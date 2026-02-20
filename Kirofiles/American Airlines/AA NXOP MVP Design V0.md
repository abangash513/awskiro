# AA NXOP MVP Design V0


NXOP MVP Design Doc



© 2025, Amazon Web
                © 2025,
                   Services,
                        Amazon
                             Inc. or
                                  Webits Services,
                                         affiliates.Inc.
                                                     All or
                                                         rights
                                                            its affiliates.
                                                                 reserved.All
                                                                            Amazon
                                                                              rights reserved.
                                                                                     Confidential
                                                                                               Amazon
                                                                                                  and Trademark.
                                                                                                       Confidential and Trademark.   1
System Context                                                                                                                                                  A
                                                                                                                                                                    External systems and connectivity that NXOP
                                                                                                                                                                    integrates with including SaaS applications on
This diagram shows the overall system context calling out the core/critical components that together make up the NXOP                                               AWS and other clouds, AA on-premise legacy
platform                                                                                                                                                            systems, and internet connectivity for
                                                                                                                                                                    monitoring and external APIs.
External Dependencies                                                                                                                                       A
                                                                                                                                                                    Centralized networking infrastructure
                                                                                                                                                                B
                                                                                                                                                                    providing secure connectivity for NXOP
                                      SaaS applications on              SaaS applications on                   On-Premise                Internet                   including Transit Gateway for cross-account
                                            AWS                         other Cloud providers                  Applications
                                                                                                                                                                    routing, NAT/Internet gateways for external
                                                                                                                                                                    access, Direct Connect for on-premise
                                                                                                                                                            B
        Network Account                                                                                                                                             connectivity, Network Firewall for security
                                                                                                                                                                    inspection, and VPC endpoints for private AWS
                                                                                                                                                                    service access.
                              Endpoints       NAT gateway      AWS Transit Gateway        AWS Direct Connect      Internet gateway   AWS Network Firewall
                                                                                                                                                                C
                                                                                                                                                                    Kubernetes platform services hosting NXOP
                                                                                                                                                                    applications including Amazon EKS clusters
                          C                                                                                                                                         running RabbitMQ consumers, flight data
                                                                                                                                                            D
        KPaaS                         NXOP Account                                                                                                                  validators, and transformers/processors, plus
        Account                                                                                                                                                     IAM services managing pod identities and
                                                                                                                                                                    cross-account access permissions.

                                                                                                                                                                D   Data and security services supporting NXOP
    Amazon Elastic
                                                                                                                                                                    operations including MSK for flight data
                                AWS Secrets Manager                Amazon Managed                                               AWS Key Management
   Kubernetes Service                                                                                                            Service (AWS KMS)                  streaming, Secrets Manager for FlightKeys
                                                              Streaming for Apache Kafka
     (Amazon EKS)
                                                                    (Amazon MSK)                                                                                    credentials, KMS for encryption, IAM for cross-
                                                                                                                                                                    account access control, S3 and DocumentDB
                                                                                                Amazon Simple Storage
                                                                                                 Service (Amazon S3)
                                                                                                                                                                    for data persistence.


AWS Identity and Access        AWS Identity and Access           Amazon DocumentDB                                             Amazon Managed Service
  Management (IAM)               Management (IAM)            (with MongoDB compatibility)                                         for Apache Flink




              Reviewed for technical accuracy, 2025
              © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
                                                                                                                                                  Amazon Virtual Private Cloud
EKS Architecture – Cluster in Separate/Shared Account
                                                                                                                                              A
                                                                                                                                                  (Amazon VPC) hosts multiple Amazon
This diagram essentially is shows the setup where the Amazon EKS clusters reside in separate and possible shared KPaaS account                    Elastic Kubernetes Service (Amazon
and the services required for the NXOP platform to function reside in the NXOP workload account.                                                  EKS) clusters in the shared KPaaS
                                                                                                                                                  account.
       KPaaS Account                                                                        Network Account
                                                                                                                                                  The shared Network account hosts the
                                                                                                                                              B
                                                                                                                                                  AWS Transit Gateway with attachments
        Region                                                                               Region                                               to all other VPCs to enable across-
                                                                                                                             B
                                                                                                                                                  account network connectivity.
                                                A                                              Virtual private cloud (VPC)
                                                                                                                                                  The NXOP Account hosts all the
           Virtual private cloud (VPC)                                                                                           Attachment
                                                                                                                                                  necessary services for the NXOP
                                                                                                                                              C
                                                                  Attachment                                                                      workload to operate like Amazon
                                                                                                                                                  DocumentDB and Amazon Managed
                                                                                                       AWS Transit Gateway
                                                                                                                                                  Streaming for Apache Kafka and many
                                                                                                                                                  others.


     Cluster N Node                         Cluster N Node Cluster N Node                   NXOP Account

                                                                                             Region                          C
                        Amazon Elastic                                                         Virtual private cloud (VPC)
                       Kubernetes Service
                         (Amazon EKS)
                                                                                                                                 Attachment


                                                                                         Amazon Managed Streaming for
                                                                                                 Apache Kafka
                                                                                                (Amazon MSK)
      NXOP Cluster                           NXOP Cluster      NXOP Cluster

                                                                                                                  Amazon DocumentDB
                                                                                                              (with MongoDB compatibility)




             Reviewed for technical accuracy, 2025
             © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Security – Pod Identity – Role Chaining                                                                                              1
                                                                                                                                         NXOP Application pod starts in EKS cluster
                                                                                                                                         with assigned service account for MSK access
