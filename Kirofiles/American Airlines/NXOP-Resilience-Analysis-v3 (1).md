# NXOP Resilience Analysis

## Executive Summary

This document provides a comprehensive resilience and disaster recovery analysis for the NXOP (Network Operations Platform) multi-region architecture. The analysis is built upon the foundation of the **[NXOP Message Flow Analysis](resilience/00-NXOP-Message-Flow-Analysis.md)**, which identified 25 distinct message flows across 7 primary integration patterns. This deep analysis of message flows, their dependencies, and integration patterns gave rise to this exhaustive resilience solution.

### Document Relationship

```
NXOP Message Flow Analysis (Foundation)
    ↓
    Identified: 25 flows, 7 primary patterns, critical dependencies
    ↓
NXOP Resilience Analysis (This Document)
    ↓
    Provides: Failure modes, recovery strategies, orchestration
```

**Prerequisites**: Before reading this document, familiarize yourself with the [NXOP Message Flow Analysis](resilience/00-NXOP-Message-Flow-Analysis.md) to understand:
- The 25 message flows and their purposes
- The 7 primary integration patterns
- Source-to-destination patterns
- NXOP platform dependencies (MSK, DocumentDB, S3)
- Multi-cloud architecture (AWS + Azure)

### NXOP Platform Scope

**Important**: Of the 25 total message flows:
- **19 flows (76%)** have active NXOP Platform involvement (AWS EKS services)
- **6 flows (24%)** have NO NXOP involvement: Flows 11, 12, 13, 15, 21, 25
  - These flows are handled by FXIP (Azure) and on-premises components
  - Resilience strategies in this document apply only to NXOP-active flows

**NXOP-Active Flows**: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 16, 17, 18, 19, 20, 22, 23, 24

### Key Findings

**Failure Mode Coverage**:
- **Component-Level Failures**: 32 infrastructure failure modes (EKS, MSK, DocumentDB, S3, Network, Replication, DR Orchestration)
- **Application-Level Failures**: 23 functionality failure modes (Data Ingestion, Processing, Auth, Distribution, Cascading)
- **Total**: 55 distinct failure modes analyzed

**Recovery Strategy Distribution**:
- **HA - Automated**: 15 failure modes (Rapid recovery in-Region) - 27%
- **Regional Switchover**: 8 failure modes (Recovery across Region) - 15%
- **Manual Intervention**: 12 failure modes (Higher recovery time) - 22%
- **Cascading/Complex**: 20 failure modes (varies) - 36%

**Message Flow Impact**:
- **HA - Automated**: 13 flows (68% of NXOP-active flows) - Most NXOP flows have automated recovery
- **Regional Switchover**: 6 flows (32% of NXOP-active flows) - Flows requiring cross-region failover
- **No NXOP Involvement**: 6 flows (24% of total) - Flows 11, 12, 13, 15, 21, 25 (handled by FXIP/On-Prem)

**Note**: Recovery strategies only apply to the 19 NXOP-active flows. The 6 non-NXOP flows are managed by FXIP (Azure) and on-premises components with separate resilience mechanisms.

**Critical Dependencies** (from Message Flow Analysis):
- **MSK-Dependent Flows**: 6 flows (24% of total, 32% of NXOP-active flows) - Flows 1, 2, 5, 10, 18, 19
  - All 6 MSK flows have active NXOP involvement
  - MSK provides event streaming backbone for high-volume, asynchronous data flows
  - Cross-region replication via MSK Replicator (bi-directional)
- **DocumentDB-Dependent Flows**: 5 flows (20% of total, 26% of NXOP-active flows) - Flows 1, 8, 10, 18, 19
  - **Critical Dependency**: Flow 8 (Pilot Briefing Package) - Cannot assemble packages without DocumentDB
  - **High Dependency**: Flow 10 (eSignature) - Cannot validate signatures without DocumentDB
  - **Medium Dependency**: Flows 1, 18, 19 - Degraded enrichment without DocumentDB (events can still flow)
  - **Global Cluster**: Primary (us-east-1), Secondary (us-west-2) with automatic failover (< 1 minute)
- **Flightkeys Dependency**: 16 flows total (64%), 15 NXOP-active flows (79% of NXOP-active)
  - Flow 12 (Flight Plans to CyberJet): Flightkeys → FXIP Azure → CyberJet (no NXOP involvement)
