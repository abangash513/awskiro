# NXOP (Next Generation Operations Platform) - Complete Overview Summary

**Document Version**: 1.0  
**Created**: February 2, 2026  
**Organization**: American Airlines  
**Project**: NXOP Platform Migration from Azure FXIP to AWS

---

## Executive Summary

The **NXOP (Next Generation Operations Platform)** is American Airlines' strategic initiative to modernize flight operations infrastructure by migrating from the legacy Azure-based FXIP platform to a cloud-native AWS architecture.

### Key Statistics

- **25 Message Flows** across 7 integration patterns
- **5 Data Domains** with 24 core entities
- **21 Microservices** + 6 admin tools
- **Multi-Region**: AWS us-east-1 (primary), us-west-2 (secondary)
- **Multi-Cloud**: AWS (NXOP), Azure (FXIP coexistence), On-Premises (FOS)
- **RTO Target**: < 10 minutes for regional failover
- **RPO Target**: 0 messages (zero data loss)

---

## 1. Architecture Overview

### Multi-Cloud Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS NXOP Platform                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  KPaaS (EKS Clusters)                                     │  │
│  │  - 21 Microservices                                       │  │
│  │  - 6 Admin Tools                                          │  │
│  │  - Pod Identity (Cross-Account IAM)                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  NXOP Infrastructure                                      │  │
│  │  - MSK Clusters (Cross-Region Replication)               │  │
│  │  - DocumentDB Global Cluster                             │  │
│  │  - S3 + Iceberg Tables                                    │  │
│  │  - Route53 DNS, Akamai GTM                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌────────▼────────┐   ┌──────▼──────┐
│ Azure FXIP     │   │ On-Premises FOS │   │ External    │
│ - Flightkeys   │   │ - DECS          │   │ - CyberJet  │
│ - OpsHub       │   │ - Load Planning │   │ - IBM Fusion│
│ - CCI          │   │ - AIRCOM        │   │             │
└────────────────┘   └─────────────────┘   └─────────────┘
```

### Account Structure

1. **NXOP Account**: MSK, DocumentDB, S3, Route53, AWS ARC, Secrets Manager, KMS
2. **KPaaS Account**: EKS clusters, NLBs, VPC infrastructure, IAM roles for Pod Identity
3. **Network Account**: Transit Gateway, NAT Gateways, Direct Connect, Network Firewall

---

## 2. Technology Stack

### Core AWS Services

| Layer | Service | Configuration | Purpose |
|-------|---------|---------------|---------|
| **Compute** | Amazon EKS | 1.28+, Multi-AZ | Application workloads (21 microservices) |
| **Messaging** | Amazon MSK | Kafka 3.5+, 9 brokers/region | Event streaming (50+ topics) |
| **Database** | Amazon DocumentDB | 5.0+, Global Cluster | Operational data (24 collections) |
| **Storage** | Amazon S3 + MRAP | Multi-region | Document storage, analytics |
| **Analytics** | Apache Iceberg | Glue Catalog | Historical data, compliance archives |
| **Networking** | Transit Gateway, NLB, Route53 | Multi-region | Cross-account routing, DNS failover |
| **Security** | IAM, KMS, Secrets Manager | Pod Identity | Cross-account access, encryption |

### Application Stack

- **Primary Language**: Java 17 (Spring Boot 3.1+)
- **Secondary Language**: Python 3.11+ (FastAPI)
- **Container Registry**: CloudSmith (AA enterprise)
- **CI/CD**: GitHub Actions
- **IaC**: Terraform 1.6+

---

## 3. Data Domains (5 Domains, 24 Entities)

### Flight Domain (7 Entities)
- **Purpose**: Core operational truth of flight lifecycle
- **Entities**: FlightIdentity, FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning
- **Data Steward**: Flight Operations team
- **Message Flows**: 11 of 25 flows (44%)

### Aircraft Domain (5 Entities)
- **Purpose**: Authoritative master record of every aircraft
- **Entities**: AircraftIdentity, AircraftConfiguration, AircraftLocation, AircraftPerformance, AircraftMEL
- **Data Steward**: Fleet Management team
- **Message Flows**: 5 of 25 flows (20%)

### Station Domain (4 Entities)
- **Purpose**: Airports and airline stations
- **Entities**: StationIdentity, StationGeo, StationAuthorization, StationMetadata
- **Data Steward**: Network Planning team
- **Message Flows**: 5 of 25 flows (20%)

### Maintenance Domain (6 Entities)
- **Purpose**: Aircraft maintenance operations
- **Entities**: MaintenanceRecord, MaintenanceDMI, MaintenanceEquipment, MaintenanceLandingData, MaintenanceOTS, MaintenanceEventHistory
- **Data Steward**: Maintenance Operations team
- **Message Flows**: 3 of 25 flows (12%)

### ADL Domain (2 Entities)
- **Purpose**: FOS-derived operational snapshots
- **Entities**: adlHeader, adlFlights
- **Data Steward**: FOS Integration team
- **Message Flows**: 3 of 25 flows (12%)

---

## 4. Integration Patterns (7 Patterns)

| Pattern | Flows | Description |
|---------|-------|-------------|
| **1. Inbound Data Ingestion** | 10 (40%) | External → NXOP → On-Prem |
| **2. Outbound Data Publishing** | 2 (8%) | On-Prem → NXOP → External |
| **3. Bidirectional Sync** | 6 (24%) | Two-way synchronization |
| **4. Notification/Alert** | 3 (12%) | Event-driven notifications |
| **5. Document Assembly** | 1 (4%) | Multi-service document generation |
| **6. Authorization** | 2 (8%) | Electronic signature workflows |
| **7. Data Maintenance** | 1 (4%) | Reference data management |

---

## 5. Message Flows (25 Flows)

### Critical Flows (Examples)

| Flow | Name | Pattern | Source | Destination | Criticality |
|------|------|---------|--------|-------------|-------------|
| **1** | Publish FOS Event Data to Flightkeys | Outbound | FOS | Flightkeys | Vital |
| **2** | Receive and Publish Flight Plans | Inbound | Flightkeys | FOS | Vital |
| **5** | Receive and Publish Audit Logs, Weather | Inbound | Flightkeys | OpsHub | Critical |
| **7** | Flight Release Notifications | Notification | NXOP | Crew/Dispatch | Vital |
| **8** | Pilot Briefing Package Assembly | Document Assembly | Multiple | S3 | Critical |
| **9** | eSignature for Flight Release - CCI | Authorization | NXOP | CCI | Vital |
| **10** | eSignature for Flight Release - ACARS | Authorization | NXOP | ACARS | Vital |

### Flow Dependencies

- **MSK-Dependent**: 6 flows (24%)
- **DocumentDB-Dependent**: 5 flows (20%)
- **Cross-Account IAM-Dependent**: ALL 25 flows (100%)
- **Akamai GTM-Dependent**: API-dependent flows
- **Route53 DNS-Dependent**: MSK-dependent flows

---

## 6. Data Governance Framework

### Three-Tier Governance Model

#### Enterprise Level (Strategic)
- **Owner**: Enterprise Data Office (Todd Waller, CDO)
- **Scope**: Cross-airline canonical data models
- **Responsibilities**: Enterprise canonical models, MDM authority, cross-domain policies

#### NXOP Domain Level (Operational)
- **Owner**: NXOP Platform Team + Domain Data Stewards
- **Scope**: Real-time operational data models
- **Responsibilities**: 5 domain models (24 entities), technical schemas, integration patterns

#### Vendor Level (Integration)
- **Owner**: FOS Vendors + NXOP Integration Team
- **Scope**: Vendor-specific implementations
- **Responsibilities**: Vendor data models, integration compliance, source data quality

### Governance Bodies

1. **Joint Governance Council**: Strategic alignment (monthly)
2. **Platform Architecture Board**: Operational governance (bi-weekly)
3. **Vendor Integration Working Group**: Tactical execution (weekly)
4. **Domain Data Steward Meetings**: Domain-specific (monthly)

---

## 7. Security & Identity

### Pod Identity (Cross-Account IAM)

**Architecture**:
1. EKS pod assumes KPaaS account role (intermediate)
2. KPaaS role assumes NXOP account role (target) with conditions
3. Pod accesses NXOP resources with temporary credentials

**Trust Policy Conditions**:
- `kubernetes-namespace`: Restricts to specific namespace
- `kubernetes-service-account`: Restricts to specific service account
- `eks-cluster-arn`: Restricts to EKS clusters in KPaaS account

**Impact**: ALL 25 message flows depend on Pod Identity

---

## 8. Resilience & Disaster Recovery

### Multi-Region Failover (< 10 Min RTO)

**Phase 0 (Continuous)**: Health monitoring detects degradation

**Phase 1 (< 5 min)**:
- Route53 DNS updates kafka.nxop.com → us-west-2
- DocumentDB promotes us-west-2 to primary

**Phase 2 (< 3 min)**:
- Akamai GTM routes API traffic to us-west-2
- AMQP listeners reconnect to Flightkeys
- Kafka connectors reconnect to MSK

**Phase 3 (< 2 min)**: Validate all 25 flows operational in us-west-2

**Total RTO**: < 10 minutes  
**RPO**: 0 messages (Kafka persistence + replication)

### Resilience Strategies

| Component | Strategy | RTO | RPO |
|-----------|----------|-----|-----|
| **MSK** | Cross-region replication, Route53 DNS failover | < 10 min | 0 messages |
| **DocumentDB** | Global Cluster automatic failover | < 1 min | < 15 sec |
| **S3** | Multi-Region Access Point (MRAP) | Immediate | < 5 min |
| **EKS** | Active-standby, auto-reconnect | < 10 min | N/A |
| **Akamai GTM** | Health-based traffic routing | < 5 min | N/A |

---

## 9. Monitoring & Observability

### Key Metrics

**Platform Metrics**:
- Availability: Target 99.999%
- API Response Time (P95): Target < 500ms
- Message Processing Latency: Target < 2 seconds
- Schema Validation Pass Rate: Target > 99.9%

**Data Quality Metrics**:
- Validation Failure Rate: Target < 1%
- Data Completeness: Target > 99%
- Referential Integrity: Target 100%
- Schema Compliance: Target 100%

**Operational Metrics**:
- Message Flow Throughput: Messages per minute
- Consumer Lag: Target < 10,000 messages
- Error Rate: Target < 0.1% (vital flows)
- Incident Count: Target < 5 per month

### Monitoring Tools

- **CloudWatch**: Metrics, logs, alarms
- **CloudWatch Dashboards**: Platform, flow, data quality dashboards
- **PagerDuty**: Critical alerts and on-call rotation
- **Slack**: Warning alerts and notifications
- **Data Catalog**: Metadata discovery and lineage
- **Governance Portal**: Policy tracking and approvals

---

## 10. Migration Strategy

### Phased Migration (4 Phases)

**Phase 1: Dual Write (Weeks 1-4)**
- Write to both Azure FXIP and AWS NXOP
- Read from Azure FXIP (primary)
- Validate data consistency

**Phase 2: Dual Read (Weeks 5-8)**
- Write to both systems
- Read from AWS NXOP (primary), fallback to Azure FXIP
- Monitor read latency and error rates

**Phase 3: AWS Primary (Weeks 9-12)**
- Write to AWS NXOP (primary), Azure FXIP (backup)
- Read from AWS NXOP only
- Prepare for Azure FXIP decommission

**Phase 4: AWS Only (Week 13+)**
- Write to AWS NXOP only
- Decommission Azure FXIP
- Archive historical data from Azure to S3

---

## 11. Operational Procedures

### Change Management

**Schema Change Process**:
1. Developer proposes schema change in Git
2. CI/CD validates syntax, compatibility, naming conventions
3. Impact analysis identifies affected message flows
4. Data Steward reviews and approves
5. Merge triggers deployment to Schema Registry
6. Schema replicated to both regions

**Role Creation Process** (Pod Identity):
1. Application team submits request with resource requirements
2. NXOP security team reviews and approves permissions
3. KPaaS security team reviews and approves trust policy
4. NXOP team creates role via IaC
5. Application team adds annotation to KPaaS WebApp
6. Deployment tested in non-prod before prod

### Incident Response

**Severity Levels**:
- **P1 (Critical)**: Complete platform outage, vital flows down
- **P2 (High)**: Partial outage, critical flows degraded
- **P3 (Medium)**: Non-critical flows down, performance degraded
- **P4 (Low)**: Minor issues, no operational impact

**Response Times**:
- **P1**: Immediate response, 15-minute acknowledgment
- **P2**: 30-minute response, 1-hour acknowledgment
- **P3**: 2-hour response, 4-hour acknowledgment
- **P4**: Next business day response

---

## 12. Success Metrics

### Platform Performance

| Metric | Target | Current (FXIP) |
|--------|--------|----------------|
| **Availability** | 99.999% | 99.95% |
| **RTO (Regional Failover)** | < 10 minutes | 30+ minutes |
| **RPO (Data Loss)** | 0 messages | < 100 messages |
| **API Response Time (P95)** | < 500ms | < 1000ms |
| **Message Processing Latency** | < 2 seconds | < 5 seconds |
| **Cost Reduction** | 30% | Baseline |

### Data Governance

| Metric | Target |
|--------|--------|
| **Schema Validation Pass Rate** | > 99.9% |
| **Data Quality (Completeness)** | > 99% |
| **Policy Approval Time** | < 1 week (non-breaking) |
| **Schema Registration Time** | < 1 hour (automated) |
| **Data Catalog Coverage** | > 95% |
| **Validation Failure Rate** | < 1% |

---

## 13. Key Stakeholders

| Role | Name | Responsibility |
|------|------|----------------|
| **Application Owner** | Lakshmi Narayana Lanka | Overall NXOP platform ownership |
| **Architect** | Praveen Chand | Platform architecture and design |
| **Chief Data Officer** | Todd Waller | Enterprise data governance |
| **Operations Data Strategy** | Kevin | NXOP operational data governance |
| **Data Architecture** | Scott | Logical data model design |
| **Physical Design** | Prem | Physical schema implementation |
| **Platform Team** | NXOP Engineering | Implementation and operations |

---

## 14. Next Steps

### Immediate Actions (Next 30 Days)

1. **Governance Council Formation**: Establish Joint Governance Council with all stakeholders
2. **Schema Registry Setup**: Deploy Confluent Schema Registry in both regions
3. **Data Catalog Implementation**: Deploy and configure data catalog tool
4. **Pod Identity Rollout**: Create Pod Identity roles for all 21 microservices
5. **Monitoring Setup**: Deploy CloudWatch dashboards for all 25 message flows

### Short-Term Goals (Next 90 Days)

1. **Domain Model Finalization**: Complete logical data models for all 5 domains
2. **Schema Migration**: Migrate all Avro schemas to Schema Registry
3. **Integration Pattern Implementation**: Implement all 7 integration patterns
4. **Data Quality Framework**: Deploy automated data quality validation
5. **Governance Portal**: Launch governance portal for policy management

### Long-Term Goals (Next 12 Months)

1. **Complete Migration**: Migrate all 25 message flows from Azure FXIP to AWS NXOP
2. **Decommission FXIP**: Shut down Azure FXIP platform
3. **Optimize Performance**: Achieve all performance targets (99.999% availability, < 500ms API response)
4. **Cost Optimization**: Achieve 30% cost reduction vs. FXIP baseline
5. **Continuous Improvement**: Establish continuous improvement process for governance and operations

---

## 15. Conclusion

The NXOP platform represents a strategic transformation of American Airlines' flight operations infrastructure. By migrating from Azure FXIP to a cloud-native AWS architecture, NXOP will deliver:

- **Improved Resilience**: < 10 minute RTO for regional failover (vs. 30+ minutes)
- **Better Performance**: < 500ms API response time (vs. < 1000ms)
- **Zero Data Loss**: 0 message RPO (vs. < 100 messages)
- **Cost Savings**: 30% reduction in operational costs
- **Operational Excellence**: 99.999% availability target

The comprehensive data governance framework ensures that NXOP can evolve to meet future business needs while maintaining data quality, security, and compliance across all 25 message flows and 5 data domains.

---

**Document Status**: Complete  
**Last Updated**: February 2, 2026  
**Next Review**: March 2, 2026