This diagram shows the Pod Identity flow for cross-account assumption of roles
                                                                                                                                     2   EKS Pod Identity agent exchanges service
                                                                                                                                         account token for AWS credentials
         KPaaS Account
                                                                                                                                     3   Pod Identity assumes KPaaS account IAM role
                                                                                                                                         with permissions for cross-account access
                                         Namespace
                                                                                         3
                                              1                                                                                          Final role in workload account with specific
                                                                                                                                     4
                                                                                                                                         MSK topic permissions, and cross-account
                                                                               Role                                                      trust policy for KPaaS IAM Role.
                            Service Account        Application Pod                                 Permissions

                                                                                                                                     5   STS provides temporary credentials for
                                                     2
    NXOP EKS Cluster                                                                                                                     workload account resource access
                                                                                   Role Chain for Cross-
                                                                                   Account Assumption
                                                                                                                                     6
                                                                                                                                         NXOP application accesses MSK topics using
                                     Pod Identity Agent
                                                                                                                                         temporary credentials for
                                                                                                                                         consuming/producing messages

                                                                                 NXOP Account



                                                                                             4
                                                                                Role                Permissions

                                                                          5



                                                         6                    AWS STS
                                                                                                      Amazon Managed Streaming for
                                                                                                              Apache Kafka
                                                                                                             (Amazon MSK)




             Reviewed for technical accuracy, 2025
             © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Overflow RabbitMQ Consumer Pattern                                                                                                   1
                                                                                                                                         FlightKeys 5D engine publishes flight
                                                                                                                                         optimization data (OFPs, alerts, trajectories) to
This shows a comprehensive Health aware overflow scaling pattern, where the overflow consumer scales out depending on a                  RabbitMQ queue in us-east-1 (Active Region)
health criteria.
                                                                                                                                         Active AMQP Consumer consuming FlightKeys
                                                                                                                                     2
                                                                                                                                         messages, validating schema, and
                                                                                                                                         transforming for downstream systems
                                                                                                                                         integrated to consume from the RabbitMQ
                                                                                                                                         queue in us-east-1
  FlightKeys on AWS (Vendor)
                                                                                                                                         A similar deployment of the same application
       us-east-1                                                                              us-west-2                              3   exists in us-west-2 but scaled down to Zero.
                                           1                                                                                             The deployment scales up the number of Pods
                        Active                                                                                  Standby                  depending on a comprehensive health aware
                      RabbitMQ                                                                                 RabbitMQ                  policy.
                                OFPs, Alerts, Flight
                                  Trajectories                                                                                           Flight Keys RabbitMQ in us-west-2 is in
                                                                                                                                     4   standby mode, with no messages being
                                                                                                                                         produced actively until FlightKeys fails over.
  KPaaS
     us-east-1                                                                               us-west-2                                   A similar deployment of the same application
                                       2                                                                                             5   exists in us-east-1 but scaled down to Zero.
                                                                            5                           3                        4       The deployment scales up the number of Pods
                   Active AMQP                     Overflow AMQP                        Overflow AMQP        AMQP Message                depending on a comprehensive health aware
                    Consumer                         Consumer                             Consumer          Processor (Active)           policy.




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Overflow Consumer Application Scaling – Alarms to Scaling behavior                                                       1
                                                                                                                             Amazon CloudWatch alarms are configured
                                                                                                                             for publishing alerts to SNS Topics when the
This shows a flow diagram of how to connect the CloudWatch Alarms to drive autoscaling of the overflow consumers             alarm is in ALARM state.

                                                                                                                             Amazon Simple Notification Service (Amazon
                                                                                                                         2
                                                                                                                             SNS) topics are configured with permissions
                      1                                                                                                      route the messages to subscriptions, and also
                                                                                                                             support filters as needed.

                                                                                                                         3
                                                                                                                             AWS Lambda function is triggered and
                                                                                                                             receives the SNS Topic messages and calculate
    Amazon CloudWatch                 Scoring Logic:                                                                         the comprehensive Health score which is then
                                      • RabbitMQ Alarm = Score+=100                                                          also published to Amazon CloudWatch as a
                                      • AZ Alarm = Score+=75 per AZ                                                          custom metric.