- **Akamai GTM**: Fronts inbound HTTPS API endpoints (not AMQP traffic)
  - **Flows with HTTPS ingestion** (via Akamai): 1, 8, 16, 17, 18, 19, 20, 22, 23, 24
  - **Flows with AMQP ingestion** (bypass Akamai): 2, 3, 4, 5, 6, 7, 9, 10, 14, 20
  - **Outbound calls**: All EKS → external system calls bypass Akamai (direct HTTPS)

---

## Quick Reference

### Recovery Strategy by Integration Pattern

| Pattern | Description | Flow Count | NXOP-Active | Primary Recovery | Secondary Recovery | RTO Target |
|---------|-------------|------------|-------------|------------------|-------------------|------------|
| **Inbound Data Ingestion** | External systems → NXOP via HTTPS/AMQP | 10 flows | 8 flows | HA Automated | Regional Switchover | < 5 min |
| **Outbound Data Publishing** | On-Prem → NXOP → External systems via HTTPS | 4 flows | 4 flows | HA Automated | Regional Switchover | < 5 min |
| **Bidirectional Sync** | NXOP ↔ External systems (request/response) | 4 flows | 4 flows | HA Automated | Manual Intervention | < 5 min |
| **Notification/Alert** | NXOP → External systems (event-driven) | 3 flows | 3 flows | HA Automated | Regional Switchover | < 5 min |
| **Document Assembly** | NXOP generates documents from multiple sources | 1 flow | 1 flow | HA Automated | Manual Intervention | < 5 min |
| **Authorization** | NXOP validates signatures and permissions | 2 flows | 2 flows | Manual Intervention | N/A | 15+ min |

**Note**: 
- **NXOP-Active**: Flows where NXOP Platform (AWS EKS) actively processes messages
- **Non-NXOP flows** (11, 12, 13, 15, 21, 25): Handled by FXIP (Azure) and on-premises components
- Recovery strategies apply only to NXOP-active flows
- **Flows 23, 24**: Outbound publishing (On-Prem → NXOP → Flightkeys), not bidirectional

### Recovery Decision Matrix

| Question | Example | Yes → | No → |
|----------|---------|-------|------|
| **Is the failure isolated to a single component/service?** | Single EKS pod crash, one MSK broker down | Consider HA - Automated | Continue to next question |
| **Are health checks and monitoring providing clear signals?** | CloudWatch alarms firing, health checks failing | HA - Automated | Manual Intervention |
| **Is the entire regional infrastructure affected?** | AWS region outage, complete AZ failure | Regional Switchover | Continue to next question |
| **Is there potential for data corruption or security compromise?** | Unauthorized access detected, data integrity issues | Manual Intervention | HA - Automated |
| **Can the failure be resolved by scaling/restarting services?** | High CPU/memory, pod restart resolves issue | HA - Automated | Manual Intervention |
| **Is cross-region failover the appropriate response?** | Regional MSK cluster failure, DocumentDB primary down | Regional Switchover | Manual Intervention |

### Critical Infrastructure Dependencies

| Infrastructure | Dependent Flows | NXOP-Active | Failure Impact | Recovery Type | Recovery Speed |
|----------------|----------------|-------------|----------------|---------------|----------------|
| **Akamai GTM** | 10 flows (inbound HTTPS) | 10 flows | HIGH - Inbound API routing fails | Regional Switchover | Fast |
| **MSK Cluster** | 6 flows (24%) | 6 flows | HIGH - Event streaming stops | Regional Switchover | Fast |
| **DocumentDB** | 5 flows (20%) | 5 flows | MEDIUM-CRITICAL - Data access degraded | HA Automated | Very Fast |
| **Route53 DNS** | 6 MSK flows | 6 flows | HIGH - MSK bootstrap fails | Regional Switchover | Fast |
| **Flightkeys** | 16 flows (64%) | 15 flows | CRITICAL - Primary data source | Vendor-managed | Varies |
| **S3 MRAP** | 1 flow (4%) | 1 flow | MEDIUM - Document storage | HA Automated | Very Fast |

