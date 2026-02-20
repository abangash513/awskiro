# NXOP Platform - Complete Deep Dive Analysis

**Document Version**: 1.0  
**Last Updated**: January 27, 2026  
**Analysis Scope**: Complete NXOP Architecture, Resilience, and Operations

---

## Executive Summary

This comprehensive analysis consolidates all aspects of the American Airlines NXOP (Next Generation Operations Platform) project, covering architecture, integration patterns, failure modes, monitoring strategy, and disaster recovery orchestration.

### Key Platform Characteristics

- **25 Message Flows** across 7 integration patterns
- **Multi-Region Architecture**: AWS us-east-1 (primary) / us-west-2 (secondary) + Azure
- **Recovery Time Objective (RTO)**: 
  - 76% of flows: < 5 minutes (HA Automated)
  - 16% of flows: < 10 minutes (Regional Switchover)
  - 8% of flows: 15+ minutes (Manual Intervention)
- **Core Infrastructure**: EKS (via KPaaS), MSK, DocumentDB Global Cluster, S3 MRAP
- **Monitoring**: ~150 CloudWatch metrics across 4 layers
- **Resilience**: 35 documented failure modes with automated recovery strategies

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Message Flow Analysis](#2-message-flow-analysis)
3. [Integration Patterns](#3-integration-patterns)
4. [Infrastructure Failures](#4-infrastructure-failures)
5. [CloudWatch Metrics Strategy](#5-cloudwatch-metrics-strategy)
6. [Region Readiness Assessment](#6-region-readiness-assessment)
7. [Region Switch Orchestration](#7-region-switch-orchestration)
8. [Recovery Mapping](#8-recovery-mapping)

---


## 1. Architecture Overview

### 1.1 Multi-Region Architecture

**Primary Components**:
- **AWS Regions**: us-east-1 (primary), us-west-2 (secondary)
- **Azure Integration**: FXIP platform, OpsHub Event Hubs
- **On-Premises**: FOS (Flight Operations System), AIRCOM Server, MQ infrastructure

**Account Structure**:
- **NXOP Account**: MSK, DocumentDB, S3, Route53, ARC
- **KPaaS Account**: EKS clusters, application workloads, NLBs

### 1.2 Core Infrastructure Components

#### EKS Clusters (KPaaS Account)
- **Deployment**: Multi-region (us-east-1, us-west-2)
- **Workloads**: Flight Data Adapter, Aircraft Data Adapter, Notification Service, Document Assembly
- **Access Pattern**: Cross-account IAM via Pod Identity
- **Scaling**: Horizontal Pod Autoscaler (HPA), Cluster Autoscaler
- **Networking**: VPC-attached, private subnets, NLB ingress

#### MSK Clusters (NXOP Account)
- **Configuration**: Multi-region with bi-directional replication
- **Bootstrap**: Route53 DNS (kafka.nxop.com) → NLB → MSK brokers
- **Connection Pattern**: Route53/NLB for bootstrap, then direct broker connections
- **Topics**: Dedicated per flow (fos-events, flight-plans, audit-logs, etc.)
- **Replication**: Cross-region replicator with < 2 second lag target
- **Security**: SASL_SSL with AWS_MSK_IAM authentication

#### DocumentDB Global Cluster (NXOP Account)
- **Configuration**: Primary (us-east-1), Secondary (us-west-2)
- **Failover**: Automatic < 1 minute
- **Use Cases**: Reference data enrichment, metadata storage, briefing packages
- **Access Pattern**: Read-heavy with occasional writes
- **Replication Lag**: < 15 seconds target

#### S3 Multi-Region Access Point (NXOP Account)
- **Configuration**: MRAP spanning us-east-1 and us-west-2 buckets
- **Replication**: Cross-Region Replication (CRR) with < 5 minute target
- **Use Cases**: Document storage (pilot briefing packages, charts, weather data)
- **Failover**: Automatic via MRAP routing


### 1.3 Network Architecture

#### Traffic Routing
- **Akamai GTM**: Fronts inbound HTTPS API endpoints exposed by EKS apps
- **AMQP Traffic**: Direct to EKS pods (bypasses Akamai)
- **Outbound HTTPS**: Direct from EKS to external systems (bypasses Akamai)
- **MSK Access**: Route53 DNS for bootstrap, direct broker connections for produce/consume

#### Cross-Account Connectivity
- **Pod Identity**: EKS pods assume IAM roles in NXOP account
- **Role Chain**: KPaaS Pod Identity → NXOP IAM Role → MSK/DocumentDB/S3
- **Security Groups**: Configured for cross-account VPC traffic
- **VPC Peering/Transit Gateway**: Enables cross-account networking

#### DNS Strategy
- **Route53 Hosted Zone**: kafka.nxop.com for MSK bootstrap
- **Health Checks**: Monitor NLB and MSK cluster health
- **Active/Passive Routing**: Primary region active, secondary passive
- **TTL**: Low values (60s) for fast failover

### 1.4 Security Architecture

#### Authentication & Authorization
- **Pod Identity**: EKS pods use IRSA (IAM Roles for Service Accounts)
- **Cross-Account IAM**: Trust relationships between KPaaS and NXOP accounts
- **MSK Authentication**: SASL_SSL with AWS_MSK_IAM
- **DocumentDB Authentication**: IAM database authentication
- **S3 Authentication**: IAM roles with bucket policies

#### Network Security
- **Security Groups**: Layered approach (EKS, MSK, DocumentDB, NLB)
- **NACLs**: Subnet-level traffic control
- **Private Subnets**: All infrastructure in private subnets
- **VPC Endpoints**: For AWS service access without internet gateway


---

## 2. Message Flow Analysis

### 2.1 Flow Distribution

**Total Flows**: 25 message flows
- **NXOP-Managed**: 19 flows (76%)
- **Non-NXOP**: 6 flows (24%) - Direct Flightkeys/FXIP to CyberJet FMS

**Primary Integration Hub**: OpsHub On-Prem (100% of flows)
**Primary Data Source**: Flightkeys (80% of flows)

### 2.2 Communication Protocols

| Protocol | Flow Count | Usage |
|----------|------------|-------|
| HTTPS | 18 flows | API calls, synchronous delivery |
| AMQP | 10 flows | Flightkeys ingestion, asynchronous |
| Kafka | 6 flows | Event streaming, MSK |
| MQ | 5 flows | On-premises integration |
| ACARS | 4 flows | Aircraft communication |
| TCP | 2 flows | Legacy protocols |

### 2.3 Key Message Flows

#### Flow 1: FOS Events to Flightkeys (Outbound Publishing)
- **Pattern**: MQ → Kafka → HTTPS
- **Infrastructure**: MQ-Kafka Adapter (on-prem), MSK, Flight/Aircraft Data Adapters (EKS)
- **Recovery**: HA Automated (< 5 min RTO)
- **Dependencies**: MSK, DocumentDB (reference data), Cross-account IAM

#### Flow 2: Flight Plans from Flightkeys (Inbound Ingestion)
- **Pattern**: AMQP → Kafka → MQ
- **Infrastructure**: Flight Plan Processor (EKS), MSK, Kafka-MQ Adapter
- **Recovery**: HA Automated (< 5 min RTO)
- **Dependencies**: MSK, Cross-account IAM

#### Flow 8: Pilot Briefing Package (Document Assembly)
- **Pattern**: HTTPS → Multi-Service Orchestration → HTTPS
- **Infrastructure**: Flightkeys Integration Service, Flight Plan Service, Pilot Document Service, DocumentDB, S3
- **Recovery**: HA Automated (< 5 min RTO)
- **Dependencies**: DocumentDB (metadata), S3 (documents), Cross-account IAM

#### Flows 9, 10: Electronic Signature (Authorization)
- **Pattern**: AMQP + HTTPS (hybrid)
- **Infrastructure**: Event Processor, Integration Service, LCA/FTM Proxies
- **Recovery**: Manual Intervention (15+ min RTO)
- **Reason**: Compliance requirements, signature validation


---

## 3. Integration Patterns

### 3.1 Pattern Classification

| Pattern Type | Flow Count | Recovery | RTO Target | Complexity |
|--------------|------------|----------|------------|------------|
| **Inbound Data Ingestion** | 10 flows | 80% HA, 20% Regional | < 5 min (HA), 5-15 min (Regional) | Medium |
| **Outbound Data Publishing** | 4 flows | 100% HA | < 5 min | Low |
| **Bidirectional Sync** | 4 flows | 50% HA, 50% Manual | < 5 min (HA), 15+ min (Manual) | High |
| **Notification/Alert** | 3 flows | 100% HA | < 5 min | Medium |
| **Document Assembly** | 1 flow | 100% HA | < 5 min | Medium-Low |
| **Authorization** | 2 flows | 100% Manual | 15+ min | High |
| **Data Maintenance** | 1 flow | 100% HA | < 5 min | Low |

### 3.2 Pattern 1: Inbound Data Ingestion

**Characteristics**:
- External sources → NXOP → On-Prem/External systems
- Primary communication: AMQP/HTTPS → Processing → HTTPS/Kafka/MQ/ACARS
- 10 flows (2, 3, 4, 5, 6, 7, 8, 14, 19, 20)

**Variations**:
1. **AMQP → MSK → MQ** (Flows 2, 5): Event streaming with Kafka persistence
2. **AMQP → HTTPS** (Flows 3, 4, 6): Synchronous delivery via proxies
3. **HTTPS → Processing** (Flows 23, 24): Data maintenance services
4. **IBM Fusion Integration** (Flow 20): Multi-hop delivery

**Common Failure Modes**:
- External source connection loss → Connection retry with exponential backoff
- Message processing errors → Dead letter queue, error handling
- MSK topic unavailability → Cross-region failover
- Downstream delivery failure → Message retry, alternative paths

### 3.3 Pattern 2: Outbound Data Publishing

**Characteristics**:
- On-Prem → NXOP → External systems
- Primary communication: MQ → Kafka → HTTPS
- 4 flows (1, 18, 23, 24)

**Architecture**:
- MQ-Kafka Adapter (on-prem) produces to MSK
- Flight/Aircraft Data Adapters (EKS) consume from MSK
- Adapters invoke external APIs (Flightkeys, Azure Event Hubs)

**Recovery**: 100% HA Automated (< 5 min RTO)


---

## 4. Infrastructure Failures

### 4.1 Failure Mode Taxonomy

**Total Failure Modes**: 35 across 5 major categories

| Category | Failure Modes | Recovery Distribution |
|----------|---------------|----------------------|
| **Infrastructure Components** | 14 modes | 9 HA, 3 Regional, 2 Manual |
| **Network Infrastructure** | 8 modes | 3 HA, 2 Regional, 3 Manual |
| **Data Replication** | 3 modes | 3 HA |
| **DR Orchestration** | 7 modes | 0 HA, 0 Regional, 7 Manual |
| **Application Functionality** | 23 modes | 6 HA, 3 Regional, 14 Manual |

### 4.2 Recovery Type Distribution

| Recovery Type | Count | Percentage | RTO Target |
|---------------|-------|------------|------------|
| **HA - Automated** | 15 modes | 43% | < 5 minutes |
| **Regional Switchover** | 8 modes | 23% | 5-15 minutes |
| **Manual Intervention** | 12 modes | 34% | 15+ minutes |

### 4.3 Critical Failure Modes

#### High Priority (Critical Impact, Medium/High Likelihood)

**1. RabbitMQ Connection Loss**
- **Impact**: Critical - No data ingestion
- **Likelihood**: Medium
- **Recovery**: HA Automated
- **Strategy**: Connection retry with exponential backoff, multiple endpoint config
- **Affected Flows**: All AMQP-based flows (2, 3, 4, 6, 7, 9, 14)

**2. Resource Exhaustion (CPU/Memory)**
- **Impact**: High - Performance degradation
- **Likelihood**: High
- **Recovery**: HA Automated
- **Strategy**: HPA scaling, resource limit tuning
- **Affected Flows**: All 19 NXOP flows

#### Monitor Closely (High/Critical Impact, Low Likelihood)

**3. Complete EKS Cluster Failure**
- **Impact**: Critical - Regional processing stops
- **Likelihood**: Low
- **Recovery**: Regional Switchover
- **Strategy**: ARC-orchestrated cross-region failover
- **RTO**: 5-15 minutes

**4. Complete MSK Cluster Failure**
- **Impact**: Critical - Regional Kafka unavailable
- **Likelihood**: Low
- **Recovery**: Regional Switchover
- **Strategy**: Route53 health checks + ARC automation
- **RTO**: 5-15 minutes
- **Affected Flows**: 6 flows (1, 2, 5, 10, 18, 19)


### 4.4 Cascading Failure Prevention

#### Circuit Breaker Pattern
- **Applicable Flows**: All flows with external dependencies (1-25)
- **Configuration**: 5 failures in 10 seconds → Open circuit
- **Timeout**: 30 seconds before testing recovery
- **Prevents**: RabbitMQ connection loss, MSK connector failures, Azure Event Hub connectivity issues

#### Bulkhead Pattern
- **Applicable Flows**: MSK-dependent flows (1, 2, 5, 10, 18, 19)
- **Configuration**: 10 connections per service, dedicated topics per flow
- **Prevents**: MSK disk space exhaustion, connection pool exhaustion

#### Graceful Degradation
- **Applicable Flows**: Document Assembly (8), Engineering Data (16, 17)
- **Levels**:
  - Level 1: Primary DocumentDB (real-time, full features)
  - Level 2: Secondary DocumentDB (15s lag, slight delay notice)
  - Level 3: S3 Cache (5 min stale, stale data warning)
  - Level 4: Partial Assembly (incomplete, missing components notice)

---

## 5. CloudWatch Metrics Strategy

### 5.1 Metrics Hierarchy

**Total Metrics**: ~150 across 4 layers

| Layer | Components | Metric Count | Purpose |
|-------|------------|--------------|---------|
| **Infrastructure** | EKS, MSK, DocumentDB, S3 | ~80 | Monitor compute, storage, messaging |
| **Network** | NLB, VPC, Route53, ARC | ~35 | Monitor connectivity, load balancing, DNS |
| **Data** | Replication (MSK, DocumentDB, S3) | ~15 | Monitor cross-region data sync |
| **Application** | Four Golden Signals, SLI | ~20 | Monitor business functionality |

### 5.2 Key Metric Categories

#### EKS Metrics (ContainerInsights)
- **Node Metrics**: CPU, memory, filesystem, network utilization
- **Pod Metrics**: CPU, memory, restart count
- **Application Metrics**: Throughput, latency, error rate, health checks

#### MSK Metrics (AWS/Kafka, MSK/Health)
- **Cluster Metrics**: Controller count, offline partitions, under-replicated partitions
- **Broker Metrics**: CPU, memory, disk usage, network drops
- **Topic Metrics**: Bytes in/out, messages in/out, conversions
- **Replicator Metrics**: Replication lag, bytes/records per second
- **Canary Metrics**: Producer latency, consumer health, replication latency


#### DocumentDB Metrics (AWS/DocDB, NXOP/Database)
- **Cluster Metrics**: CPU, memory, connections, read/write latency, IOPS
- **Instance Metrics**: Per-instance CPU, memory, connections, throughput
- **Global Cluster Metrics**: Replication lag, data transfer bytes, replicated write IO
- **Application Metrics**: Connection errors, query latency, transaction errors, pool utilization

#### S3 Metrics (AWS/S3, NXOP/Storage)
- **MRAP Metrics**: All requests, 4xx/5xx errors, first byte latency, total latency
- **Regional Bucket Metrics**: Get/Put requests, errors, latency
- **Replication Metrics**: Replication latency, bytes/operations pending, replicated bytes
- **Application Metrics**: Operation latency, errors, throughput utilization, integrity checks

#### Network Metrics (AWS/NetworkELB, NXOP/Network)
- **NLB Metrics**: Active/new flow count, processed bytes, TCP resets
- **Target Group Metrics**: Healthy/unhealthy host count, connection errors, TLS errors
- **VPC Metrics**: Packets dropped/received/sent, bytes received/sent
- **Security Group Metrics**: Rule count, connection blocked, rule violations

### 5.3 MSK Health Canary

**Purpose**: Continuous validation of MSK cluster health, cross-region replication, and end-to-end message flow

**Architecture**:
- **Producer Lambda**: Scheduled every 1 minute, produces 60 messages (1/sec) to MSK
- **Consumer Lambda**: Event Source Mapping (ESM) from MSK, processes local and replicated messages
- **Bi-Directional**: Both regions produce and consume, validating replication in both directions

**Metrics Published**:
- **Producer**: BatchSuccessRate, ProducerLatency, BatchMessagesProduced, BatchTotalLatency
- **Consumer**: ConsumerHealth, ProcessingLatency (local), ReplicationLatency (cross-region), MessagesProcessed

**Replication Validation**:
- **Target**: P95 replication latency < 2 seconds
- **Actual**: P95 ~850ms (sub-second replication)
- **Message Flow**: 120 messages/min per consumer (60 local + 60 replicated)


---

## 6. Region Readiness Assessment

### 6.1 Hierarchical Health Check System

**Framework**: L1-L4 layered health checks with composite scoring

| Layer | Weight | Components | Target Score |
|-------|--------|------------|--------------|
| **L1 - Infrastructure** | 30% | EKS, MSK, DocumentDB, S3 | ≥ 90% |
| **L2 - Network** | 25% | NLB, DNS, Cross-Account | ≥ 90% |
| **L3 - Data** | 25% | Replication (MSK, DocumentDB, S3) | ≥ 90% |
| **L4 - Application** | 20% | Service, End-to-End, Canary | ≥ 90% |

**Master Readiness Threshold**: ≥ 90% composite score required for Regional Switchover

### 6.2 L1 - Infrastructure Layer

#### EKS Cluster Health (35% weight)
- **Node Capacity**: ≥ 80% of desired instances (50% weight)
- **Pod Capacity**: < 70% average CPU utilization (30% weight)
- **Pod Health**: < 2 restarts/hour (20% weight)

#### MSK Cluster Health (30% weight)
- **Controller**: ActiveControllerCount = 1 (30% weight)
- **Partitions**: OfflinePartitionsCount = 0 (25% weight)
- **Replication**: UnderReplicatedPartitions = 0 (25% weight)
- **Brokers**: CpuIdle > 30% average (20% weight)

#### DocumentDB Cluster Health (25% weight)
- **CPU**: < 70% utilization (25% weight)
- **Memory**: > 30% freeable memory (25% weight)
- **Connections**: < 80% of max (25% weight)
- **Latency**: < 50ms P95 read/write (25% weight)

#### S3 Bucket Health (10% weight)
- **Availability**: < 0.1% 5xx error rate (40% weight)
- **Performance**: < 200ms P95 first byte latency (30% weight)
- **MRAP**: > 0 requests/min (30% weight)

### 6.3 L2 - Network Layer

#### Load Balancer Health (40% weight)
- **Targets**: ≥ 2 healthy targets (50% weight)
- **Resets**: < 10 TCP resets/min (25% weight)
- **Throughput**: > baseline processed bytes (25% weight)

#### DNS Health (35% weight)
- **Health Check**: HealthCheckStatus = 1 (60% weight)
- **Latency**: < 2000ms connection time (40% weight)

#### Cross-Account Connectivity (25% weight)
- **Role Chain**: > 95% AssumeRole success (40% weight)
- **Latency**: < 3000ms role assumption (30% weight)
- **Failures**: < 2 failures/hour (30% weight)


### 6.4 L3 - Data Layer

#### Replication Health (100% weight)
- **MSK Replication**: < 2 seconds lag (35% weight)
- **DocumentDB Replication**: < 15 seconds lag (35% weight)
- **S3 Replication**: < 300 seconds lag (30% weight)

### 6.5 L4 - Application Layer

#### Service Health (40% weight)
- **Pod Readiness**: < 2 restarts/hour (30% weight)
- **Pod Resources**: < 80% CPU utilization (25% weight)
- **Service Health**: ApplicationPrefix.HealthCheck = 1 (45% weight)

#### End-to-End Health - Active Region (35% weight)
- **Ingestion**: > 50 messages/min (40% weight)
- **Latency**: < 20000ms P95 (35% weight)
- **Errors**: < 2% error rate (25% weight)

#### End-to-End Health - Standby Region (35% weight)
- **App Readiness**: ApplicationPrefix.HealthCheck = 1 (50% weight)
- **Resource Capacity**: < 70% CPU utilization (30% weight)
- **Connectivity Test**: 0 Kafka connection errors/5min (20% weight)

#### Canary Health (25% weight)
- **Producer**: > 95% batch success rate (35% weight)
- **Consumer**: ConsumerHealth = 1 (35% weight)
- **Replication**: < 15000ms P95 replication latency (30% weight)

### 6.6 Continuous Monitoring (Phase 0)

**Frequency**: Every 1 minute
**Purpose**: Eliminate pre-flight checks during failover
**Benefit**: Reduces total failover time to < 10 minutes

**Readiness States**:
- **READY**: ≥ 90% composite score
- **DEGRADED**: 70-89% composite score
- **NOT READY**: < 70% composite score

---

## 7. Region Switch Orchestration

### 7.1 Failover Phases

**Total RTO**: < 10 minutes (with continuous Phase 0 monitoring)

#### Phase 0: Continuous Readiness Validation (Pre-Failover)
- **Frequency**: Every 1 minute
- **Activities**: L1-L4 health checks, composite scoring
- **Threshold**: ≥ 90% required to proceed with failover

#### Phase 1: Infrastructure Isolation (Concurrent Execution)
- **Duration**: 1-2 minutes
- **Activities**:
  - Toggle ARC routing controls (West ON, East OFF)
  - Security group cordon to force MSK client reconnections
  - DocumentDB global cluster failover
- **Concurrency**: All activities execute in parallel


#### Phase 2: Application Failover (Concurrent Execution)
- **Duration**: 5-7 minutes
- **Activities**:
  - Update Akamai GTM to point to West NLB
  - Trigger AMQP listeners in West region
  - Validate connector auto-reconnection (MSK, Kafka-MQ, Azure Event Hubs)
- **Concurrency**: All activities execute in parallel

#### Phase 3: Post-Failover Validation
- **Duration**: 3-5 minutes
- **Activities**:
  - Validate L1-L4 composite health alarms
  - Verify message flow resumption
  - Confirm no data loss
  - Monitor for errors

### 7.2 Trigger Conditions

**Automatic Triggers**:
1. Complete regional AWS service outage
2. Major infrastructure failures (complete EKS, MSK, or NLB failure)
3. Network partition between regions
4. L1-L4 composite score < 70% in active region for > 5 minutes

**Manual Triggers**:
1. Planned maintenance requiring region evacuation
2. Disaster recovery drill
3. Operational decision by SRE team

### 7.3 ARC (Application Recovery Controller)

**Components**:
- **Control Cluster**: Manages routing controls and safety rules
- **Routing Controls**: Binary ON/OFF switches for each region
- **Safety Rules**: Prevent simultaneous activation of both regions
- **Readiness Checks**: Continuous validation of resource readiness

**Routing Control States**:
- **us-east-1**: ON (active) / OFF (standby)
- **us-west-2**: OFF (standby) / ON (active)

**Safety Rule**: At most one region can be ON at any time

---

## 8. Recovery Mapping

### 8.1 Flow Recovery Distribution

| Recovery Type | Flow Count | Percentage | RTO | Flow Numbers |
|---------------|------------|------------|-----|--------------|
| **HA - Automated** | 19 flows | 76% | < 5 min | 1, 2, 5, 6, 8, 11, 14-24 |
| **Regional Switchover** | 4 flows | 16% | < 10 min | 3, 4, 7, 13 |
| **Manual Intervention** | 2 flows | 8% | 15+ min | 9, 10 |

### 8.2 Component Dependency Matrix

**Universal Dependencies** (All 25 flows):
- EKS (100%)
- Cross-Account IAM (100%)

**Selective Dependencies**:
- MSK: 6 flows (1, 2, 5, 10, 18, 19) - 24%
- DocumentDB: 5 flows (1, 8, 10, 18, 19) - 20%
- S3: 1 flow (8) - 4%


### 8.3 Recovery Scenarios

#### Scenario 1: HA Automated Recovery (Flow 1: FOS Events to Flightkeys)
**Failure**: EKS pod failure  
**Total RTO**: < 5 minutes

| Phase | Duration | Activities |
|-------|----------|------------|
| Detection | 0-1 min | Health check fails, K8s detects unhealthy pod |
| Execution | 1-2 min | Kubernetes automatically restarts pod |
| Ready | 2-3 min | Pod passes readiness probe, joins service |
| Verification | 3-5 min | Traffic resumes, health checks pass |

#### Scenario 2: Regional Switchover (Flow 3: Flightkeys Events to FOS)
**Failure**: Complete EKS cluster failure in us-east-1  
**Total RTO**: < 10 minutes

| Phase | Duration | Activities |
|-------|----------|------------|
| Detection | 0-1 min | Continuous monitoring detects cluster failure |
| Phase 1 | 1-2 min | ARC toggle, SG cordon, DocumentDB failover (concurrent) |
| Phase 2 | 2-7 min | Akamai GTM update, AMQP listeners, connectors (concurrent) |
| Phase 3 | 7-10 min | L1-L4 health check validation |

#### Scenario 3: Manual Intervention (Flow 9: eSignature - CCI)
**Failure**: Cross-account IAM role chain failure  
**Total RTO**: 15-20+ minutes

| Phase | Duration | Activities |
|-------|----------|------------|
| Detection | 0-5 min | Alarm triggers, PagerDuty alert, engineer notified |
| Investigation | 5-10 min | Engineer reviews logs, identifies IAM issue |
| Remediation | 10-15 min | Manual IAM role fix, policy update |
| Validation | 15-20 min | Test signature flow, monitor for errors |

### 8.4 Chaos Engineering Experiments

**Top 10 High-Risk Failure Modes** (prioritized by impact and likelihood):

1. **Single MSK Broker Failure** (Medium impact, High likelihood)
   - AWS FIS: ✅ Yes (Lambda → RebootBroker API)
   - Patterns Tested: Outbound Publishing, Bidirectional Sync
   - Affected Flows: 1, 2, 5, 18, 19

2. **MSK Network Latency** (High impact, Medium likelihood)
   - AWS FIS: ✅ Yes (network:disrupt-connectivity with latency)
   - Patterns Tested: Outbound Publishing, Bidirectional Sync
   - Affected Flows: 1, 2, 5, 18, 19

3. **DocumentDB Primary Failover** (High impact, Medium likelihood)
   - AWS FIS: ✅ Yes (Lambda → FailoverDBCluster API)
   - Patterns Tested: Outbound Publishing, Document Assembly, Bidirectional Sync
   - Affected Flows: 1, 8, 10, 18, 19

4. **Security Group Rule Misconfiguration** (High impact, Medium likelihood)
   - AWS FIS: ✅ Yes (Lambda → Modify SG rules)
   - Patterns Tested: All 7 patterns
   - Affected Flows: All 19 NXOP flows

5. **RabbitMQ Connection Loss** (Critical impact, High likelihood)
   - AWS FIS: ⚠️ Partial (network:disrupt-connectivity)
   - Patterns Tested: Inbound Ingestion, Bidirectional Sync
   - Affected Flows: 2, 3, 4, 6, 7, 9, 14


---

## 9. Key Insights and Recommendations

### 9.1 Strengths

1. **High Availability**: 76% of flows have automated recovery with < 5 minute RTO
2. **Multi-Region Resilience**: Active-standby architecture with < 10 minute regional failover
3. **Comprehensive Monitoring**: ~150 CloudWatch metrics across 4 layers
4. **Continuous Readiness**: Phase 0 validation eliminates pre-flight checks during failover
5. **Sub-Second Replication**: MSK cross-region replication P95 ~850ms
6. **Automated Orchestration**: ARC-driven failover with safety rules
7. **Cascading Failure Prevention**: Circuit breakers, bulkheads, graceful degradation

### 9.2 Areas for Improvement

1. **RabbitMQ Resilience**: Enhance connection pooling with multiple endpoints (Critical Priority)
2. **OnPrem Connectivity**: Automate network path restoration (currently manual)
3. **Authorization Flows**: Reduce manual intervention for flows 9, 10 (compliance constraints)
4. **MSK Standardization**: Migrate more flows to MSK for consistent event streaming
5. **Monitoring Consolidation**: Standardize application metrics across all services

### 9.3 Operational Recommendations

#### Pre-Failover Checklist
1. Verify target region readiness: L1-L4 composite score ≥ 90%
2. Check MSK canary health: Producer success > 95%, Consumer healthy, Replication < 2s
3. Validate cross-account IAM: Role assumption success > 95%
4. Confirm no recent alarms in last 5 minutes
5. Review DocumentDB replication lag: < 15 seconds
6. Verify S3 CRR status: < 300 seconds lag

#### Post-Failover Validation
1. Validate L1-L4 composite health alarms
2. Verify message flow resumption (check throughput metrics)
3. Confirm no data loss (check MSK consumer lag, DocumentDB replication)
4. Monitor for errors (check error rate metrics)
5. Validate end-to-end latency (< 20000ms P95)
6. Check canary health in new active region

#### Chaos Engineering Strategy
1. **Phase 1**: NXOP account experiments (#1-5) - Infrastructure resilience
2. **Phase 2**: KPaaS account experiments (#7-9) - Application layer testing
3. **Phase 3**: Cross-account experiments (#6, #10) - End-to-end validation
4. **Frequency**: Quarterly chaos drills, monthly canary validation


---

## 10. Technical Deep Dives

### 10.1 MSK Bootstrap and Connection Pattern

**Bootstrap Phase**:
1. Client (EKS pod or MQ-Kafka Adapter) queries Route53 DNS: `kafka.nxop.com`
2. Route53 returns active region's NLB endpoint (typically us-east-1)
3. Client connects to NLB, which forwards to MSK brokers
4. MSK returns cluster metadata (broker list, topic partitions)

**Direct Connection Phase**:
1. Client disconnects from NLB
2. Client connects directly to MSK brokers using metadata
3. Producer/Consumer operations bypass NLB (direct broker connections)
4. NLB only used for initial bootstrap

**Failover Behavior**:
1. Route53 health check detects MSK failure in us-east-1
2. Route53 updates DNS to point to us-west-2 NLB
3. Clients detect connection failure, re-bootstrap via DNS
4. Clients connect to us-west-2 MSK cluster
5. Message processing resumes with minimal data loss (Kafka persistence)

### 10.2 Cross-Account IAM Role Chain

**Role Chain Flow**:
1. **EKS Pod** (KPaaS account) uses IRSA (IAM Roles for Service Accounts)
2. **Pod Identity** assumes role in KPaaS account
3. **Cross-Account Assume Role** to NXOP account
4. **NXOP IAM Role** grants access to MSK, DocumentDB, S3

**Authentication Sequence**:
```
EKS Pod → IRSA Token → AssumeRoleWithWebIdentity (KPaaS) 
  → AssumeRole (NXOP) → Access MSK/DocumentDB/S3
```

**Security Considerations**:
- Trust relationships between KPaaS and NXOP accounts
- Least privilege IAM policies
- Session duration limits (1 hour default)
- Audit logging via CloudTrail

### 10.3 DocumentDB Global Cluster Failover

**Normal Operation**:
- Primary cluster: us-east-1 (read/write)
- Secondary cluster: us-west-2 (read-only)
- Replication lag: < 15 seconds

**Failover Trigger**:
1. Primary cluster failure detected
2. Automatic failover initiated by AWS
3. Secondary cluster promoted to primary
4. Applications reconnect to new primary

**Failover Duration**: < 1 minute (AWS-managed)

**Application Impact**:
- Brief connection interruption
- Automatic reconnection via connection pool
- No data loss (replication ensures consistency)


### 10.4 S3 Multi-Region Access Point (MRAP)

**Architecture**:
- Single global endpoint: `arn:aws:s3::123456789012:accesspoint/mrap-alias`
- Backed by regional buckets: us-east-1, us-west-2
- Cross-Region Replication (CRR) between buckets

**Request Routing**:
1. Application sends request to MRAP endpoint
2. MRAP routes to nearest healthy regional bucket
3. If regional bucket fails, MRAP automatically routes to other region
4. CRR ensures data consistency across regions

**Failover Behavior**:
- Automatic and transparent to applications
- No DNS updates required
- Sub-second failover for read operations
- Write operations may experience brief delay during CRR

**Use Case**: Pilot briefing package document storage (Flow 8)

---

## 11. Glossary

| Term | Definition |
|------|------------|
| **ARC** | Application Recovery Controller - AWS service for orchestrating multi-region failover |
| **CRR** | Cross-Region Replication - S3 feature for replicating objects across regions |
| **ESM** | Event Source Mapping - Lambda trigger for consuming from Kafka/MSK |
| **FOS** | Flight Operations System - On-premises airline operations platform |
| **HPA** | Horizontal Pod Autoscaler - Kubernetes feature for scaling pods based on metrics |
| **IRSA** | IAM Roles for Service Accounts - EKS feature for pod-level IAM roles |
| **ISR** | In-Sync Replicas - Kafka replicas that are fully caught up with the leader |
| **KPaaS** | Kubernetes Platform as a Service - Managed EKS platform |
| **MRAP** | Multi-Region Access Point - S3 feature for global access to regional buckets |
| **MSK** | Managed Streaming for Apache Kafka - AWS managed Kafka service |
| **NLB** | Network Load Balancer - AWS Layer 4 load balancer |
| **NXOP** | Next Generation Operations Platform - American Airlines modernization initiative |
| **Pod Identity** | EKS feature for assigning IAM roles to pods |
| **RTO** | Recovery Time Objective - Target time to restore service after failure |
| **SASL_SSL** | Simple Authentication and Security Layer with SSL - Kafka authentication protocol |

---

## 12. Related Documentation

### Internal Documents
- **00-NXOP-Message-Flow-Analysis.md** - Complete catalog of 25 message flows
- **01-Architecture-Overview.md** - Detailed architecture diagrams and component descriptions
- **02-Integration-Pattern-Resilience.md** - Pattern-level resilience analysis
- **03-Infrastructure-Failures.md** - Comprehensive failure mode catalog
- **04-CloudWatch-Metrics.md** - Complete metrics strategy with thresholds
- **05-Region-Readiness-Assessment.md** - L1-L4 health check framework
- **06-Region-Switch-Orchestration.md** - Detailed failover procedures
- **07-Message-Flow-Recovery-Mapping.md** - Flow-to-failure mode mapping

### External References
- AWS Well-Architected Framework - Reliability Pillar
- AWS Disaster Recovery Whitepaper
- Apache Kafka Documentation
- Amazon MSK Best Practices
- Amazon DocumentDB Global Clusters
- AWS Application Recovery Controller

---

## Document Metadata

**Document Owner**: NXOP Platform Team  
**Last Updated**: January 27, 2026  
**Review Frequency**: Quarterly  
**Version**: 1.0  
**Status**: Complete

**Contributors**:
- Architecture Team
- SRE Team
- Application Development Teams
- Operations Team

**Change Log**:
- 2026-01-27: Initial comprehensive analysis document created