Alarms alerted                                                                                                           4
                                                                                                                             Amazon CloudWatch allows to configure
                                                                                                                             alerting on the custom metric along with all
                                                                                                         6
                                                                                                                             the other alarms.
                     2                                             3
                                                                                                                             A KEDA Scaling configuration on the overflow
                               Triggers
                                                                                                                             consumer deployment polls Amazon
                                                                                                                         5   CloudWatch in configurable interval for the
                                                                                                                             Health score and performs a scaling math
 Amazon Simple Notification                                                                Kubernetes API                    based on desired vs target values to determine
                                                   AWS Lambda                                                                the scaling behavior.
  Service (Amazon SNS)
                                         Put Health                                               Triggers Autoscaling       KEDA uses the derived scaling behavior
                                                                                                                         6
                                        Score Metric                                                                         information to interact with Kubernetes API to
                                                                                                        5                    scale up/down the overflow consumer
                                                                       4
                                                                                                                             application Pods as needed.
                                                                             Polling for
                                                                            Health Score

                                               Amazon CloudWatch
             Reviewed for technical accuracy, 2025
             © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
KEDA Scaling Configuration Example                                                                            1
                                                                                                                  For the overflow consumer application, the minimum
                                                                                                                  replica count is set to Zero and Maximum to 10
This shows an example of KEDA Scaled Object configuration that uses the Health Score from Amazon CloudWatch
                                                                                                                  References the actual custom metric in Amazon
                                                                                                              2
                                                                                                                  CloudWatch for the Health score that was calculated by
                                                                                                                  the AWS Lambda function.
  apiVersion: keda.sh/v1alpha1
  kind: ScaledObject                                                                                          3
                                                                                                                  The targetMetricValue determines the scaling behavior
                                                                                                                  along with the health score. KEDA uses the logic of
  metadata:
   name: overflow-consumer-optimal                                                                                replicas = ceil(health_score / targetMetricValue)
  spec:
                                                                                                                  Examples:
   scaleTargetRef:
     name: overflow-amqp-consumer                                                                                 • When Healthy
   minReplicaCount: 0                                                                                                         health_score=0, then replicas=0
                           1
   maxReplicaCount: 10                                                                                            • When 1 AZ impact
   triggers:                                                                                                                   health_score=75, then replicas=2
   - type: aws-cloudwatch
                                                                                                                  • When RabbitMQ impact
     metadata:                                                                                                                health_score=100, then replicas=2
      awsRegion: us-east-1
      namespace: Custom/FlightPipeline                                                                            • When RabbitMQ + 1 AZ impact
                                                                                                                              health_score=175, then replicas=4
      metricName: HealthScore
      dimensionName: Flow                                                                                         • When RabbitMQ + 2 AZ impact
      dimensionValue: FlightKeys_To_NXOP                           2                                                          health_score=250, then replicas=5
      targetMetricValue: “50” 3                                                                                   • When RabbitMQ + 3 AZ impact
      activationTargetMetricValue: “25”                                                                                       health_score=325, then replicas=7




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
MSK – Client Connectivity                                                                                                                              1
                                                                                                                                                           External clients initiate connection to the
                                                                                                                                                           custom domain for MSK bootstrap and
This diagram shows the approach for setting up NLB for the initial connection bootstrap to MSK brokers                                                     metadata retrieval.

                                                                                                                                                       2   The AWS Network Load Balancer receives the
                                                                                                                                                           client request and applies TLS certificate from
                       NXOP Account                                                                                                                        ACM (Step 5) to enforce transport layer
                                                                                                                                                           encryption for secure communication.
                                           Virtual private cloud (VPC)
           1                                                                                                                   Elastic network         3   MSK brokers are deployed in 3 AZs to provide
                                                             2
                                                                                                                                  interface                high availability

                                              Network Load                                                   Elastic network                           4   Route 53 Private Hosted Zone helps with DNS
  Client                                        Balancer                                                        interface                                  resolution of the custom domain and
                                                                                                                                                           maintains the association between the custom
                                   TLS Certificate                                                                             Elastic network             domain and the Network Load Balancer
                                                                                                                                  interface                endpoint.
                              5
                                                                         4                                                                       3     5   AWS Certificate Manager (ACM) provides the
                                                                              Association                                                                  TLS certificate used by the Network Load
                                                                                                                                                           Balancer to secure client connections during
                AWS Certificate                              Private                                             Amazon Managed Streaming for Apache       the bootstrap process.
                Manager (ACM)       Amazon Route 53                                                                           Kafka
                                                           Hosted zone
                                                                                                                           (Amazon MSK)




                                                                                           Network Load
                                                                                             Balancer



                                                                                           read/write data
                                                                                                                               MSK Broker

               Reviewed for technical accuracy, 2025 Client
               © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
MSK Producers/Consumers Network Path                                                                                                                             1
                                                                                                                                                                     MSK Clients connect to MSK via the Route53
                                                                                                                                                                     DNS layer for resolving the actual brokers and
