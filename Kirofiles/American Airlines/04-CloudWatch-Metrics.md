# NXOP CloudWatch Metrics Strategy

**Part of**: [NXOP Resilience Analysis](../NXOP-Resilience-Analysis-v3.md)  
**Foundation**: [NXOP Message Flow Analysis](00-NXOP-Message-Flow-Analysis.md)

---

## Purpose

This document provides a comprehensive CloudWatch metrics strategy for monitoring the NXOP platform. For each component, we define:
- Metric names and namespaces
- Dimensions and thresholds
- Purpose and scope (Regional/Zonal/Global)
- Alerting criteria

**Audience**: SREs, monitoring engineers, operations teams

---

## Metrics Visualization Strategy

### CloudWatch Metrics Hierarchy

**Metrics Organization**: Infrastructure → Network → Data → Application layers

| Layer | Components | Metric Count | Namespaces | Purpose |
|-------|------------|--------------|------------|---------|
| **Infrastructure** | EKS, MSK, DocumentDB, S3 | ~80 metrics | AWS/*, ContainerInsights | Monitor compute, storage, messaging infrastructure |
| **Network** | NLB, VPC, Route53, ARC | ~35 metrics | AWS/NetworkELB, AWS/VPC, AWS/Route53 | Monitor connectivity, load balancing, DNS |
| **Data** | Replication (MSK, DocumentDB, S3) | ~15 metrics | AWS/Kafka, AWS/DocDB, AWS/S3 | Monitor cross-region data sync |
| **Application** | Four Golden Signals, SLI | ~20 metrics | NXOP/*, MSK/Health | Monitor business functionality |
| **Total** | | **~150 metrics** | | |

**Metric Flow**: Lower-level infrastructure metrics aggregate into higher-level application SLIs

```
Infrastructure Metrics (EKS, MSK, DocumentDB)
    ↓ Aggregation
Network Metrics (NLB, Route53, VPC)
    ↓ Aggregation
Data Replication Metrics (Cross-Region Sync)
    ↓ Aggregation
Application SLI Metrics (Four Golden Signals)
    ↓ Composite Alarms
Region Readiness Status
```

---

### Metric Namespace Distribution

**Total Namespaces**: 15 (9 AWS-managed, 6 custom)

| Namespace Category | Namespaces | Metric Count | Percentage |
|-------------------|------------|--------------|------------|
| **AWS Infrastructure** | AWS/Kafka, AWS/DocDB, AWS/S3, AWS/AutoScaling, ContainerInsights | ~80 | 53% |
| **AWS Network** | AWS/NetworkELB, AWS/VPC, AWS/Route53, AWS/Route53RecoveryControlConfig | ~35 | 23% |
| **Custom Application** | NXOP/Processing, NXOP/Messaging, NXOP/Database, NXOP/Storage, NXOP/SLI | ~20 | 13% |
| **Custom Infrastructure** | NXOP/Network, NXOP/DNS, NXOP/ARC, MSK/Health | ~15 | 10% |
| **CloudWatch Logs** | CWLogs (IAM metrics from log insights) | ~5 | 3% |

**Key Namespaces by Component**:

| Component | Primary Namespace | Secondary Namespace | Metric Examples |
|-----------|------------------|---------------------|-----------------|
| EKS | ContainerInsights | NXOP/Processing | node_cpu_utilization, ApplicationPrefix.Throughput |
| MSK | AWS/Kafka | MSK/Health, NXOP/Messaging | OfflinePartitionsCount, ProducerLatency |
| DocumentDB | AWS/DocDB | NXOP/Database | CPUUtilization, DocumentDB.ConnectionErrors |
| S3 | AWS/S3 | NXOP/Storage | AllRequests (MRAP), S3.OperationLatency |
| NLB | AWS/NetworkELB | NXOP/Network | HealthyHostCount, SecurityGroup.ConnectionBlocked |
| Route53 | AWS/Route53 | NXOP/DNS | HealthCheckStatus, DNS.ResolutionTime |
| ARC | AWS/Route53RecoveryControlConfig | NXOP/ARC | RoutingControlState, ReadinessCheckStatus |

---

## Metrics Organization

Metrics are organized by component category:
- **Component-Level**: Infrastructure metrics (EKS, MSK, DocumentDB, S3, Network)
- **Application-Level**: Business logic metrics (Four Golden Signals)
- **Cross-Account**: IAM and authentication metrics

---

## Component-Level Metrics

### Compute Infrastructure Metrics (EKS)

#### Node and Pod Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `node_cpu_utilization` | `ContainerInsights` | `ClusterName`, `NodeName` | > 80% | Monitor node resource usage | Zonal |
| `node_memory_utilization` | `ContainerInsights` | `ClusterName`, `NodeName` | > 85% | Monitor node memory usage | Zonal |
| `node_filesystem_utilization` | `ContainerInsights` | `ClusterName`, `NodeName` | > 90% | Monitor node disk usage | Zonal |
| `node_network_total_bytes` | `ContainerInsights` | `ClusterName`, `NodeName` | Sudden drop > 70% | Monitor node network health | Zonal |
| `pod_cpu_utilization` | `ContainerInsights` | `ClusterName`, `Namespace`, `PodName` | > 90% | Monitor pod resource usage | Zonal |
| `pod_memory_utilization` | `ContainerInsights` | `ClusterName`, `Namespace`, `PodName` | > 95% | Monitor pod memory usage | Zonal |
| `pod_restart_count` | `ContainerInsights` | `ClusterName`, `Namespace`, `PodName` | > 5 restarts/hour | Detect pod instability | Zonal |

#### Application-Level Metrics
**Note**: `ApplicationPrefix` represents your application's metric prefix following the Four Golden Signals pattern.

| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ApplicationPrefix.Throughput` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | < 100/min for 5 min | Monitor processing throughput | Regional |
| `ApplicationPrefix.Latency` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | > 5000ms (P95) | Monitor processing performance | Regional |
| `ApplicationPrefix.ErrorRate` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | > 5% | Monitor application errors | Regional |
| `ApplicationPrefix.HealthCheck` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | = 0 (unhealthy) | Monitor application health | Regional |


#### Cross-Account IAM Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `AssumeRole.SuccessCount` | `AWS/CloudTrail` | `RoleName`, `SourceAccount` | < 90% success rate | Monitor role assumption health | Regional |
| `AssumeRole.Duration` | `AWS/CloudTrail` | `RoleName`, `SourceAccount` | > 5000ms | Monitor role assumption performance | Regional |
| `IAM.AccessDeniedErrors` | `AWS/CloudTrail` | `UserName`, `EventName` | > 10/hour | Detect permission issues | Regional |

#### Auto Scaling Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `GroupDesiredCapacity` | `AWS/AutoScaling` | `AutoScalingGroupName` | Monitor scaling events | Track node group scaling | Zonal |
| `GroupInServiceInstances` | `AWS/AutoScaling` | `AutoScalingGroupName` | < 50% of desired | Monitor node availability | Zonal |
| `GroupPendingInstances` | `AWS/AutoScaling` | `AutoScalingGroupName` | > 0 for > 10 min | Detect scaling issues | Zonal |

### Data Storage Metrics (DocumentDB)

#### DocumentDB Cluster Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `CPUUtilization` | `AWS/DocDB` | `DBClusterIdentifier` | > 80% | Monitor cluster CPU usage | Regional |
| `DatabaseConnections` | `AWS/DocDB` | `DBClusterIdentifier` | > 90% of max | Monitor connection usage | Regional |
| `FreeableMemory` | `AWS/DocDB` | `DBClusterIdentifier` | < 20% of total | Monitor memory usage | Regional |
| `ReadLatency` | `AWS/DocDB` | `DBClusterIdentifier` | > 100ms (P95) | Monitor read performance | Regional |
| `WriteLatency` | `AWS/DocDB` | `DBClusterIdentifier` | > 200ms (P95) | Monitor write performance | Regional |
| `VolumeReadIOPs` | `AWS/DocDB` | `DBClusterIdentifier` | > 80% of provisioned | Monitor read IOPS usage | Regional |
| `VolumeWriteIOPs` | `AWS/DocDB` | `DBClusterIdentifier` | > 80% of provisioned | Monitor write IOPS usage | Regional |

#### DocumentDB Instance Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `CPUUtilization` | `AWS/DocDB` | `DBInstanceIdentifier` | > 85% | Monitor instance CPU | Zonal |
| `DatabaseConnections` | `AWS/DocDB` | `DBInstanceIdentifier` | > 90% of max | Monitor instance connections | Zonal |
| `FreeableMemory` | `AWS/DocDB` | `DBInstanceIdentifier` | < 15% of total | Monitor instance memory | Zonal |
| `ReadThroughput` | `AWS/DocDB` | `DBInstanceIdentifier` | Monitor read throughput | Track read performance | Zonal |
| `WriteThroughput` | `AWS/DocDB` | `DBInstanceIdentifier` | Monitor write throughput | Track write performance | Zonal |

#### Global Cluster Replication Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `GlobalClusterReplicationLag` | `AWS/DocDB` | `DBClusterIdentifier`, `SourceRegion` | > 30 seconds | Monitor cross-region replication | Global |
| `GlobalClusterDataTransferBytes` | `AWS/DocDB` | `DBClusterIdentifier`, `SourceRegion` | Sudden drop > 50% | Monitor replication data flow | Global |
| `GlobalClusterReplicatedWriteIO` | `AWS/DocDB` | `DBClusterIdentifier`, `SourceRegion` | < 90% of primary writes | Monitor replication completeness | Global |

#### Application Connection Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `DocumentDB.ConnectionErrors` | `NXOP/Database` | `Environment`, `Region`, `ClusterName` | > 5/min | Monitor connection failures | Regional |
| `DocumentDB.QueryLatency` | `NXOP/Database` | `Environment`, `Region`, `Operation` | > 1000ms (P95) | Monitor query performance | Regional |
| `DocumentDB.TransactionErrors` | `NXOP/Database` | `Environment`, `Region`, `ErrorType` | > 1% error rate | Monitor transaction failures | Regional |
| `DocumentDB.ConnectionPoolUtilization` | `NXOP/Database` | `Environment`, `Region`, `ServiceName` | > 85% | Monitor connection pool usage | Regional |

### Object Storage Metrics (S3 MRAP)

#### S3 MRAP Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `AllRequests` | `AWS/S3` | `MultiRegionAccessPointName` | Sudden drop > 50% | Monitor MRAP request volume | Global |
| `4xxErrors` | `AWS/S3` | `MultiRegionAccessPointName` | > 5% error rate | Monitor client errors via MRAP | Global |
| `5xxErrors` | `AWS/S3` | `MultiRegionAccessPointName` | > 1% error rate | Monitor server errors via MRAP | Global |
| `FirstByteLatency` | `AWS/S3` | `MultiRegionAccessPointName` | > 1000ms (P95) | Monitor MRAP response latency | Global |
| `TotalRequestLatency` | `AWS/S3` | `MultiRegionAccessPointName` | > 5000ms (P95) | Monitor total MRAP latency | Global |

#### S3 Regional Bucket Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `AllRequests` | `AWS/S3` | `BucketName`, `FilterId` | Sudden drop > 70% | Monitor regional bucket health | Regional |
| `GetRequests` | `AWS/S3` | `BucketName`, `FilterId` | Monitor read operations | Track read activity | Regional |
| `PutRequests` | `AWS/S3` | `BucketName`, `FilterId` | Monitor write operations | Track write activity | Regional |
| `4xxErrors` | `AWS/S3` | `BucketName`, `FilterId` | > 5% error rate | Monitor client errors | Regional |
| `5xxErrors` | `AWS/S3` | `BucketName`, `FilterId` | > 1% error rate | Monitor server errors | Regional |
| `FirstByteLatency` | `AWS/S3` | `BucketName`, `FilterId` | > 500ms (P95) | Monitor response latency | Regional |

#### S3 Cross-Region Replication Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ReplicationLatency` | `AWS/S3` | `SourceBucket`, `DestinationBucket` | > 300 seconds (5 min) | Monitor replication lag | Global |
| `BytesPendingReplication` | `AWS/S3` | `SourceBucket`, `DestinationBucket` | > 1GB for > 30 min | Monitor replication backlog | Global |
| `OperationsPendingReplication` | `AWS/S3` | `SourceBucket`, `DestinationBucket` | > 1000 for > 15 min | Monitor operation backlog | Global |
| `ReplicatedBytes` | `AWS/S3` | `SourceBucket`, `DestinationBucket` | < 90% of source bytes | Monitor replication completeness | Global |

#### Application S3 Access Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `S3.OperationLatency` | `NXOP/Storage` | `Environment`, `Region`, `Operation` | > 2000ms (P95) | Monitor application S3 performance | Regional |
| `S3.OperationErrors` | `NXOP/Storage` | `Environment`, `Region`, `ErrorType` | > 2% error rate | Monitor application S3 errors | Regional |
| `S3.ThroughputUtilization` | `NXOP/Storage` | `Environment`, `Region`, `BucketName` | < 50% of expected | Monitor data transfer performance | Regional |
| `S3.ObjectIntegrityChecks` | `NXOP/Storage` | `Environment`, `Region`, `BucketName` | > 0 failures | Monitor data integrity | Regional |


### Message Streaming Metrics (MSK)

#### MSK Cluster-Level Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ActiveControllerCount` | `AWS/Kafka` | `Cluster Name` | = 0 | Monitor controller availability | Regional |
| `OfflinePartitionsCount` | `AWS/Kafka` | `Cluster Name` | > 0 | Monitor partition health | Regional |
| `UnderReplicatedPartitions` | `AWS/Kafka` | `Cluster Name` | > 0 | Monitor replication health | Regional |
| `UnderMinIsrPartitionCount` | `AWS/Kafka` | `Cluster Name` | > 0 | Monitor ISR health | Regional |
| `GlobalPartitionCount` | `AWS/Kafka` | `Cluster Name` | Monitor partition growth | Track cluster scaling | Regional |
| `GlobalTopicCount` | `AWS/Kafka` | `Cluster Name` | Monitor topic growth | Track topic creation | Regional |

#### MSK Broker-Level Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `CpuIdle` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | < 20% | Monitor broker CPU usage | Zonal |
| `CpuSystem` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 60% | Monitor system CPU usage | Zonal |
| `CpuUser` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 70% | Monitor user CPU usage | Zonal |
| `MemoryFree` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | < 20% of total | Monitor memory usage | Zonal |
| `MemoryUsed` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 80% of total | Monitor memory consumption | Zonal |
| `RootDiskUsed` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 85% | Monitor disk usage | Zonal |
| `NetworkRxDropped` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 100/min | Monitor network drops | Zonal |
| `NetworkTxDropped` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 100/min | Monitor network drops | Zonal |

#### MSK Topic and Partition Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `BytesInPerSec` | `AWS/Kafka` | `Cluster Name`, `Topic`, `Broker ID` | < 1MB/sec for 10 min | Monitor ingress throughput | Zonal |
| `BytesOutPerSec` | `AWS/Kafka` | `Cluster Name`, `Topic`, `Broker ID` | < 1MB/sec for 10 min | Monitor egress throughput | Zonal |
| `MessagesInPerSec` | `AWS/Kafka` | `Cluster Name`, `Topic`, `Broker ID` | < 10/sec for 10 min | Monitor message flow | Zonal |
| `ProduceMessageConversionsPerSec` | `AWS/Kafka` | `Cluster Name`, `Topic`, `Broker ID` | > 100/sec | Monitor conversion overhead | Zonal |
| `FetchMessageConversionsPerSec` | `AWS/Kafka` | `Cluster Name`, `Topic`, `Broker ID` | > 100/sec | Monitor fetch conversions | Zonal |

#### MSK Producer and Consumer Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ProduceRequestRate` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | Monitor producer activity | Track producer load | Zonal |
| `ProduceResponseRate` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | Monitor producer responses | Track producer success | Zonal |
| `FetchRequestRate` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | Monitor consumer activity | Track consumer load | Zonal |
| `FetchResponseRate` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | Monitor consumer responses | Track consumer success | Zonal |
| `ProduceTotalTimeMs` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 1000ms (P95) | Monitor producer latency | Zonal |
| `FetchConsumerTotalTimeMs` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 500ms (P95) | Monitor consumer latency | Zonal |

#### MSK Replicator Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ReplicationBytesPerSec` | `AWS/MSK/Replicator` | `ReplicatorName`, `SourceCluster`, `TargetCluster` | < 1MB/sec for 10 min | Monitor replication throughput | Global |
| `ReplicationRecordsPerSec` | `AWS/MSK/Replicator` | `ReplicatorName`, `SourceCluster`, `TargetCluster` | < 100/sec for 10 min | Monitor replication rate | Global |
| `ReplicationLag` | `AWS/MSK/Replicator` | `ReplicatorName`, `SourceCluster`, `TargetCluster` | > 60 seconds | Monitor replication lag | Global |
| `ReplicatorRunningTaskCount` | `AWS/MSK/Replicator` | `ReplicatorName` | < expected count | Monitor replicator health | Global |
| `ReplicatorFailedTaskCount` | `AWS/MSK/Replicator` | `ReplicatorName` | > 0 | Monitor replicator failures | Global |
| `AuthenticationFailures` | `AWS/Kafka` | `Cluster Name`, `ClientType` | > 0 | Monitor SASL/IAM auth failures | Regional |
| `ClientConnectionCount` | `AWS/Kafka` | `Cluster Name`, `Broker ID` | > 90% of max | Monitor active client connections | Zonal |

#### Application Kafka Client Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `Kafka.ProducerLatency` | `NXOP/Messaging` | `Environment`, `Region`, `Topic` | > 1000ms (P95) | Monitor producer performance | Regional |
| `Kafka.ConsumerLag` | `NXOP/Messaging` | `Environment`, `Region`, `ConsumerGroup` | > 10000 messages | Monitor consumer lag | Regional |
| `Kafka.ConnectionErrors` | `NXOP/Messaging` | `Environment`, `Region`, `ClientType` | > 5/min | Monitor connection issues | Regional |
| `Kafka.AuthenticationFailures` | `NXOP/Messaging` | `Environment`, `Region`, `ClientType` | > 0 | Monitor auth issues | Regional |

#### MSK Health Canary Custom Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ProducerLatency` | `MSK/Health` | `Cluster`, `Region`, `Component`, `SequenceNumber` | > 5000ms (P95) | Monitor individual message produce latency | Regional |
| `BatchMessagesProduced` | `MSK/Health` | `Cluster`, `Region`, `Component` | < 50 messages/batch | Monitor batch production success | Regional |
| `BatchSuccessRate` | `MSK/Health` | `Cluster`, `Region`, `Component` | < 95% | Monitor batch production success rate | Regional |
| `BatchTotalLatency` | `MSK/Health` | `Cluster`, `Region`, `Component` | > 60000ms | Monitor total batch execution time | Regional |
| `MemoryUsed` | `MSK/Health` | `Cluster`, `Region`, `Component` | > 80% of allocated | Monitor Lambda memory usage | Regional |
| `MemoryUtilization` | `MSK/Health` | `Cluster`, `Region`, `Component` | > 85% | Monitor Lambda memory efficiency | Regional |
| `ExecutionCount` | `MSK/Health` | `Cluster`, `Region`, `Component` | Monitor execution frequency | Track canary invocations | Regional |
| `ColdStart` | `MSK/Health` | `Cluster`, `Region`, `Component` | > 20% of executions | Monitor Lambda cold start rate | Regional |
| `ConsumerHealth` | `MSK/Health` | `Cluster`, `Region`, `Component` | = 0 (failure) | Monitor real-time consumer health | Regional |
| `RealtimeMessagesProcessed` | `MSK/Health` | `Region`, `Handler` | < 10/min for 10 min | Monitor real-time message processing | Regional |
| `RealtimeProcessingLatency` | `MSK/Health` | `Region`, `Handler` | > 10000ms (P95) | Monitor real-time processing latency | Regional |
| `RealtimeProcessingTime` | `MSK/Health` | `Region`, `Handler` | > 30000ms | Monitor Lambda execution time | Regional |
| `RealtimeProcessingErrors` | `MSK/Health` | `Region`, `Handler` | > 0 | Monitor real-time processing errors | Regional |
| `RealtimeLocalMessages` | `MSK/Health` | `Region`, `Component` | Monitor local message count | Track local message processing | Regional |
| `RealtimeReplicatedMessages` | `MSK/Health` | `Region`, `Component` | Monitor replicated message count | Track cross-region replication | Regional |
| `RealtimeReplicationLatency` | `MSK/Health` | `Cluster`, `Region`, `Component`, `SourceTopic` | > 30000ms (P95) | Monitor cross-region replication latency | Regional |
| `RealtimeReplicationLatencyP95` | `MSK/Health` | `Cluster`, `Region`, `Component`, `SourceTopic` | > 60000ms | Monitor P95 replication latency | Regional |

#### Cross-Account IAM Role Chain Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `AssumeRoleWithWebIdentity.Success` | `CWLogs` | `RoleName`, `SourceAccount` | < 95% success rate | Monitor Pod Identity role assumption | Regional |
| `AssumeRole.CrossAccount.Duration` | `CWLogs` | `RoleName`, `TargetAccount` | > 5000ms | Monitor cross-account role chain latency | Regional |
| `AssumeRole.CrossAccount.Failures` | `CWLogs` | `RoleName`, `ErrorCode` | > 5/hour | Monitor cross-account role failures | Regional |

#### Application-Level SLI Metrics
**Note**: `ApplicationPrefix` represents your application's metric prefix (e.g., `FlightData`, `OrderProcessing`, `UserActivity`) following the Four Golden Signals pattern.

| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ApplicationPrefix.Throughput` | `NXOP/SLI` | `Environment`, `Region` | < 100 messages/min | Monitor end-to-end data ingestion | Regional |
| `ApplicationPrefix.Latency` | `NXOP/SLI` | `Environment`, `Region` | > 30000ms (P95) | Monitor end-to-end processing latency | Regional |
| `ApplicationPrefix.ErrorRate` | `NXOP/SLI` | `Environment`, `Region` | > 2% | Monitor application error rate | Regional |
| `ApplicationPrefix.Saturation` | `NXOP/SLI` | `Environment`, `Region` | > 80% | Monitor resource utilization | Regional |
| `ApplicationPrefix.HealthCheck` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | = 0 (unhealthy) | Monitor application health | Regional |
| `CrossRegion.SyncLag` | `NXOP/SLI` | `SourceRegion`, `TargetRegion` | > 120 seconds | Monitor east-west data consistency | Global |


### Network Infrastructure Metrics (NLB, VPC)

#### Network Load Balancer (NLB) Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ActiveFlowCount` | `AWS/NetworkELB` | `LoadBalancer` | Monitor active connections | Track connection load | Regional |
| `NewFlowCount` | `AWS/NetworkELB` | `LoadBalancer` | Monitor new connections | Track connection rate | Regional |
| `ProcessedBytes` | `AWS/NetworkELB` | `LoadBalancer` | Monitor data throughput | Track data flow | Regional |
| `TCP_Client_Reset_Count` | `AWS/NetworkELB` | `LoadBalancer` | > 100/min | Monitor client resets | Regional |
| `TCP_ELB_Reset_Count` | `AWS/NetworkELB` | `LoadBalancer` | > 50/min | Monitor ELB resets | Regional |
| `TCP_Target_Reset_Count` | `AWS/NetworkELB` | `LoadBalancer` | > 100/min | Monitor target resets | Regional |

#### NLB Target Group Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `HealthyHostCount` | `AWS/NetworkELB` | `TargetGroup`, `LoadBalancer` | < 2 hosts | Monitor target health | Regional |
| `UnHealthyHostCount` | `AWS/NetworkELB` | `TargetGroup`, `LoadBalancer` | > 0 hosts | Monitor unhealthy targets | Regional |
| `TargetConnectionErrorCount` | `AWS/NetworkELB` | `TargetGroup`, `LoadBalancer` | > 10/min | Monitor target connection errors | Regional |
| `TargetTLSNegotiationErrorCount` | `AWS/NetworkELB` | `TargetGroup`, `LoadBalancer` | > 5/min | Monitor TLS errors | Regional |

#### VPC and Networking Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `PacketsDropped` | `AWS/VPC` | `VpcId`, `SubnetId` | > 1000/min | Monitor packet drops | Zonal |
| `PacketsReceived` | `AWS/VPC` | `VpcId`, `SubnetId` | Sudden drop > 70% | Monitor network activity | Zonal |
| `PacketsSent` | `AWS/VPC` | `VpcId`, `SubnetId` | Sudden drop > 70% | Monitor outbound traffic | Zonal |
| `BytesReceived` | `AWS/VPC` | `VpcId`, `SubnetId` | Monitor data ingress | Track data flow | Zonal |
| `BytesSent` | `AWS/VPC` | `VpcId`, `SubnetId` | Monitor data egress | Track data flow | Zonal |

#### Security Group Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `SecurityGroup.RuleCount` | `NXOP/Network` | `Environment`, `Region`, `SecurityGroupId` | Monitor rule changes | Track security changes | Regional |
| `SecurityGroup.ConnectionBlocked` | `NXOP/Network` | `Environment`, `Region`, `SecurityGroupId` | > 10/min | Monitor blocked connections | Regional |
| `SecurityGroup.RuleViolations` | `NXOP/Network` | `Environment`, `Region`, `SecurityGroupId` | > 0 | Monitor rule violations | Regional |

#### Cross-Account Network Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `VPCPeering.PacketsDropped` | `AWS/VPC` | `VpcPeeringConnectionId` | > 100/min | Monitor peering health | Regional |
| `VPCPeering.BytesTransferred` | `AWS/VPC` | `VpcPeeringConnectionId` | Sudden drop > 50% | Monitor cross-account traffic | Regional |
| `TransitGateway.PacketDropCount` | `AWS/TransitGateway` | `TransitGateway` | > 100/min | Monitor TGW packet drops | Regional |
| `TransitGateway.BytesIn` | `AWS/TransitGateway` | `TransitGateway` | Monitor ingress traffic | Track TGW usage | Regional |
| `TransitGateway.BytesOut` | `AWS/TransitGateway` | `TransitGateway` | Monitor egress traffic | Track TGW usage | Regional |

#### NAT Gateway Metrics (if applicable)
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `BytesInFromDestination` | `AWS/NATGateway` | `NatGatewayId` | Monitor inbound traffic | Track NAT usage | Zonal |
| `BytesOutToDestination` | `AWS/NATGateway` | `NatGatewayId` | Monitor outbound traffic | Track NAT usage | Zonal |
| `PacketsDropCount` | `AWS/NATGateway` | `NatGatewayId` | > 100/min | Monitor packet drops | Zonal |
| `ErrorPortAllocation` | `AWS/NATGateway` | `NatGatewayId` | > 0 | Monitor port exhaustion | Zonal |

### DNS and Traffic Routing Metrics (Route53, ARC)

#### Route53 Health Check Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `HealthCheckStatus` | `AWS/Route53` | `HealthCheckId` | = 0 (failure) | Monitor health check status | Global |
| `HealthCheckPercentHealthy` | `AWS/Route53` | `HealthCheckId` | < 100% | Monitor health check reliability | Global |
| `ConnectionTime` | `AWS/Route53` | `HealthCheckId` | > 5000ms | Monitor health check latency | Global |
| `TimeToFirstByte` | `AWS/Route53` | `HealthCheckId` | > 10000ms | Monitor endpoint response time | Global |

#### Route53 Resolver Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `InboundQueryVolume` | `AWS/Route53Resolver` | `EndpointId` | Monitor query volume | Track DNS usage | Regional |
| `OutboundQueryVolume` | `AWS/Route53Resolver` | `EndpointId` | Monitor outbound queries | Track DNS forwarding | Regional |
| `OutboundQueryAggregatedVolume` | `AWS/Route53Resolver` | `RuleId` | Monitor rule usage | Track forwarding rules | Regional |

#### Application DNS Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `DNS.ResolutionTime` | `NXOP/DNS` | `Environment`, `Region`, `RecordName` | > 2000ms (P95) | Monitor DNS resolution performance | Regional |
| `DNS.ResolutionFailures` | `NXOP/DNS` | `Environment`, `Region`, `RecordName` | > 1% failure rate | Monitor DNS resolution errors | Regional |
| `DNS.CacheHitRate` | `NXOP/DNS` | `Environment`, `Region` | < 80% | Monitor DNS cache efficiency | Regional |
| `DNS.TTLViolations` | `NXOP/DNS` | `Environment`, `Region`, `RecordName` | > 0 | Monitor TTL compliance | Regional |

#### ARC (Application Recovery Controller) Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `RoutingControlState` | `AWS/Route53RecoveryControlConfig` | `ControlPanelArn`, `RoutingControlArn` | Monitor control state | Track routing control status | Global |
| `SafetyRuleEvaluationResult` | `AWS/Route53RecoveryControlConfig` | `SafetyRuleArn` | Monitor safety rule status | Track safety rule compliance | Global |
| `ReadinessCheckStatus` | `AWS/Route53RecoveryReadiness` | `ReadinessCheckName` | = 0 (not ready) | Monitor resource readiness | Regional |
| `ARC.ControlStateChanges` | `NXOP/ARC` | `Environment`, `Region`, `ControlName` | Monitor state changes | Track control modifications (custom metric) | Global |

#### Geolocation and Traffic Policy Metrics
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `Route53.QueryCount` | `CWLogs` | `HostedZoneId`, `RecordName` | Monitor query volume | Track DNS usage patterns (custom metric from Query Logging) | Global |
| `Route53.GeolocationQueries` | `NXOP/DNS` | `Environment`, `Region`, `GeolocationCode` | Monitor geo distribution | Track geographic routing | Global |
| `Route53.LatencyBasedQueries` | `NXOP/DNS` | `Environment`, `Region`, `LatencyRegion` | Monitor latency routing | Track latency-based routing | Global |
| `Route53.FailoverQueries` | `NXOP/DNS` | `Environment`, `Region`, `FailoverType` | Monitor failover usage | Track failover routing | Global |

#### CloudFront Metrics (if CDN is used)
| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `Requests` | `AWS/CloudFront` | `DistributionId` | Monitor request volume | Track CDN usage | Global |
| `BytesDownloaded` | `AWS/CloudFront` | `DistributionId` | Monitor data transfer | Track bandwidth usage | Global |
| `4xxErrorRate` | `AWS/CloudFront` | `DistributionId` | > 5% | Monitor client errors | Global |
| `5xxErrorRate` | `AWS/CloudFront` | `DistributionId` | > 1% | Monitor server errors | Global |
| `OriginLatency` | `AWS/CloudFront` | `DistributionId` | > 5000ms (P95) | Monitor origin performance | Global |

## Application/Functionality-Level Metrics

### Data Ingestion Metrics

| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `RabbitMQ.ConnectionStatus` | `NXOP/FlightKeys` | `Environment`, `Region`, `ConnectionId` | = 0 (disconnected) | Monitor AMQP connection health | Regional |
| `RabbitMQ.MessagesReceived` | `NXOP/FlightKeys` | `Environment`, `Region`, `Queue` | < 10/min for 5 min | Detect message flow interruption | Regional |
| `RabbitMQ.ConnectionLatency` | `NXOP/FlightKeys` | `Environment`, `Region` | > 1000ms | Monitor connection performance | Regional |
| `RabbitMQ.AuthenticationFailures` | `NXOP/FlightKeys` | `Environment`, `Region` | > 0 | Detect credential issues | Regional |
| `FlightKeys.DNSResolutionTime` | `NXOP/FlightKeys` | `Environment`, `Region` | > 5000ms | Monitor DNS resolution performance | Regional |
| `NetworkPacketsIn` | `AWS/EC2` | `InstanceId` | Sudden drop > 50% | Monitor network connectivity to FlightKeys | Zonal |
| `NetworkPacketsOut` | `AWS/EC2` | `InstanceId` | Sudden drop > 50% | Monitor outbound network health | Zonal |
| `NetworkLatency` | `CWAgent` | `InstanceId`, `DestinationHost` | > 200ms to FlightKeys | Monitor network performance | Regional |

### Message Processing and Validation Metrics

| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `MessageSchema.ValidationErrors` | `NXOP/Processing` | `Environment`, `Region`, `SchemaVersion` | > 5% error rate | Detect schema compatibility issues | Regional |
| `Kafka.ConsumerLag` | `NXOP/Messaging` | `Environment`, `Region`, `ConsumerGroup` | > 10000 messages | Monitor consumer lag | Regional |
| `Kafka.ProducerLatency` | `NXOP/Messaging` | `Environment`, `Region`, `Topic` | > 1000ms (P95) | Monitor producer performance | Regional |
| `Kafka.ConnectionErrors` | `NXOP/Messaging` | `Environment`, `Region`, `ClientType` | > 5/min | Monitor connection issues | Regional |
| `Kafka.AuthenticationFailures` | `NXOP/Messaging` | `Environment`, `Region`, `ClientType` | > 0 | Monitor auth issues | Regional |

### Application Processing Metrics

| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `ApplicationPrefix.Throughput` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | < 100/min for 5 min | Monitor processing throughput | Regional |
| `ApplicationPrefix.Latency` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | > 5000ms (P95) | Monitor processing performance | Regional |
| `ApplicationPrefix.ErrorRate` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | > 5% | Monitor application errors | Regional |
| `ApplicationPrefix.HealthCheck` | `NXOP/Processing` | `Environment`, `Region`, `ServiceName` | = 0 (unhealthy) | Monitor application health | Regional |

### Cross-Account IAM and Authentication Metrics

| Metric Name | Namespace | Dimensions | Threshold | Purpose | Scope |
|-------------|-----------|------------|-----------|---------|-------|
| `AssumeRole.SuccessCount` | `AWS/CloudTrail` | `RoleName`, `SourceAccount` | < 90% success rate | Monitor role assumption health | Regional |
| `AssumeRole.Duration` | `AWS/CloudTrail` | `RoleName`, `SourceAccount` | > 5000ms | Monitor role assumption performance | Regional |
| `IAM.AccessDeniedErrors` | `AWS/CloudTrail` | `UserName`, `EventName` | > 10/hour | Detect permission issues | Regional |
| `AssumeRoleWithWebIdentity.Success` | `CWLogs` | `RoleName`, `SourceAccount` | < 95% success rate | Monitor Pod Identity role assumption | Regional |
| `AssumeRole.CrossAccount.Duration` | `CWLogs` | `RoleName`, `TargetAccount` | > 5000ms | Monitor cross-account role chain latency | Regional |
| `AssumeRole.CrossAccount.Failures` | `CWLogs` | `RoleName`, `ErrorCode` | > 5/hour | Monitor cross-account role failures | Regional |

---

## Composite Alarm Strategy

### Alarm Hierarchy

```
Master Region Readiness Alarm
├── L1-Infrastructure-Ready
│   ├── EKS-Cluster-Health
│   ├── MSK-Cluster-Health
│   ├── DocumentDB-Cluster-Health
│   └── S3-Bucket-Health
├── L2-Network-Ready
│   ├── NLB-Health
│   ├── DNS-Health
│   └── Cross-Account-Connectivity
├── L3-Data-Ready
│   └── Replication-Health
└── L4-Application-Ready
    ├── Service-Health
    ├── End-to-End-Health
    └── Health-Canary
```

See [Region Readiness Assessment](05-Region-Readiness-Assessment.md) for complete composite alarm implementation.

---

## Composite Alarm Strategy

### Alarm Hierarchy

**Sample Alarm Structure**:
![Sample Alarm Structure - Deployed in NXOP Account](images/Alarms.png)

**Master Region Readiness Alarm Structure**:

```
Master Region Readiness Alarm (Composite)
│
├── L1-Infrastructure-Ready (Composite - AND logic)
│   ├── EKS-Cluster-Health (Composite)
│   │   ├── node_cpu_utilization < 80%
│   │   ├── pod_restart_count < 5/hour
│   │   └── GroupInServiceInstances >= 50% of desired
│   ├── MSK-Cluster-Health (Composite)
│   │   ├── ActiveControllerCount = 1
│   │   ├── OfflinePartitionsCount = 0
│   │   └── UnderReplicatedPartitions = 0
│   ├── DocumentDB-Cluster-Health (Composite)
│   │   ├── CPUUtilization < 80%
│   │   ├── DatabaseConnections < 90% of max
│   │   └── GlobalClusterReplicationLag < 30 seconds
│   └── S3-Bucket-Health (Composite)
│       ├── 5xxErrors < 1%
│       └── ReplicationLatency < 300 seconds
│
├── L2-Network-Ready (Composite - AND logic)
│   ├── NLB-Health (Composite)
│   │   ├── HealthyHostCount >= 2
│   │   └── UnHealthyHostCount = 0
│   ├── DNS-Health (Composite)
│   │   ├── HealthCheckStatus = 1 (healthy)
│   │   └── HealthCheckPercentHealthy = 100%
│   └── Cross-Account-Connectivity (Composite)
│       ├── VPCPeering.PacketsDropped < 100/min
│       └── AssumeRole.SuccessCount >= 95%
│
├── L3-Data-Ready (Composite - AND logic)
│   └── Replication-Health (Composite)
│       ├── MSK.ReplicationLag < 60 seconds
│       ├── DocumentDB.GlobalClusterReplicationLag < 30 seconds
│       └── S3.ReplicationLatency < 300 seconds
│
└── L4-Application-Ready (Composite - AND logic)
    ├── Service-Health (Composite)
    │   ├── ApplicationPrefix.HealthCheck = 1 (healthy)
    │   └── ApplicationPrefix.ErrorRate < 5%
    ├── End-to-End-Health (Composite)
    │   ├── ApplicationPrefix.Throughput >= 100/min
    │   └── ApplicationPrefix.Latency < 5000ms (P95)
    └── Health-Canary (Composite)
        ├── MSK/Health.ProducerLatency < 5000ms
        ├── MSK/Health.ConsumerHealth = 1
        └── MSK/Health.RealtimeReplicationLatency < 30000ms
```

**Alarm Logic**:
- **AND Logic**: All child alarms must be OK for parent to be OK
- **Failure Propagation**: Any child alarm failure triggers parent alarm
- **Recovery**: Parent alarm clears only when all children are OK

See [Region Readiness Assessment](05-Region-Readiness-Assessment.md) for complete composite alarm implementation.

---

### Metric Threshold Decision Tree

**Decision Flow**: Metric Collection → Evaluation → Action

| Step | Decision Point | Outcome | Action |
|------|---------------|---------|--------|
| **1. Metric Collection** | CloudWatch receives metric data point | | Store metric in namespace |
| **2. Threshold Evaluation** | Is metric > Critical threshold? | Yes → ALARM (Red) | Proceed to Step 3a |
| | Is metric > Warning threshold? | Yes → WARNING (Yellow) | Proceed to Step 3b |
| | Is metric within normal range? | Yes → OK (Green) | Proceed to Step 3c |
| **3a. ALARM State Actions** | Critical threshold breached | | • Trigger SNS notification<br/>• Execute Lambda auto-remediation (if configured)<br/>• Update composite alarm state<br/>• Page on-call engineer<br/>• Create incident ticket |
| **3b. WARNING State Actions** | Warning threshold breached | | • Send Slack notification<br/>• Log to CloudWatch Logs<br/>• Update dashboard to yellow<br/>• Monitor for escalation |
| **3c. OK State Actions** | Metric within normal range | | • Clear previous alarms<br/>• Update dashboard to green<br/>• Log recovery event |
| **4. Composite Alarm Evaluation** | Aggregate child alarm states | | • Apply AND/OR logic<br/>• Update master alarm state<br/>• Propagate to parent alarms |
| **5. Recovery Actions** | Based on alarm type | | • HA - Automated: Auto-scaling, restart, failover<br/>• Regional Switchover: ARC Region Switch Plan<br/>• Manual Intervention: Create incident ticket, page engineer |

**Example Threshold Scenarios**:

| Metric | Warning Threshold | Critical Threshold | Action |
|--------|------------------|-------------------|--------|
| MSK OfflinePartitionsCount | > 0 for 1 min | > 0 for 5 min | Regional Switchover via ARC |
| EKS pod_cpu_utilization | > 80% | > 90% | HPA scaling (automated) |
| DocumentDB CPUUtilization | > 70% | > 80% | Monitor, consider scaling |
| RabbitMQ.ConnectionStatus | = 0 for 1 min | = 0 for 3 min | Connection retry, alert on-call |
| ApplicationPrefix.ErrorRate | > 3% | > 5% | Investigate errors, rollback if needed |

---

### Four Golden Signals Dashboard Layout

**Recommended CloudWatch Dashboard**: 4-quadrant layout for application monitoring

```
┌─────────────────────────────────────────────────────────────────┐
│ NXOP Application Monitoring - Four Golden Signals              │
│ Region: us-east-1 (Active) | us-west-2 (Standby)              │
├─────────────────────────────────┬───────────────────────────────┤
│ THROUGHPUT (Traffic)            │ LATENCY                       │
│                                 │                               │
│ Line Graph:                     │ Line Graph:                   │
│ • ApplicationPrefix.Throughput  │ • ApplicationPrefix.Latency   │
│ • By Region (east-1, west-2)    │ • P50, P95, P99 percentiles   │
│ • Threshold: 100 msg/min min    │ • By ServiceName              │
│ • Time: Last 24 hours           │ • Threshold: 5000ms P95 max   │
│                                 │ • SLA target annotation       │
│ Current: 450 msg/min ✓          │ Current: P95 = 2,340ms ✓      │
├─────────────────────────────────┼───────────────────────────────┤
│ ERRORS                          │ SATURATION                    │
│                                 │                               │
│ Stacked Area Chart:             │ Gauge Charts:                 │
│ • ApplicationPrefix.ErrorRate   │ • CPU Utilization: 65% ✓      │
│ • By ErrorType and Region       │   Target: < 80%               │
│ • Threshold: 5% maximum         │ • Memory Utilization: 72% ✓   │
│ • Color: Red above threshold    │   Target: < 85%               │
│                                 │ • Connection Pool: 58% ✓      │
│ Current: 1.2% ✓                 │   Target: < 85%               │
├─────────────────────────────────┴───────────────────────────────┤
│ CROSS-REGION SYNC LAG                                          │
│ • us-east-1 → us-west-2: 12 seconds ✓ (Target: < 120s)        │
│ • MSK Replication Lag: 8 seconds ✓                             │
│ • DocumentDB Replication Lag: 5 seconds ✓                      │
├─────────────────────────────────────────────────────────────────┤
│ RECENT ALARMS & EVENTS                                          │
│ • 14:23 - EKS Pod Restart (us-east-1) - Resolved               │
│ • 12:45 - MSK Consumer Lag Warning (us-west-2) - Resolved      │
│ • 09:15 - Health Check Success - All systems operational       │
└─────────────────────────────────────────────────────────────────┘
```

**Dashboard Widgets**:

| Widget | Type | Metrics | Purpose |
|--------|------|---------|---------|
| **Throughput** | Line graph | ApplicationPrefix.Throughput by Region | Monitor message processing rate |
| **Latency** | Line graph | ApplicationPrefix.Latency (P50, P95, P99) | Monitor processing performance |
| **Errors** | Stacked area | ApplicationPrefix.ErrorRate by ErrorType | Monitor error distribution |
| **Saturation** | Gauge | CPU, Memory, Connection Pool utilization | Monitor resource usage |
| **Cross-Region Sync** | Number | CrossRegion.SyncLag, Replication metrics | Monitor data consistency |
| **Recent Alarms** | Log widget | CloudWatch Alarms state changes | Track alarm history |
| **Region Status** | Text widget | Active/Standby status | Show current region state |

**Color Coding**:
- **Green**: Metric within normal range (OK)
- **Yellow**: Metric above warning threshold (WARNING)
- **Red**: Metric above critical threshold (ALARM)
- **Gray**: No data or metric not applicable

---

## Deployed Dashboard: NXOP Region Readiness

**Current Implementation**: The NXOP Region Readiness Dashboard is deployed and monitors regional health and disaster recovery readiness.

### Dashboard Structure

The dashboard is organized into the following sections:

| Section | Widgets | Metrics Covered | Purpose |
|---------|---------|-----------------|---------|
| **MSK Cluster Health** | 2 widgets | ActiveControllerCount (both regions) | Monitor Kafka cluster controller status |
| **MSK Throughput** | 2 widgets | MessagesInPerSec by broker, ClientConnectionCount | Track message ingestion rates and connections |
| **MSK Replication** | 2 widgets | ReplicatorThroughput, ReplicatorLatency | Monitor cross-region replication |
| **MSK Health Canary** | 5 widgets | ProducerLatency (seq 11-60), ConsumerHealth, ProcessingLatency, MessagesProcessed, Producer Performance | Validate end-to-end MSK health |
| **DocumentDB Global Cluster** | 2 widgets | GlobalClusterReplicationLag (both directions) | Monitor cross-region replication lag |
| **DocumentDB Regional Health** | 4 widgets | DatabaseConnections, CPUUtilization (NXOP & FXIP) | Monitor regional cluster health |
| **Network Load Balancer** | 1 widget | HealthyHostCount (IAM & SASL targets) | Monitor NLB target health |
| **DR Readiness** | 2 widgets | Route53 HealthCheckStatus, ARC Routing Control Status | Validate failover readiness |

### Key Metrics Tracked

**MSK Metrics**:
- `AWS/Kafka.ActiveControllerCount` - Cluster controller availability
- `AWS/Kafka.MessagesInPerSec` - Message ingestion rate per broker
- `AWS/Kafka.ClientConnectionCount` - Active client connections
- `AWS/Kafka.ReplicatorThroughput` - Cross-region replication throughput
- `AWS/Kafka.ReplicatorLatency` - Cross-region replication lag

**MSK Health Canary Metrics** (Custom):
- `MSK/Health.ProducerLatency` - Individual message produce latency (sequences 11-60)
- `MSK/Health.ConsumerHealth` - Real-time consumer health status
- `MSK/Health.ProcessingLatency` - Consumer processing latency (local vs replicated)
- `MSK/Health.ReplicationLatency` - Cross-region replication latency
- `MSK/Health.MessagesProcessed` - Message processing rate (local vs replicated)
- `MSK/Health.BatchMessagesProduced` - Producer batch performance
- `MSK/Health.BatchSuccessRate` - Producer batch success rate

**DocumentDB Metrics**:
- `AWS/DocDB.GlobalClusterReplicationLag` - Cross-region replication lag (both directions)
- `AWS/DocDB.DatabaseConnections` - Active database connections
- `AWS/DocDB.CPUUtilization` - Cluster CPU usage

**Network Metrics**:
- `AWS/NetworkELB.HealthyHostCount` - NLB target health (IAM & SASL)

**DR Readiness Metrics**:
- `AWS/Route53.HealthCheckStatus` - MSK endpoint health checks
- ARC Routing Control Status (via CLI) - Traffic routing state

### Dashboard Gaps and Recommended Additions

Based on the comprehensive metrics strategy, the following additions would enhance monitoring:

#### 1. **EKS Application Metrics** (Missing)
Add widgets for:
- `ContainerInsights.pod_cpu_utilization` - Pod resource usage
- `ContainerInsights.pod_memory_utilization` - Pod memory usage
- `ContainerInsights.pod_restart_count` - Pod stability
- `NXOP/Processing.ApplicationPrefix.Throughput` - Application throughput
- `NXOP/Processing.ApplicationPrefix.Latency` - Application latency (P95)
- `NXOP/Processing.ApplicationPrefix.ErrorRate` - Application error rate

**Rationale**: Currently monitoring infrastructure (MSK, DocumentDB) but not the EKS applications that process messages.

#### 2. **S3 MRAP Metrics** (Missing)
Add widgets for:
- `AWS/S3.AllRequests` (MultiRegionAccessPointName) - MRAP request volume
- `AWS/S3.4xxErrors` - Client errors
- `AWS/S3.5xxErrors` - Server errors
- `AWS/S3.FirstByteLatency` - MRAP response latency

**Rationale**: Flow 8 (Pilot Briefing Package) uses S3 MRAP for document storage.

#### 3. **Cross-Account IAM Metrics** (Missing)
Add widgets for:
- `CWLogs.AssumeRoleWithWebIdentity.Success` - Pod Identity role assumption
- `CWLogs.AssumeRole.CrossAccount.Failures` - Cross-account role failures
- `AWS/CloudTrail.IAM.AccessDeniedErrors` - Permission issues

**Rationale**: Critical for monitoring cross-account access from KPaaS to NXOP resources.

#### 4. **MSK Partition Health** (Missing)
Add widgets for:
- `AWS/Kafka.OfflinePartitionsCount` - Offline partitions
- `AWS/Kafka.UnderReplicatedPartitions` - Under-replicated partitions
- `AWS/Kafka.UnderMinIsrPartitionCount` - ISR health

**Rationale**: These are critical indicators for MSK cluster health and should trigger regional switchover.

#### 5. **Four Golden Signals Dashboard** (Recommended)
Create a separate application-focused dashboard with:
- **Throughput**: Message processing rate across all flows
- **Latency**: End-to-end processing latency (P50, P95, P99)
- **Errors**: Error rate by error type and service
- **Saturation**: Resource utilization (CPU, memory, connections)

**Rationale**: Provides application-level SLI monitoring complementing infrastructure metrics.


### Alert Configuration

The dashboard should be complemented with CloudWatch Alarms for critical metrics:

| Metric | Threshold | Action | Priority |
|--------|-----------|--------|----------|
| `OfflinePartitionsCount` | > 0 for 5 min | Trigger ARC Regional Switchover | Critical |
| `ActiveControllerCount` | ≠ 1 for 5 min | Alert on-call, investigate cluster | Critical |
| `GlobalClusterReplicationLag` | > 30 seconds | Alert on-call, check replication | High |
| `HealthyHostCount` | < 2 hosts | Alert on-call, check NLB targets | High |
| `Route53.HealthCheckStatus` | = 0 (unhealthy) | Trigger ARC failover | Critical |
| `MSK/Health.ConsumerHealth` | = 0 for 3 min | Alert on-call, check canary | High |
| `ReplicatorLatency` | > 60 seconds | Alert on-call, check replicator | Medium |

See [Region Readiness Assessment](05-Region-Readiness-Assessment.md) for complete composite alarm configuration.

---

## Related Documentation

- **[Infrastructure Failures](03-Infrastructure-Failures.md)** - Failure modes requiring metrics
- **[Region Readiness Assessment](05-Region-Readiness-Assessment.md)** - Composite alarm structure
- **[Architecture Overview](01-Architecture-Overview.md)** - Component architecture

---

**Document Owner**: NXOP Platform Team  
**Last Updated**: 2026-01-19  
**Review Frequency**: Quarterly