**Notes**:
- **Akamai GTM**: Only fronts inbound HTTPS APIs (not AMQP traffic). Flows with HTTPS ingestion: 1, 8, 16, 17, 18, 19, 20, 22, 23, 24. Flows with AMQP ingestion bypass Akamai: 2, 3, 4, 5, 6, 7, 9, 10, 14, 20.
- **Route53 DNS**: MSK bootstrap only (kafka.nxop.com). After bootstrap, clients connect directly to MSK brokers.
- **DocumentDB**: Flow 8 is CRITICAL (cannot assemble briefing packages), Flow 10 is HIGH (cannot validate signatures), Flows 1, 18, 19 are MEDIUM (degraded enrichment acceptable).
- **S3**: Bi-directional cross-region replication (us-east-1 ↔ us-west-2) with S3 MRAP for automatic regional routing.

---

## Detailed Documentation

### Architecture and Design

#### [01. Architecture Overview](resilience/01-Architecture-Overview.md)
**Purpose**: Understand the complete NXOP multi-region architecture  
**Contents**:
- Multi-region architecture diagram (AWS East/West + Azure)
- Integration patterns and data flows
- ARC control states and traffic routing
- Cross-account IAM architecture

**Key Insights**:
- Akamai GTM routes external API traffic
- Route53 DNS routes internal MSK traffic
- ARC orchestrates MSK, Akamai, and DocumentDB failover
- Pod Identity enables cross-account access

**Audience**: Architects, new team members, leadership

---

#### [02. Integration Pattern Resilience](resilience/02-Integration-Pattern-Resilience.md)
**Purpose**: Understand how each of the 7 primary integration patterns handles failures  
**Contents**:
- Pattern-specific failure modes and recovery strategies
- Pattern variations and unique characteristics
- RTO targets and recovery mechanisms
- Pattern-level recommendations

**Key Insights**:
- Event-Driven pattern (Inbound Data Ingestion - 10 flows) relies on AMQP and HTTPS
- Authorization pattern (2 flows) requires manual intervention for compliance
- 6 flows have no NXOP involvement (handled by FXIP/On-Prem only)

**Audience**: Application developers, integration engineers

---

### Infrastructure and Operations

#### [03. Infrastructure Failures](resilience/03-Infrastructure-Failures.md)
**Purpose**: Comprehensive catalog of infrastructure failure modes  
**Contents**:
- Component failures (EKS, MSK, DocumentDB, S3)
- Network infrastructure failures (NLB, VPC, DNS)
- Data replication failures
- DR orchestration failures
- Application/functionality failures
- Cascading and multi-component failures

**Key Insights**:
- 32 component-level failure modes
- 23 application-level failure modes
- Chaos testing experiments for each failure mode

**Audience**: Infrastructure engineers, SREs, operations teams

---

#### [04. CloudWatch Metrics Strategy](resilience/04-CloudWatch-Metrics.md)
**Purpose**: Complete monitoring and alerting strategy  
**Contents**:
- Component-level metrics (EKS, MSK, DocumentDB, S3, Network)
- Application-level metrics (Four Golden Signals)
- Cross-account IAM metrics
- Composite alarm structure
- Health canary metrics

**Key Insights**:
- Hundreds of metrics organized by component
- Thresholds and alerting criteria
- Scope (Regional/Zonal/Global) for each metric

**Audience**: SREs, monitoring engineers, operations

---

### Disaster Recovery

#### [05. Region Readiness Assessment](resilience/05-Region-Readiness-Assessment.md)
**Purpose**: Validate target region health before failover  
**Contents**:
- Hierarchical health check framework (L1-L4)
- Composite scoring methodology
- Readiness thresholds and decision criteria
- CloudWatch implementation details

**Key Insights**:
- 4-layer health check hierarchy
- 90%+ score required for safe failover
- Different metrics for active vs standby regions

**Audience**: SREs, operations, DR coordinators

---

#### [06. Region Switch Orchestration](resilience/06-Region-Switch-Orchestration.md)
**Purpose**: Step-by-step regional failover procedures  
**Contents**:
- Continuous pre-failover validation (Phase 0)
- Concurrent infrastructure isolation (Phase 1: MSK + DocumentDB)
- Concurrent application failover (Phase 2: Akamai GTM + AMQP listeners)
- Post-failover validation (Phase 3: L1-L4 health checks)
- Rollback procedures

**Key Insights**:
- Phase 0 runs continuously, eliminating pre-flight checks
- Phase 1 and Phase 2 execute concurrently for speed
- < 10 minute total failover time
- Automated rollback on failure
- AMQP listeners and connectors auto-reconnect

**Audience**: Operations, DR coordinators, incident commanders

---

### Application Impact