This shows the network connectivity path for MSK Producers/Consumers                                                                                                 get connected to the Active region

                                                                                                                                                                 2   The Route53 DNS record resolves the request
 NXOP                                                                                                                                                                to the NLB in the active Region, and thereby
                                                                                                                                                                     enabling the bootstrap request to be handled
                       Active Region                                                                                 Standby Region                                  by the MSK brokers in the active Region.

                                                                                                                                                                 3
                                                                                                                                                                     The MSK clients connect directly to the broker
                                                                                                                                                                     in the Active Region to produce/consume
                                                                       Bi-directional                                                                                messages.
                      Cluster 1: Topic                                  Replication                                   Cluster 2: Topic




                            NLB                                                                                            NLB

    msk-bootstrap-nlb-1234567890.elb.us-east-1.amazonaws.com                                          msk-bootstrap-nlb-0987654321.elb.us-west-2.amazonaws.com

                                         Bootstrap Request                 Route53                    Failover Path
                                                               2             DNS           kafka.nxop.com




                                                                               1    Bootstrap Request
                                              3

                          Produce/Consume Messages                                                Producer/Consume Messages


                                                                              Clients
               Reviewed for technical accuracy, 2025
               © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
FXIP MVP for 11/14 – Single Region                                                                             1
                                                                                                                   FlightKeys 5D engine publishes flight
                                                                                                                   optimization data (OFPs, alerts, trajectories) to
This diagram shows the single Region setup for 11/14 MVP deadline                                                  RabbitMQ queue in us-east-1 (Active Region)

                                                   FlightKeys on AWS (Vendor)                                      Active AMQP Consumer consuming FlightKeys
                                                                                                               2
                                                                                                                   messages, validating schema, and
                                                         us-east-1                                                 transforming for downstream systems
                                                                                                  1
                                                                               Active                              integrated to consume from the RabbitMQ
                                                                             RabbitMQ                              queue in us-east-1
                                                                                        OFPs, Alerts, Flight
                                                                                                                   MSK cluster in us-east-1 receiving validated
                                                                                          Trajectories
                                                                                                               3   flight data from active FXIP processor, in
                                                                                                                   Source Topic
                                                  KPaaS
                                                                                                                   Application also writes to DocumentDB in the
                                                       us-east-1                                               4   same Region
                                                                                              2
                                                                        Active AMQP
                                                                         Consumer



                                                  NXOP


                                                                         3                                 4
                                                        Cluster 1:
                                                                                           DocumentDB
                                                       Source Topic




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
FXIP MVP for 11/14 – Single Region                                                                                                                   1
                                                                                                                                                         FlightKeys 5D engine publishes flight
This diagram shows the single Region setup for 11/14 MVP deadline                                                                                        optimization data (OFPs, alerts,
                                                                                                                                                         trajectories) to RabbitMQ queue in us-
                                                                                                                                                         east-1 (Active Region)
                 us-east-1

                                                                                                                                                     2
                                                                                                                                                         Application Pods deployed on EKS Cluster
                                                                                                                                                         consume messages from FlightKeys
    FlightKeys




                                                                                               1
                                                                                                                                                         RabbitMQ and produce to MSK cluster as
                                                                                                                                                         well as write to DocumentDB.

                                                                                  RabbitMQ                                                           3   MSK cluster in us-east-1 receiving
                                                                                                                                                         validated flight data from application
                                                                                                                                                         pods.
                 us-east-1
                                                                                                                                                     4   The application on EKS also writes data to
                                                                                    2                                                                    DocumentDB.
    KPaaS




                                                           Amazon Elastic Kubernetes Service
                               Application Pods                    (Amazon EKS)                    Application Pods               Application Pods




                 us-east-1


                                                                     3                                                   4
    NXOP




                                                  Amazon Managed Streaming                             Amazon DocumentDB
                                                      for Apache Kafka                             (with MongoDB compatibility)
                                                       (Amazon MSK)




                  Reviewed for technical accuracy, 2025
                  © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
FXIP - Data Flow – FlightKeys to NXOP (Inbound)                                                                                      1
                                                                                                                                         Active AMQP Consumer in us-east-1
                                                                                                                                         subscribes and receives messages from
This diagram shows the data flow for FXIP across the various systems/components from Flight Keys to MSK integration layer                FlightKeys RabbitMQ in us-east-1.

   FlightKeys on AWS (Vendor)                                                                                                            The Active AMQP Consumer get routed to the
                                                                                                                                     2
                                                                                                                                         Active MSK cluster by using the bootstrap
       us-east-1                                                                              us-west-2                                  process that gets routed to the Route53 DNS
                                                                                                                                         Record.
                        Active                                                                                   Standby
                      RabbitMQ                                                                                  RabbitMQ                 The Route53 DNS record resolves to the NLB
                                OFPs, Alerts, Flight                                                                                     in the active Region which then enables the
                                  Trajectories                                                                                       3   request to resolve to the MSK brokers behind
                         1
                                                                                                                                         the NLB.
  KPaaS
                                                                                                                                     4   The Active AMQP Consumer produce data
     us-east-1                                                                               us-west-2                                   directly to the active MSK cluster

                                                                                                                                         The Source Topic in the active MSK Cluster is
                    Active AMQP                    Overflow AMQP                        Overflow AMQP       AMQP Message             5
                                                                                                                                         replicated to the Source Topic in the Standby
                     Consumer                        Consumer                             Consumer         Processor (Active)            region MSK Cluster

                                        2
                                                                                                                                     6   During a failover, the route53 DNS record will
                                                                                                                                         resolve the bootstrap requests to the MSK
                                                                                                6                                        cluster in the standby Region.
  NXOP                                                               Route53 DNS
                4                                                                               Failover
                                                       3



                                                                                                    5
               Cluster 1: Source Topic                               Bi-directional                        Cluster 2: Source Topic
                                                                      Replication




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
FXIP - Data Flow – FlightKeys to NXOP (Inbound) – Failure Scenario 1                                                                 1
                                                                                                                                         Active AMQP Consumer in us-east-1
                                                                                                                                         subscribes and receives messages from
