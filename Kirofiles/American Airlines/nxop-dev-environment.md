# NXOP Development Environment Infrastructure

## Overview

The NXOP Development environment is the first iteration of the Next-Gen Operations Platform (NXOP) infrastructure in AWS. The environment is deployed in the us-east-1 region and follows a secure, multi-tier architecture pattern with dedicated networking, data storage, messaging, and compute resources.

## Architecture Summary

The environment consists of several interconnected components designed to support a cloud-native microservices architecture:

- **Data Storage**: Amazon DocumentDB cluster for data persistence.
- **Message Streaming**: Amazon MSK (Managed Streaming for Kafka) cluster for event streaming.
- **Object Storage**: S3 buckets for application data and access logging.
- **Security**: Comprehensive encryption and least-privilege access patterns.
- **Access Management**: Pod Identity integration for secure service-to-service authentication.
- **Temporary Infrastructure**: Jump hosts to provide developer access while firewall rules are being created, and RabbitMQ instances to serve as a temporary development tool until Amazon MQ is approved for use in the environment. More details below.

## Infrastructure-as-Code

The NXOP Dev environment infrastructured is deployed and maintained using Terraform code. Code is stored in the [nxop-infra](https://github.com/AAInternal/nxop-infra). GitHub Actions workflows automate the deployment of code into the environment. Branch protection is in place, and automated PR workflows ensure code quality and safe operations by invoking tools like Checkov, linters, formatters, and more.

***Infrastructure should only be deployed and/or modified using the `nxop-infra` repository and its automated workflows. Do not manually provision or modify infrastructures resources unless there is no alternative, and in that unlikely event, document all manual actions.***

## AWS Account

**Account ID:** 178549792225
**Account Name:** aa-aws-nxop-dev

## Network Architecture

### VPC Configuration

The environment utilizes a VPC that was provisioned by the AA networking team. The NXOP infrastructure team, per AA guidance, has modified the VPC to include additional CIDR blocks and subnet configurations to support the various workloads. The network is segmented into specialized subnet types. Comprehensive documentation of the NXOP Dev VPC [can be found here](nxop-dev-network.md).

### Connectivity

- The VPC is integrated with AWS Transit Gateway which provides connectivity to other non-prod AA networks. This is subject to firewall rules that are yet to be created. Once the nature of those rules and procedures are in place, this page should be updated to include those details.
- VPC endpoints are configured for secure communication to select AWS services.
- Internet egress is provided to select endpoints and ports/protocols. This is subject to firewall rules. Once the nature of those rules and procedures are in place, this page should be updated to include those details.

## Compute Infrastructure

### Kubernetes Platform as a Service (KPaas)

The AA KPaaS platform serves as the primary compute infrastructure for the dev environment. The KPaaS non-prod environment serves both the NXOP dev and NXOP non-prod environments.

- KPaaS clusters are configured with worker nodes distributed across multiple availability zones.
- AWS Pod Identity is leveraged for secure workload authentication in order to invoke AWS services.
- Automated deployment workflows are in place and documented by the KPaaS team.
- As of Nov 6, 2025, a dedicated NXOP cluster has been provisioned. Further isolation between non-prod environments is achieved via namespaces.

For additional information, see [NXOP KPaaS Integration](../../nxop-kpaas-integration.md).

## Data Storage

### Amazon DocumentDB

Two DocumentDB database clusters have been provisioned.

- One cluster serves as the primary NXOP data store, the other cluster is dedicated to the FXIP application.
- Clusters are configured with multiple instances for high availability.
- All clusters use encryption at-rest using customer-managed KMS keys.
- Backups are automated and maintenance windows are configured.
- Clusters are secured with dedicated least-privilege security groups allowing access only from necessary sources.

### S3 Storage

S3 buckets have been deployed to provide object storage capabilities:

1. **FXIP Application Bucket**: Stores application data and artifacts specific to the FFXIP application.
2. **S3 Access Logs Bucket**: Centralizes access logging for audit and compliance purposes.

Both buckets implement versioning, encryption at-rest by default, public access blocks, and least-privilege bucket policies.

## Message Streaming

### Amazon MSK Cluster

An Amazon Managed Streaming for Apache Kafka (MSK) cluster has been deployed and provides event streaming capabilities:

- The cluster features multiple broker nodes across availability zones for high availability.
- Express broker nodes are in use. These deliver triple the throughput per broker, scale 20 times faster, and reduce recovery time by 90% compared to Standard brokers. They come pre-optimized with Kafka best practices, maintain full API compatibility, and provide low-latency performance.
- IAM and SASL authentication methods are supported.
- Encrypted in transit using TLS and at rest using customer-managed KMS keys.
- The cluster is fronted by a Network Load Balancer for load distribution amongst broker nodes, simplifying access including cross-account access patterns.
- Enhanced monitoring enabled is enabled for operational visibility.

The MSK cluster is specifically configured to support event-driven architecture patterns expected for use within the platform.

### Temporary EC2 Instances

Temporary EC2 instances provide interim solutions:

1. **RabbitMQ Instance**: Provides message queuing capabilities until the Amazon MQ service is approved for use within AA. At present, it is not an approved service and is blocked by a service control policy (SCP).
2. **Developer Jump Host**: Enables developer access to internal resources within the VPC.

Eventually, the required firewall rules will be in place to allow direct access from developer and engineer workstations, but this is still in progress as of this writing.

## Security and Encryption

### Key Management Service (KMS)

Multiple customer-managed encryption keys secure different resource types:

- **DocumentDB CMKs**: Encrypt database storage and backups.
- **MSK CMK**: Encrypt Kafka message data and logs.
- **S3 CMK**: Encrypt object storage.
- **EBS CMK**: Encrypt EBS volumes attached to EC2 instances.

### Identity and Access Management

IAM configuration supports the principle of least privilege:

- **Pod Identity Integration**: Kubernetes workloads authenticate to AWS services using pod-level IAM roles.
- **Service Accounts**: Dedicated IAM roles for different application components.

### Secrets Management

AWS Secrets Manager stores sensitive credentials for NXOP Dev infrastructure. Secrets Manager is used for the following purposes:

- DocumentDB user credentials for various database user accounts across multiple clusters.
- Rabbit MQ credentials.

Using the human NXOP Developer role, developers can view and update secret values in the environment. In order to deploy an entirely new secret object, infrastructure engineers must deploy the associated AWS resource via Terraform.

## Network Security

### Security Groups

Security groups control network access:

- DocumentDB security groups restrict database access to authorized sources.
- MSK security groups control Kafka cluster access.
- EC2 security groups manage temporary instance access.

### Network Load Balancer

The MSK cluster utilizes an internal Network Load Balancer for:

- Service discovery and endpoint management.
- Load distribution across Kafka brokers.
- Health checking to avoid routing traffic to unhealthy broker nodes.
- Secure internal routing without internet exposure.

## Monitoring and Observability

The environment includes comprehensive monitoring capabilities:

- **Enhanced MSK Monitoring**: Per-broker metrics for Kafka cluster performance.
- **CloudWatch Integration**: Centralized logging for DocumentDB and other AWS services.

## Development and Operations Support

### Temporary Access Infrastructure

Recognizing the need for development and operational access, temporary infrastructure provides:

- Secure jump host access for development and infrastructure teams. These hosts have AWS Systems Manager Session Manager capabilities allowing for direct access via the browser or their own workstations using SSH port-forwarding.
- Interim message queuing while organizational approval processes complete.

### Service Integration

The environment is designed to support the FXIP application's microservices architecture through:

- Event-driven communication patterns via Kafka.
- Stateful data persistence through DocumentDB.
- Secure inter-service communication.

## Operational Considerations

### Human Access

Most operational actions in the environment should be handled through GitHub Actions pipelines to maintain consistency and auditability. Select infrastructure engineers have elevated permissions but should only use those when absolutely necessary for emergency situations or troubleshooting that cannot be performed through automated pipelines.

A custom "NXOPDeveloper" role is available to development teams and provides:

- Read-only access to most AWS resources for monitoring, transparency, and troubleshooting.
- Connection capabilities to temporary EC2 instances via AWS Systems Manager Session Manager.
- Viewing and updating pre-existing secrets in AWS Secrets Manager.

This role enables developers to perform day-to-day development activities while maintaining appropriate security boundaries and preventing inadvertent changes to critical infrastructure components.

### Scalability

The infrastructure is configured to support growth:

- DocumentDB read replicas for read scaling; additional read replicas can be easily provisioned as and when needed.
- MSK cluster storage scaling and the ability to easily add additional broker nodes to the cluster.
- S3 unlimited storage capacity.