#### [07. Message Flow Recovery Mapping](resilience/07-Message-Flow-Recovery-Mapping.md)
**Purpose**: Map all 25 message flows to recovery strategies  
**Contents**:
- Flow-to-failure mode mapping
- Recovery characteristics by flow type
- Cascading failure prevention
- Dependency impact analysis

**Key Insights**:
- 13 NXOP-active flows (68%) have HA automated recovery
- 6 NXOP-active flows (32%) require regional switchover
- 6 flows (24% of total) have no NXOP involvement (handled by FXIP/On-Prem)

**Audience**: Application teams, product owners, business stakeholders

---

## How to Use This Documentation

### For New Team Members
1. Start with [NXOP Message Flow Analysis](resilience/00-NXOP-Message-Flow-Analysis.md) to understand the flows
2. Read [Architecture Overview](resilience/01-Architecture-Overview.md) to understand the system
3. Review [Integration Pattern Resilience](resilience/02-Integration-Pattern-Resilience.md) for your patterns

### For Incident Response
1. Check [Recovery Decision Matrix](#recovery-decision-matrix) to determine recovery type
2. Consult [Infrastructure Failures](resilience/03-Infrastructure-Failures.md) for specific failure modes
3. Follow [Region Switch Orchestration](resilience/06-Region-Switch-Orchestration.md) if regional failover needed

### For DR Planning
1. Review [Region Readiness Assessment](resilience/05-Region-Readiness-Assessment.md) for validation criteria
2. Study [Region Switch Orchestration](resilience/06-Region-Switch-Orchestration.md) for procedures
3. Use [Message Flow Recovery Mapping](resilience/07-Message-Flow-Recovery-Mapping.md) for business impact

### For Monitoring Setup
1. Implement metrics from [CloudWatch Metrics Strategy](resilience/04-CloudWatch-Metrics.md)
2. Create composite alarms per [Region Readiness Assessment](resilience/05-Region-Readiness-Assessment.md)
3. Set up health canaries for MSK and application endpoints

### For Chaos Engineering
1. Use failure modes from [Infrastructure Failures](resilience/03-Infrastructure-Failures.md)
2. Design experiments based on chaos testing recommendations
3. Validate recovery procedures match documented RTO targets

---

## Conclusion

This resilience analysis provides a comprehensive framework for understanding and responding to failures across the NXOP platform. The analysis is grounded in the **[NXOP Message Flow Analysis](resilience/00-NXOP-Message-Flow-Analysis.md)**, which identified the 25 message flows, 7 primary integration patterns, and critical dependencies that form the foundation of this resilience strategy.

### Key Takeaways

1. **Deep Analysis Drives Comprehensive Solutions**: The exhaustive analysis of message flows, integration patterns, and dependencies in the Message Flow Analysis document enabled this detailed resilience strategy covering 55 distinct failure modes.

2. **Most Flows Are Highly Resilient**: 68% of NXOP-active flows have automated recovery with < 5 min RTO, demonstrating strong architectural resilience.

3. **Akamai GTM Role**: Fronts inbound HTTPS API endpoints for 10 NXOP flows. AMQP traffic from Flightkeys bypasses Akamai and goes directly to EKS pods. All outbound HTTPS calls from EKS apps to external systems are direct (not through Akamai).

4. **Regional Switchover Is Fast and Automated**: 6 flows require regional failover, with automated procedures and < 10 min RTO through continuous readiness monitoring and concurrent execution.

5. **Authorization Flows Require Special Handling**: eSignature flows (9, 10) require manual intervention due to compliance requirements.

6. **NXOP Scope**: 19 of 25 flows (76%) are actively managed by NXOP Platform; 6 flows (24%) are handled by FXIP/On-Prem only.

### Continuous Improvement

This documentation should be:
- **Updated** when new flows are added or patterns change
- **Validated** through regular DR drills and chaos engineering
- **Enhanced** based on actual incident learnings
- **Reviewed** quarterly for accuracy and completeness

### Related Documentation

- **[NXOP Message Flow Analysis](resilience/00-NXOP-Message-Flow-Analysis.md)** - Foundation document analyzing all 25 flows
- **[Architecture Overview](resilience/01-Architecture-Overview.md)** - Detailed architecture diagrams and patterns
- **[Region Switch Orchestration](resilience/06-Region-Switch-Orchestration.md)** - DR procedures and runbooks

---

**Document Maintained By**: NXOP Platform Team  
**Last Updated**: 2026-01-20  
**Review Frequency**: Quarterly