This diagram shows the data flow for FXIP across the various systems/components from Flight Keys to MSK integration layer                FlightKeys RabbitMQ in us-east-1.
when the RabbitMQ queue depth increases beyond a threshold

   FlightKeys on AWS (Vendor)                                                                                                            The Active AMQP Consumer get routed to the
                                                                                                                                     2
                                                                                                                                         Active MSK cluster by using the bootstrap
       us-east-1                                                                              us-west-2                                  process that gets routed to the Route53 DNS
                                          6   queue_depth > threshold                                                                    Record.
                        Active                                                                                   Standby
                      RabbitMQ                                                                                  RabbitMQ             3   The Route53 DNS record resolves to the NLB
                                OFPs, Alerts, Flight                                                                                     in the active Region which then enables the
                                  Trajectories                                                                                           request to resolve to the MSK brokers behind
                                                                                                                                         the NLB.
  KPaaS
                                                                                                                                     4   The Active AMQP Consumer produce data
     us-east-1          1                                                                 7   us-west-2                                  directly to the active MSK cluster

                                                                                                                                         The Source Topic in the active MSK Cluster is
                    Active AMQP                     Overflow AMQP                       Overflow AMQP       AMQP Message             5
                                                                                                                                         replicated to the Source Topic in the Standby
                     Consumer                         Consumer                            Consumer         Processor (Active)            region MSK Cluster

                                                                                                                                         The RabbitMQ queue depth increases beyond
                                                2                                         8                                          6
                                                                                                                                         threshold due to multiple possible reasons,
  NXOP                                                                                                                                   and triggers an alarm.
                4                                                    Route53 DNS
                                                     3
                                                                                                Failover
                                                                                                                                     7   The alarm affects the overall health score of
                                                                                                                                         the system and triggers the overflow AMQP
                                                                        Bi-directional                                                   consumer in us-west-2 to scale out to also
               Cluster 1: Source Topic                                   Replication                       Cluster 2: Source Topic
                                                                                          5                                              start consuming from the RabbitMQ in us-
                                                                                                                                         east-1.

                                                                                                                                     8   Like the active AMQP consumer, the overflow
                                                                                                                                         AMQP consumer also follows the same
                                                                                                                                         connectivity process to connect to the active
                                                                                                                                         MSK cluster.
            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
FXIP - Data Flow – FlightKeys to NXOP (Inbound) – Failure Scenario 2                                                                  1
                                                                                                                                          Active AMQP Consumer in us-east-1 has an
                                                                                                                                          impairment preventing it from consuming
This diagram shows the data flow for FXIP across the various systems/components from Flight Keys to MSK integration layer                 messages from the FlightKeys RabbitMQ in us-
when the RabbitMQ queue depth increases beyond a threshold, due an issue with the EKS components                                          east-1, and triggers an alarm.
   FlightKeys on AWS (Vendor)
                                                                                                                                      2   The alarm affects the overall health score of
       us-east-1                                                                               us-west-2                                  the system and triggers the overflow AMQP
                                                                                                                                          consumer in us-west-2 to scale out to also
                        Active                                                                                    Standby                 start consuming from the RabbitMQ in us-
                      RabbitMQ                                                                                   RabbitMQ                 east-1.
                                OFPs, Alerts, Flight
                                  Trajectories                                                                                        3   Like the active AMQP consumer, the overflow
                                                                                                                                          AMQP consumer also follows the same
                                                                                                                                          connectivity process to connect to the active
  KPaaS
                                                                                                                                          MSK cluster via the Route53 DNS Record.
     us-east-1          1                                                                  2   us-west-2
                                                                                                                                      4   The Route53 DNS record resolves to the NLB
                                                                                                                                          in the active Region which then enables the
                   Active AMQP                     Overflow AMQP                        Overflow AMQP        AMQP Message                 request to resolve to the MSK brokers behind
                    Consumer                         Consumer                             Consumer          Processor (Active)            the NLB.

                                                                                  3
                                                                                                                                      5   The Overflow AMQP Consumer produce data
                                                                                                                                          directly to the active MSK cluster
  NXOP                                      4
                                                                       Route53 DNS                                                        The Source Topic in the active MSK Cluster is
                                                                                                 Failover                             6
                                                                                                                                          replicated to the Source Topic in the Standby
                                                                                                                                          region MSK Cluster
                                                                   6    Bi-directional
               Cluster 1: Source Topic                                   Replication                        Cluster 2: Source Topic

                                                       5




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
FXIP - Data Flow – FlightKeys to NXOP (Inbound) – Failure Scenario 3                                                                      1
                                                                                                                                              The MSK in us-east-1 has an impairment
                                                                                                                                              preventing the Active AMQP Consumer in us-
