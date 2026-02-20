from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_rds as rds,
    aws_elasticache as elasticache,
    aws_ecs as ecs,
    aws_ecs_patterns as ecs_patterns,
    aws_ecr as ecr,
    aws_secretsmanager as secretsmanager,
    aws_logs as logs,
    aws_iam as iam,
    Duration,
    RemovalPolicy,
    CfnOutput
)
from constructs import Construct

class CloudOptimaStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # VPC with public and private subnets
        vpc = ec2.Vpc(
            self, "CloudOptimaVPC",
            max_azs=2,
            nat_gateways=1,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="Public",
                    subnet_type=ec2.SubnetType.PUBLIC,
                    cidr_mask=24
                ),
                ec2.SubnetConfiguration(
                    name="Private",
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS,
                    cidr_mask=24
                )
            ]
        )

        # Security Groups
        db_security_group = ec2.SecurityGroup(
            self, "DBSecurityGroup",
            vpc=vpc,
            description="Security group for RDS PostgreSQL",
            allow_all_outbound=True
        )

        redis_security_group = ec2.SecurityGroup(
            self, "RedisSecurityGroup",
            vpc=vpc,
            description="Security group for ElastiCache Redis",
            allow_all_outbound=True
        )

        ecs_security_group = ec2.SecurityGroup(
            self, "ECSSecurityGroup",
            vpc=vpc,
            description="Security group for ECS tasks",
            allow_all_outbound=True
        )

        # Allow ECS to access RDS and Redis
        db_security_group.add_ingress_rule(
            ecs_security_group,
            ec2.Port.tcp(5432),
            "Allow ECS tasks to access PostgreSQL"
        )

        redis_security_group.add_ingress_rule(
            ecs_security_group,
            ec2.Port.tcp(6379),
            "Allow ECS tasks to access Redis"
        )

        # Secrets Manager for credentials
        db_secret = secretsmanager.Secret(
            self, "DBSecret",
            secret_name="cloudoptima/prod/db",
            generate_secret_string=secretsmanager.SecretStringGenerator(
                secret_string_template='{"username": "cloudoptima"}',
                generate_string_key="password",
                exclude_punctuation=True,
                password_length=32
            )
        )

        jwt_secret = secretsmanager.Secret(
            self, "JWTSecret",
            secret_name="cloudoptima/prod/jwt",
            generate_secret_string=secretsmanager.SecretStringGenerator(
                secret_string_template='{}',
                generate_string_key="secret_key",
                exclude_punctuation=True,
                password_length=64
            )
        )

        # RDS PostgreSQL 16 with TimescaleDB support
        db_instance = rds.DatabaseInstance(
            self, "CloudOptimaDB",
            engine=rds.DatabaseInstanceEngine.postgres(
                version=rds.PostgresEngineVersion.VER_16
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.T4G,
                ec2.InstanceSize.MEDIUM
            ),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS),
            security_groups=[db_security_group],
            database_name="cloudoptima",
            credentials=rds.Credentials.from_secret(db_secret),
            allocated_storage=50,
            max_allocated_storage=200,
            storage_type=rds.StorageType.GP3,
            backup_retention=Duration.days(7),
            deletion_protection=False,
            removal_policy=RemovalPolicy.SNAPSHOT,
            multi_az=False,
            publicly_accessible=False
        )

        # ElastiCache Redis
        redis_subnet_group = elasticache.CfnSubnetGroup(
            self, "RedisSubnetGroup",
            description="Subnet group for CloudOptima Redis",
            subnet_ids=[subnet.subnet_id for subnet in vpc.private_subnets]
        )

        redis_cluster = elasticache.CfnCacheCluster(
            self, "CloudOptimaRedis",
            cache_node_type="cache.t4g.micro",
            engine="redis",
            num_cache_nodes=1,
            vpc_security_group_ids=[redis_security_group.security_group_id],
            cache_subnet_group_name=redis_subnet_group.ref
        )

        # ECR Repositories
        backend_repo = ecr.Repository(
            self, "BackendRepo",
            repository_name="cloudoptima-backend",
            removal_policy=RemovalPolicy.DESTROY,
            image_scan_on_push=True
        )

        frontend_repo = ecr.Repository(
            self, "FrontendRepo",
            repository_name="cloudoptima-frontend",
            removal_policy=RemovalPolicy.DESTROY,
            image_scan_on_push=True
        )

        # ECS Cluster
        cluster = ecs.Cluster(
            self, "CloudOptimaCluster",
            vpc=vpc,
            container_insights=True
        )

        # Task Execution Role
        task_execution_role = iam.Role(
            self, "TaskExecutionRole",
            assumed_by=iam.ServicePrincipal("ecs-tasks.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AmazonECSTaskExecutionRolePolicy"
                )
            ]
        )

        # Grant secrets access
        db_secret.grant_read(task_execution_role)
        jwt_secret.grant_read(task_execution_role)

        # Task Role (for application permissions)
        task_role = iam.Role(
            self, "TaskRole",
            assumed_by=iam.ServicePrincipal("ecs-tasks.amazonaws.com")
        )

        # Backend Task Definition
        backend_task = ecs.FargateTaskDefinition(
            self, "BackendTask",
            memory_limit_mib=1024,
            cpu=512,
            execution_role=task_execution_role,
            task_role=task_role
        )

        backend_container = backend_task.add_container(
            "backend",
            image=ecs.ContainerImage.from_ecr_repository(backend_repo, "latest"),
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="backend",
                log_retention=logs.RetentionDays.ONE_WEEK
            ),
            environment={
                "APP_ENV": "production",
                "LOG_LEVEL": "INFO",
                "DATABASE_URL": f"postgresql+asyncpg://cloudoptima:{db_secret.secret_value_from_json('password').unsafe_unwrap()}@{db_instance.db_instance_endpoint_address}:5432/cloudoptima",
                "REDIS_URL": f"redis://{redis_cluster.attr_redis_endpoint_address}:{redis_cluster.attr_redis_endpoint_port}/0"
            },
            secrets={
                "SECRET_KEY": ecs.Secret.from_secrets_manager(jwt_secret, "secret_key")
            }
        )

        backend_container.add_port_mappings(
            ecs.PortMapping(container_port=8000, protocol=ecs.Protocol.TCP)
        )

        # Backend Service with ALB
        backend_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "BackendService",
            cluster=cluster,
            task_definition=backend_task,
            desired_count=1,
            public_load_balancer=True,
            listener_port=80,
            security_groups=[ecs_security_group]
        )

        backend_service.target_group.configure_health_check(
            path="/health",
            interval=Duration.seconds(60)
        )

        # Frontend Task Definition
        frontend_task = ecs.FargateTaskDefinition(
            self, "FrontendTask",
            memory_limit_mib=512,
            cpu=256,
            execution_role=task_execution_role
        )

        frontend_container = frontend_task.add_container(
            "frontend",
            image=ecs.ContainerImage.from_ecr_repository(frontend_repo, "latest"),
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="frontend",
                log_retention=logs.RetentionDays.ONE_WEEK
            ),
            environment={
                "REACT_APP_API_URL": f"http://{backend_service.load_balancer.load_balancer_dns_name}"
            }
        )

        frontend_container.add_port_mappings(
            ecs.PortMapping(container_port=3000, protocol=ecs.Protocol.TCP)
        )

        # Frontend Service with ALB
        frontend_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self, "FrontendService",
            cluster=cluster,
            task_definition=frontend_task,
            desired_count=1,
            public_load_balancer=True,
            listener_port=80,
            security_groups=[ecs_security_group]
        )

        # Celery Worker Task
        celery_worker_task = ecs.FargateTaskDefinition(
            self, "CeleryWorkerTask",
            memory_limit_mib=1024,
            cpu=512,
            execution_role=task_execution_role,
            task_role=task_role
        )

        celery_worker_task.add_container(
            "celery-worker",
            image=ecs.ContainerImage.from_ecr_repository(backend_repo, "latest"),
            command=["celery", "-A", "app.core.celery_app", "worker", "--loglevel=info"],
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="celery-worker",
                log_retention=logs.RetentionDays.ONE_WEEK
            ),
            environment={
                "APP_ENV": "production",
                "DATABASE_URL": f"postgresql+asyncpg://cloudoptima:{db_secret.secret_value_from_json('password').unsafe_unwrap()}@{db_instance.db_instance_endpoint_address}:5432/cloudoptima",
                "REDIS_URL": f"redis://{redis_cluster.attr_redis_endpoint_address}:{redis_cluster.attr_redis_endpoint_port}/0"
            },
            secrets={
                "SECRET_KEY": ecs.Secret.from_secrets_manager(jwt_secret, "secret_key")
            }
        )

        celery_worker_service = ecs.FargateService(
            self, "CeleryWorkerService",
            cluster=cluster,
            task_definition=celery_worker_task,
            desired_count=1,
            security_groups=[ecs_security_group]
        )

        # Celery Beat Task
        celery_beat_task = ecs.FargateTaskDefinition(
            self, "CeleryBeatTask",
            memory_limit_mib=512,
            cpu=256,
            execution_role=task_execution_role,
            task_role=task_role
        )

        celery_beat_task.add_container(
            "celery-beat",
            image=ecs.ContainerImage.from_ecr_repository(backend_repo, "latest"),
            command=["celery", "-A", "app.core.celery_app", "beat", "--loglevel=info"],
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="celery-beat",
                log_retention=logs.RetentionDays.ONE_WEEK
            ),
            environment={
                "APP_ENV": "production",
                "DATABASE_URL": f"postgresql+asyncpg://cloudoptima:{db_secret.secret_value_from_json('password').unsafe_unwrap()}@{db_instance.db_instance_endpoint_address}:5432/cloudoptima",
                "REDIS_URL": f"redis://{redis_cluster.attr_redis_endpoint_address}:{redis_cluster.attr_redis_endpoint_port}/0"
            },
            secrets={
                "SECRET_KEY": ecs.Secret.from_secrets_manager(jwt_secret, "secret_key")
            }
        )

        celery_beat_service = ecs.FargateService(
            self, "CeleryBeatService",
            cluster=cluster,
            task_definition=celery_beat_task,
            desired_count=1,
            security_groups=[ecs_security_group]
        )

        # Outputs
        CfnOutput(self, "FrontendURL", value=f"http://{frontend_service.load_balancer.load_balancer_dns_name}")
        CfnOutput(self, "BackendURL", value=f"http://{backend_service.load_balancer.load_balancer_dns_name}")
        CfnOutput(self, "BackendRepoURI", value=backend_repo.repository_uri)
        CfnOutput(self, "FrontendRepoURI", value=frontend_repo.repository_uri)
        CfnOutput(self, "DBEndpoint", value=db_instance.db_instance_endpoint_address)
        CfnOutput(self, "RedisEndpoint", value=redis_cluster.attr_redis_endpoint_address)