This diagram shows the data flow for FXIP across the various systems/components from Flight Keys to MSK integration layer                     east-1 from producing message to the cluster
when the RabbitMQ queue depth increases beyond a threshold, due to the MSK cluster impairment in us-east-1                                    topic and triggers an alarm.
   FlightKeys on AWS (Vendor)
                                                                                                                                          2   The alarm affects the overall health score of
       us-east-1                                                                               us-west-2                                      the system and triggers the overflow AMQP
                                                                                                                                              consumer in us-west-2 to scale out to also
                        Active                                                                                        Standby                 start consuming from the RabbitMQ in us-
                      RabbitMQ                                                                                       RabbitMQ                 east-1.
                                OFPs, Alerts, Flight
                                  Trajectories                                                                                            3   Like the active AMQP consumer, the overflow
                                                                                                                                              AMQP consumer also follows the same
                                                                                                                                              connectivity process to connect to the active
  KPaaS
                                                                                                                                              MSK cluster via the Route53 DNS Record.
     us-east-1                                                                             2   us-west-2
                                                                                                                                          4   The Route53 DNS record resolves to the NLB
                                                                                                                                              in the Standby Region which then enables the
                    Active AMQP                    Overflow AMQP                        Overflow AMQP            AMQP Message                 request to resolve to the MSK brokers behind
                     Consumer                        Consumer                             Consumer              Processor (Active)            the NLB.
                                                                                                            5
                1                                                                 3
                                                                                                                                          5   The Overflow AMQP Consumer produce data
                                                                                                                                              directly to the standby MSK cluster, and once
  NXOP                                                                                          4                                             the Active AMQP consumer is able to recover
                                                                       Route53 DNS                                                            starts producing the Standby MSK cluster.
                                                                                                 Failover

                                                                                                                                          6   The Source Topic in the standby MSK Cluster is
                                                                   6    Bi-directional                                                        replicated to the Source Topic in the Active
               Cluster 1: Source Topic                                   Replication                            Cluster 2: Source Topic
                                                                                                                                              region MSK Cluster

                                                                                                 5




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Overflow Consumer Scaling Criteria Matrix
This shows a comprehensive suite of metrics that will be used for scaling criteria for the overflow consumers

                                                                                            Scaling
 Component                  Metrics                    Threshold             Weight                                   Rationale                     Custom/Out of the Box
                                                                                            Action
                                                     > 10,000                                           Message Backlog indicates
                  Queue Depth                                               Critical      Scale to 10                                      Custom (due to Vendor ownership)
                                                     messages                                           slow/stalled processing
  RabbitMQ
                                                     <2                                                 Low/No connections = No message
                  Connection Count                                          Critical      Scale to 10                                      Custom (due to Vendor ownership)
                                                     connections                                        consumption
                  Number of running
                                                     < 2 Pods               High          Scale to 5    Insufficient processing capacity   EKS Container Insights (Out of the box)
                  Pods
                  Pod Number of
                                                     > 5 /min               High          Scale to 3    Pod instability                    EKS Container Insights (Out of the box)
                  Container Restarts
   EKS Pods
                                                                            Mediu
                  Pod CPU Utilization                > 80%                                Scale to 2    Resource pressure                  EKS Container Insights (Out of the box)
                                                                            m
                  Pod Memory                                                Mediu
                                                     > 85%                                Scale to 2    Memory pressure                    EKS Container Insights (Out of the box)
                  Utilization                                               m
                  Consumer Lag                       3000                   High          Scale to 5    Downstream processing behind       MSK Metrics (Out of the box)
                  Offline Partition
                                                     >0                     Critical      Scale to 10   Data unavailability                MSK Metrics (Out of the box)
                  Count
     MSK          Under replicated                                          Mediu
                                                     >0                                   Scale to 3    Reduced redundancy                 MSK Metrics (Out of the box)
                  Partitions                                                m
                                                     < 50% of               Mediu
                  Bytes in per second                                                     Scale to 2    Reduced throughput                 MSK Metrics (Out of the box)
                                                     baseline               m

              Reviewed for technical accuracy, 2025
              © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Alarm Structure for AZ Fault Detection
This shows a comprehensive Alarm Structure by Region to detect AZ faults




  us-east-1a EKS Availability Alarm                                                                                                                       us-east-1a EKS Memory Alarm      us-east-1a MSK Throughput Alarm
                                        us-east-1a MSK Availability Alarm        us-east-1a EKS Latency Alarm          us-east-1a MSK Latency Alarm
        (EKS_Availability_1a)                                                                                                                                  (EKS_Memory_1a)                   (MSK_Throughput_1a)
                                              (MSK_Availability_1a)                   (EKS_Latency_1a)                      (MSK_Latency_1a)
 ALARM(Service_Number_of_Runnin                                                                                                                          ALARM(Pod_Memory_Utilization)       ALARM(Bytes_in_per_second)
                                        ALARM(Offline_Partitions_Count)          ALARM(Pod_CPU_Utilization)               ALARM(Max_Offset_Lag)
              g_Pods)
                                                                                                                                                            us-east-1a EKS Health Alarm
                                                                                                                                                                                             us-east-1a MSK Health Alarm
                                                                                                                                                                 (EKS_Health_1a)
                                                                                                                                                                                                   (MSK_Health_1a)
                                                                                                                                                         ALARM(Pod_Number_of_Container
                                                                                                                                                                                          ALARM(Under_Replicated_Partitions)
                                                                                                                                                                     _Restarts)




                                                                                                                                                                       us-east-1a Health Alarm (AZ_Health_1a)
             us-east-1a Availability Alarm (AZ_Availability_1a)                                 us-east-1a Latency Alarm (AZ_Latency_1a)                         ALARM(EKS_Health_1a) OR ALARM(EKS_Memory_1a) OR
         ALARM(EKS_Availability_1a) OR ALARM(MSK_Availability_1a)                           ALARM(EKS_Latency_1a) OR ALARM(MSK_Latency_1a)                       ALARM(MSK_Health_1a) OR ALARM(MSK_Throughput_1a)




                                                                                            us-east-1a Aggregate Alarm (AZ_Aggregate_1a)
                                                                              ALARM(AZ_Availability_1a) OR ALARM(AZ_Latency_1a) OR ALARM(AZ_Health_1a)




                Reviewed for technical accuracy, 2025
                © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Alarm Structure for AZ Health – FlightKeys to NXOP Data Flow
This shows a comprehensive Alarm Structure by Region to detect AZ faults




                          us-east-1a Aggregate Alarm (AZ_Aggregate_1a)                                                                             us-east-1a Aggregate Alarm (AZ_Aggregate_1c)
            ALARM(AZ_Availability_1a) OR ALARM(AZ_Latency_1a) OR ALARM(AZ_Health_1a)                                                 ALARM(AZ_Availability_1c) OR ALARM(AZ_Latency_1c) OR ALARM(AZ_Health_1c)




                                                                                       us-east-1a Aggregate Alarm (AZ_Aggregate_1b)
                                                                         ALARM(AZ_Availability_1b) OR ALARM(AZ_Latency_1b) OR ALARM(AZ_Health_1b)




                                                                            us-east-1a Zonal Health Alarm (FlightKeys_To_NXOP_1a_Isolated_Impact)
                                                                          ALARM(AZ_Aggregate_1a) AND OK(AZ_Aggregate_1b) AND OK(AZ_Aggregate_1c)




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Alarm Structure for Regional Health – FlightKeys to NXOP Data Flow
This shows a comprehensive Alarm Structure for Regional Health of FlightKeys to NXOP Data Flow




                                                                                                                                          us-east-1a Zonal Health Alarm (FlightKeys_To_NXOP_1a_Isolated_Impact)
                                                                                                                                        ALARM(AZ_Aggregate_1a) AND OK(AZ_Aggregate_1b) AND OK(AZ_Aggregate_1c)




                                  us-east-1a Aggregate Alarm (AZ_Aggregate_1c)
                    ALARM(AZ_Availability_1c) OR ALARM(AZ_Latency_1c) OR ALARM(AZ_Health_1c)




                                  us-east-1a Aggregate Alarm (AZ_Aggregate_1b)
                    ALARM(AZ_Availability_1b) OR ALARM(AZ_Latency_1b) OR ALARM(AZ_Health_1b)




                           us-east-1 RabbitMQ Regional Health (RabbitMQ_Regional_Health)
                               ALARM(Queue_Messages_Ready) OR ALARM(Connections)




                                                                                            us-east-1 Regional Health Alarm
                   ALARM(RabbitMQ_Regional_Health) OR ALARM(FlightKeys_To_NXOP_1a_Isolated_Impact) OR ALARM(FlightKeys_To_NXOP_1b_ Isolated_ Impact) OR ALARM(FlightKeys_To_NXOP_1c_ Isolated_ Impact)


            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
NXOP – ASM Data Flow                                                                                                                            1
                                                                                                                                                    MSF jobs consume data from the source topic in MSK
                                                                                                                                                    cluster in the same Region.
This diagram shows the data flow for ASM
                                                                                                                                                2   The job enriches the data and writes to DocumentDB
                                                                                                                                                    cluster in region.

  NXOP                                                                                                                                              The job also writes to an enriched output topic which is
                               Active Region                                                                  Standby Region                    3
                                                                                                                                                    internal and not replicated across Regions.




                           DocumentDB                                                                       DocumentDB
                                            2                                                                          2




                                MSF Job                                                                           MSF Job

                    3                                         1                                       1                            3


            Cluster 1: Internal                                                                                        Cluster 2: Internal
                                                Cluster 1: Source Topic                 Cluster 2: Source Topic
          Enriched Output (Hidden)                                                                                   Enriched Output (Hidden)




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
NXOP – ASM Data Flow                                                                                                      1
                                                                                                                              Backfill process in the Active Region consumes data
                                                                                                                              from the Internal Enriched Output topic.
This diagram shows the data flow for ASM
                                                                                                                          2   The Backfill process validates if the current Region is
                                                                                                                              still the Active region by performing a Route53 TXT
                                                                                                                              Record DNS lookup
  NXOP
                               Active Region                                                      Standby Region              If still operating in the Active Region, proceed to
                                                                                                                          3
                                                                                                                              validate if the current message being processed is a
                                                                                                                              duplicate using the DynamoDB Global Table. If not a
                                                                                                                              duplicate, insert an Item into the Table with the
                                                                                                                              message metadata
                           Cluster 1: Internal                                                   Cluster 2: Internal
                         Enriched Output (Hidden)                                              Enriched Output (Hidden)   4
                                                                                                                              Proceed to write to the External Enriched Output topic
                                                                                                                              which is bi-directionally replicated across Regions, and
                                                                                                                              then update the item in the DynamoDB Global Table.
                                   1                                   activeregion.nxop.com
                                                       2                Route53 TXT Record
                                                                            =”us-east-1”
                                   Backfill                                                             Backfill
                                   Process                                                              Process
                                                       3

                                                                       Message De-Dup Cache
                                                                        DynamoDB Global
                                                                              Table



                                   4



                                                                Bi-Directional Replication
                            Cluster 1: External                                                  Cluster 2: External
                             Enriched Output                                                      Enriched Output




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
NXOP – ASM Data Flow - Failover                                                                                               1a
                                                                                                                                   Backfill process in the Standby Region looks up the
                                                                                                                                   last processed message timestamp from the de-dup
This diagram shows the data flow for ASM                                                                                           cache table.

                                                                                                                              1b   The process seeks the offset corresponding to the
                                                                                                                                   timestamp from the internal enriched output topic.
  NXOP
                               Active Region                                                            Standby Region             Validates that the current Region is still the Active
                                                                                                                              2
                                                                                                                                   Region.

                                                                                                                                   Proceeds to lookup the message metadata to validate
                                                                                                                              3
                                                                                                                                   for duplication, and makes an entry into the Table if not
                           Cluster 1: Internal                                                       Cluster 2: Internal           a duplicate
                         Enriched Output (Hidden)                                                  Enriched Output (Hidden)
                                                                                                                                   Produces the message to MSK in the Standby Region
                                                                                                                              4
                                                                                                                                   to the External Enriched Output topic which is bi-
                                                                       activeregion.nxop.com                         1b            directionally replicated, and then updates the Item in
                                                                        Route53 TXT Record     2                                   the DynamoDB Global Table that the Item has been
                                                                            =”us-west-2”                                           processed.
                                   Backfill                                                                   Backfill
                                   Process                                                                    Process

                                                                                               3   1a
                                                                       Message De-Dup Cache
                                                                        DynamoDB Global
                                                                              Table
                                                                                                                     4




                                                                Bi-Directional Replication
                            Cluster 1: External                                                         Cluster 2: External
                             Enriched Output                                                             Enriched Output




            Reviewed for technical accuracy, 2025
            © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
NXOP – Region Failover Steps                                                                                                        1
                                                                                                                                        Validate
                                                                                                                                        • Us-west-2 Health
This shows the steps involved in orchestrating a Region failover when failing over to us-west-2                                         • MSK Cluster Ready
                                                                                                                                        • Backfill Jobs health
                                                                                                                                        • DynamoDB Health
                                                                                          2
                                                                                              Update Active                         2   Update Route53 TXT record with the new value for
                    Start                                                                                             Stop              active Region i.e; us-west-2
                                                                                               Region Flag
                                                                                                                                        In Application Recovery Controller Routing Control
                                         1                                                                                          3
                                                                                                                                        Panel
            Failover Readiness                                                            3                                             • Disable us-east-1 health check routing control
                                                           Successful                          Update MSK                               • Enable us-west-2 health check routing control
                  Checks                                                                                          Alert/Notify
                                                                                               Routing DNS                              Validate DNS resolution to us-west-2 NLB
us-west-2




                                                                                                                                    4   Start the Backfill process in the us-west-2 Region

                                                                                                                                        Cross-Region Lambda invocation to remove inbound

                                                      Abort Failover and                       Start Backfill   Validate Failover   5   rules from MSK Security Group and block ports 9092,
                                                                                                                                        9094
                                                                                          4
                   Stop                                                                          Process          Completion
                                                        Alert/Notify
us-east-1




                                                                                              Cordon off MSK
                                                                                          5
                                                                                              Security Group



              Reviewed for technical accuracy, 2025
              © 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.
Reviewed for technical accuracy, 2025
© 2025, Amazon Web Services, Inc. or its affiliates. All rights reserved.

