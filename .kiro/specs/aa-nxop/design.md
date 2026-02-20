# Design Document: AA NXOP Data Model Governance

## Executive Summary

This design document provides a comprehensive blueprint for establishing data governance across American Airlines' Next Generation Operations Platform (NXOP). The document is structured to be accessible to both technical and non-technical stakeholders, including executives, architects, developers, operations teams, and business stakeholders.

**What This Document Covers**:
- How NXOP manages data across multiple cloud platforms (AWS, Azure, On-Premises)
- Governance structures and decision-making processes
- Technical architecture and infrastructure components
- Data quality, security, and compliance frameworks
- Implementation roadmap and risk management

**Who Should Read This Document**:
- **Executives**: Focus on Executive Summary, Strategic Context, Risk Management, and Implementation Roadmap
- **Architects**: Focus on Architecture, Components, and Design Principles
- **Developers**: Focus on Components, Schema Management, Testing Strategy, and Error Handling
- **Operations**: Focus on Multi-Region Resilience, Monitoring, and Error Handling
- **Data Stewards**: Focus on Data Domain Models, Data Quality Framework, and Governance Council

## Overview

The AA NXOP Data Model Governance initiative establishes a comprehensive framework for managing data structures, schemas, and metadata across American Airlines' Next Generation Operations Platform. This design addresses the strategic challenge of governing data across a complex multi-cloud architecture (AWS, Azure, On-Premises) while supporting 25 message flows, 7 integration patterns, and 5 core data domains.

**Why Data Governance Matters for NXOP**:
- **Operational Excellence**: Ensures flight operations data is accurate, timely, and consistent across all systems
- **Regulatory Compliance**: Maintains audit trails and data quality standards required by FAA and other regulatory bodies
- **Business Agility**: Enables rapid integration of new vendor solutions (FOS) without disrupting existing operations
- **Cost Optimization**: Prevents data duplication and reduces integration complexity through standardized patterns
- **Risk Mitigation**: Reduces operational risks from data inconsistencies that could impact flight safety and operations

### Strategic Context

NXOP operates as a multi-region, event-driven architecture designed to support American Airlines' critical flight operations in real-time. Understanding the strategic context is essential for appreciating the complexity and importance of this data governance initiative.

#### Multi-Cloud Architecture Overview

**AWS NXOP Platform (Primary Operational Platform)**:
- **Regions**: us-east-1 (N. Virginia - Primary), us-west-2 (Oregon - Secondary)
- **Purpose**: Real-time flight operations, event processing, operational data storage
- **Why Multi-Region**: 
  - Disaster recovery with < 10 minute RTO (Recovery Time Objective)
  - Geographic redundancy for critical flight operations
  - Load distribution during peak operational periods
  - Compliance with data residency requirements

**Azure FXIP Platform (Flight Planning and Crew Integration)**:
- **Purpose**: Flight planning calculations, crew scheduling integration, legacy system bridge
- **Key Components**: Flightkeys Event Processors, ConsulDB (reference data), OpsHub Event Hubs
- **Integration Point**: Connects to NXOP via AMQP (Advanced Message Queuing Protocol) and HTTPS APIs
- **Why Azure**: Legacy investment, existing crew management systems, gradual migration strategy

**On-Premises FOS (Future of Operations Solutions)**:
- **Purpose**: Legacy flight operations systems, vendor solution integrations
- **Key Systems**: 
  - DECS (Dispatch Environmental Control System)
  - Load Planning (cargo and passenger weight distribution)
  - Takeoff Performance (runway calculations)
  - Crew Management (crew assignments and scheduling)
- **Integration Point**: MQ-Kafka adapters bridge on-premises MQ to NXOP MSK
- **Why On-Premises**: Regulatory requirements, vendor constraints, gradual cloud migration

#### Technology Stack Deep Dive

**Compute Layer - EKS in KPaaS**:
- **What**: Kubernetes clusters managed by American Airlines' internal KPaaS (Kubernetes Platform as a Service) team
- **Why Separate Accounts**: 
  - KPaaS manages infrastructure (nodes, networking, monitoring)
  - NXOP teams manage applications (pods, services, deployments)
  - Clear separation of concerns and responsibilities
- **Account Structure**:
  - KPaaS NonProd: 285282426848 (development, testing, staging environments)
  - KPaaS Prod: 045755618773 (production flight operations)
- **Pod Identity**: Enables EKS pods to assume IAM roles in NXOP account without static credentials
  - Security benefit: No long-lived credentials stored in pods
  - Operational benefit: Automatic credential rotation
  - Compliance benefit: Full audit trail of all access

**Storage Layer - Multi-Technology Approach**:

*DocumentDB Global Clusters (Operational Data)*:
- **What**: MongoDB-compatible database service with multi-region replication
- **Why DocumentDB**: 
  - Flexible schema for evolving operational data structures
  - High write throughput for real-time flight events (10,000+ writes/sec)
  - Complex nested documents match operational data patterns (flight events with embedded metadata)
  - Global Cluster provides automatic failover (< 1 minute RTO)
- **Data Stored**: 
  - Flight operational data (24 collections across 5 domains)
  - Aircraft configurations and status
  - Station (airport) information
  - Maintenance records
  - ADL (FOS-derived) snapshots
- **Access Patterns**:
  - Read-heavy for reference data (aircraft configs, station data)
  - Write-heavy for event data (flight events, position updates)
  - Mixed for operational data (flight times, aircraft location)

*S3 + Apache Iceberg (Analytics Data)*:
- **What**: Object storage with Iceberg table format for analytics workloads
- **Why Iceberg**: 
  - ACID transactions on S3 data
  - Time travel queries for historical analysis
  - Schema evolution without rewriting data
  - Efficient partition pruning for large datasets
- **Data Stored**:
  - Historical flight data (years of operational history)
  - Analytics aggregations (OTP metrics, fuel efficiency)
  - Compliance archives (7-year retention for FAA)
- **Access Patterns**:
  - Batch reads for analytics (Databricks, Orion)
  - Append-only writes from operational systems
  - Time-series queries for trend analysis

**Streaming Layer - MSK/Kafka**:
- **What**: Managed Kafka service for event streaming
- **Why Kafka**: 
  - High throughput (millions of events per day)
  - Durable message storage (3-day to 72-hour retention)
  - Decouples producers from consumers
  - Enables event replay for debugging and recovery
- **Cross-Region Replication**:
  - Bidirectional replication between us-east-1 and us-west-2
  - Replication lag < 1 second (target)
  - Automatic failover via Route53 DNS
- **Topics**: 50+ Kafka topics organized by domain and carrier
  - Flight events: flight-event-aa-*, flight-event-mq-*, flight-event-te-*
  - Aircraft events: aircraft-snapshot-*, aircraft-update-*
  - Station events: airport-event-*, airport-update-*
  - Maintenance events: internal-maintenanceevents-avro
  - ADL data: adl-data
- **Avro Schemas**: 
  - Enforced via Confluent Schema Registry
  - Backward compatibility ensures consumers don't break
  - Schema evolution tracked with version numbers

**API Layer - GraphQL with Apollo Federation**:
- **What**: Unified API layer aggregating data from multiple sources
- **Why GraphQL**: 
  - Clients request only needed data (reduces bandwidth)
  - Single endpoint for multiple data sources
  - Strong typing with schema validation
  - Real-time subscriptions for live updates
- **Apollo Federation**: 
  - Each domain (Flight, Aircraft, Station, Maintenance, ADL) has its own subgraph
  - Gateway composes subgraphs into unified schema
  - Enables independent deployment of domain services
- **Akamai GTM (Global Traffic Manager)**:
  - Routes external API traffic to healthy region
  - Health-based routing (monitors endpoint availability)
  - Geographic routing (routes to nearest region)
  - DDoS protection and rate limiting

#### Integration Complexity

**25 Message Flows**:
- **What**: Distinct data exchange pathways between systems
- **Why 25**: Each flow represents a specific business process (flight planning, crew assignment, maintenance tracking, etc.)
- **Examples**:
  - Flow 1: FOS events → NXOP → Flightkeys (outbound publishing)
  - Flow 2: Flightkeys flight plans → NXOP → FOS (inbound ingestion)
  - Flow 8: Pilot briefing package assembly (document assembly)
  - Flow 10: Pilot eSignature via ACARS (authorization workflow)

**7 Integration Patterns**:
- **What**: Standardized approaches for data exchange
- **Why Patterns**: Reduces complexity, enables reuse, simplifies governance
- **Patterns**:
  1. **Inbound Data Ingestion** (10 flows): External → NXOP → On-Prem
  2. **Outbound Data Publishing** (2 flows): On-Prem → NXOP → External
  3. **Bidirectional Sync** (6 flows): Two-way synchronization
  4. **Notification/Alert** (3 flows): Event-driven notifications
  5. **Document Assembly** (1 flow): Multi-service document generation
  6. **Authorization** (2 flows): Electronic signature workflows
  7. **Data Maintenance** (1 flow): Reference data management

**5 Data Domains with 24 Entities**:
- **What**: Bounded contexts of related data following Domain-Driven Design (DDD) principles
- **Why Domains**: 
  - Clear ownership (Operations owns business logic, IT owns implementation)
  - Independent evolution (changes in one domain don't break others)
  - Scalability (domains can scale independently)
- **Domains**:
  1. **Flight Domain** (7 entities): FlightIdentity, FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning
  2. **Aircraft Domain** (5 entities): AircraftIdentity, AircraftConfiguration, AircraftLocation, AircraftPerformance, AircraftMEL
  3. **Station Domain** (4 entities): StationIdentity, StationGeo, StationAuthorization, StationMetadata
  4. **Maintenance Domain** (6 entities): MaintenanceRecord, MaintenanceDMI, MaintenanceEquipment, MaintenanceLandingData, MaintenanceOTS, MaintenanceEventHistory
  5. **ADL Domain** (2 entities): adlHeader, adlFlights

#### Cross-Account Access Pattern (Pod Identity)

**The Challenge**:
- EKS pods run in KPaaS account (285282426848 or 045755618773)
- NXOP resources (DocumentDB, MSK, S3) are in separate NXOP account
- Traditional approach: Store AWS credentials in pods (security risk)

**The Solution - Pod Identity**:
- **Step 1**: Pod assumes KPaaS account role (intermediate role)
- **Step 2**: KPaaS role assumes NXOP account role (target role)
- **Step 3**: Pod accesses NXOP resources with temporary credentials
- **Benefits**:
  - No static credentials stored in pods
  - Automatic credential rotation (credentials expire after 1 hour)
  - Full audit trail (CloudTrail logs all AssumeRole calls)
  - Least-privilege access (each pod gets only needed permissions)

**Trust Policy Example**:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "arn:aws:iam::285282426848:root"},
    "Action": ["sts:AssumeRole", "sts:TagSession"],
    "Condition": {
      "StringEquals": {
        "aws:RequestTag/kubernetes-namespace": "nxop-prod",
        "aws:RequestTag/kubernetes-service-account": "flight-data-adapter-sa"
      }
    }
  }]
}
```

**Why This Matters**:
- ALL 25 message flows depend on Pod Identity
- If Pod Identity fails, entire NXOP platform stops
- Critical single point of failure requiring robust monitoring

#### Network Integration

**Transit Gateway (TGW)**:
- **What**: AWS service connecting multiple VPCs
- **Why**: Enables KPaaS VPC to communicate with NXOP VPC
- **Routing**: 
  - KPaaS pods → TGW → NXOP VPC → DocumentDB/MSK
  - Eliminates need for VPC peering (simpler management)
  - Centralized routing policies

**Route53 DNS**:
- **What**: AWS DNS service
- **Purpose**: Routes MSK bootstrap connections
- **DNS Name**: kafka.nxop.com
- **Routing Policy**: Health-based failover
  - Primary: nxop-msk-nlb-east.internal (us-east-1)
  - Secondary: nxop-msk-nlb-west.internal (us-west-2)
- **TTL**: 60 seconds (fast failover)

#### Governance Framework Requirements

**Data Convergence for Decision-Making**:
- **Example**: Crew planning (Enterprise) + crew operations (NXOP)
- **Challenge**: Two systems with different data models
- **Solution**: Semantic mapping layer translates between models
- **Benefit**: Enables integrated decision-making without forcing single model

**Parallel Data Structure Operation (18+ Month Transitions)**:
- **Why**: Legacy systems can't be migrated overnight
- **Approach**: Run old and new data structures in parallel
- **Example**: 
  - Month 1-6: Legacy FOS model + new NXOP model (dual-write)
  - Month 7-12: Gradual consumer migration to NXOP model
  - Month 13-18: Legacy model sunset, NXOP model primary
- **Governance**: Ensure data consistency between parallel structures

**FOS Vendor Integration**:
- **Challenge**: Multiple vendors with different data models
- **Solution**: 
  - ADL Domain preserves FOS-specific metadata
  - Transformation layer maps FOS models to NXOP models
  - Integration templates standardize vendor onboarding
- **Phases**:
  - Phase 1 (Months 1-9): Foundation vendors
  - Phase 2 (Months 10-15): Extended vendors
  - Phase 3 (Months 16-18+): Future vendors

**Enterprise Data Alignment (Todd Waller's Canonical Models)**:
- **Challenge**: NXOP operational models vs. Enterprise analytical models
- **Solution**: 
  - Joint ownership of shared domains (Crew, Network)
  - Semantic mappings for model differences
  - Governance Council with Enterprise representation
- **Benefit**: Consistent data across operational and analytical systems

**Multi-Region Resilience (< 10 Min RTO)**:
- **Challenge**: Regional failures must not disrupt flight operations
- **Solution**: 
  - Continuous health monitoring (Phase 0)
  - Concurrent failover execution (Phase 1 + Phase 2)
  - Automatic rollback on failure
- **Components**:
  - MSK: Route53 DNS failover
  - DocumentDB: Automatic promotion of secondary
  - Akamai GTM: Health-based traffic routing
  - Applications: Auto-reconnect to new region

**Cross-Account IAM Governance**:
- **Challenge**: 100+ Pod Identity roles across multiple teams
- **Solution**: 
  - Standardized trust policy templates
  - Approval workflow (KPaaS + NXOP security teams)
  - Automated impact analysis (affects all 25 flows)
  - Monitoring and alerting for auth failures

### Design Principles

These principles guide all design decisions and trade-offs in the NXOP data governance framework. Each principle includes rationale and practical implications.

#### 1. Multi-Cloud First

**Principle**: Governance policies apply uniformly across AWS, Azure, and On-Premises environments.

**Rationale**:
- American Airlines operates across multiple cloud platforms due to legacy investments and strategic partnerships
- Inconsistent governance across clouds creates data silos and integration complexity
- Uniform policies reduce cognitive load for developers and operators

**Practical Implications**:
- Schema validation rules work identically in AWS MSK (Avro), Azure Event Hubs, and On-Prem MQ
- Data quality checks apply regardless of storage technology (DocumentDB, ConsulDB, FOS databases)
- Monitoring and alerting use consistent metrics across all platforms

**Example**:
- A flight event schema must be valid whether it's:
  - Produced to AWS MSK from on-premises MQ-Kafka adapter
  - Consumed by Azure FXIP Event Processor
  - Stored in DocumentDB for operational queries
  - Archived to S3 for compliance

#### 2. Message Flow Centric

**Principle**: All governance decisions consider impact on 25 message flows.

**Rationale**:
- Message flows represent actual business processes (flight planning, crew assignment, maintenance tracking)
- Changes that break message flows directly impact flight operations
- Flow-centric thinking prevents "ivory tower" governance disconnected from reality

**Practical Implications**:
- Schema changes require impact analysis: "Which of the 25 flows does this affect?"
- Infrastructure changes require flow validation: "Do all flows still work after this change?"
- Performance optimization targets specific flows: "Flow 2 (flight plans) has 1000+ msg/min, needs optimization"

**Example**:
- Proposed schema change to FlightEvent entity
- Impact analysis identifies: Flows 1, 2, 4, 5, 7, 10, 14 affected (7 of 25 flows)
- Governance Council reviews impact on each flow
- Approval requires validation that all 7 flows continue working

#### 3. Domain-Driven Design

**Principle**: 5 data domains with clear boundaries and entity relationships.

**Rationale**:
- Complex systems need clear boundaries to manage complexity
- Domain boundaries align with organizational structure (Flight Ops, Fleet Management, Network Planning, Maintenance, FOS Integration)
- Independent evolution: Changes in Flight domain don't break Aircraft domain

**Practical Implications**:
- Each domain has a Data Steward (business owner)
- Each domain has independent schema evolution
- Cross-domain relationships are explicit and governed (Flight.tailNumber → Aircraft.noseNumber)

**Example - Flight Domain Boundary**:
- **Inside Boundary**: FlightIdentity, FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning
- **Outside Boundary**: Aircraft data (separate domain), Station data (separate domain)
- **Cross-Domain Reference**: Flight.tailNumber references Aircraft.noseNumber (referential integrity enforced)

#### 4. Event-Driven Architecture

**Principle**: All data changes flow through MSK with schema validation.

**Rationale**:
- Event-driven architecture decouples producers from consumers
- Events provide audit trail (who changed what, when)
- Events enable replay for debugging and recovery
- Schema validation at produce time prevents bad data from entering system

**Practical Implications**:
- All operational data changes produce events to MSK
- Consumers subscribe to relevant topics (loose coupling)
- Schema Registry enforces Avro schema validation
- Event replay enables time-travel debugging

**Example - Flight Time Update**:
1. FOS updates flight departure time
2. MQ-Kafka adapter produces event to `flight-event-aa-time-avro` topic
3. Schema Registry validates event against Avro schema
4. Multiple consumers process event:
   - Flight Data Adapter updates DocumentDB
   - Analytics pipeline updates Iceberg tables
   - Notification Service sends alerts to crew
5. All changes tracked in event log (audit trail)

#### 5. Cross-Account Security

**Principle**: Pod Identity enables secure, credential-free access.

**Rationale**:
- Static credentials in pods are security risk (can be extracted, don't rotate)
- Pod Identity uses temporary credentials (expire after 1 hour)
- Full audit trail (CloudTrail logs all AssumeRole calls)
- Least-privilege access (each pod gets only needed permissions)

**Practical Implications**:
- No AWS credentials stored in pod environment variables or config files
- Automatic credential rotation (no manual rotation required)
- Fine-grained access control (namespace + service account + cluster conditions)
- Monitoring for authentication failures (AssumeRole denials)

**Example - Flight Data Adapter Access**:
1. Pod starts with service account `flight-data-adapter-sa`
2. Pod assumes KPaaS account role (intermediate)
3. KPaaS role assumes NXOP account role (target) with conditions:
   - kubernetes-namespace: nxop-prod
   - kubernetes-service-account: flight-data-adapter-sa
   - eks-cluster-arn: arn:aws:eks:*:285282426848:cluster/*
4. Pod receives temporary credentials (valid 1 hour)
5. Pod accesses DocumentDB, MSK, S3 with temporary credentials
6. All access logged to CloudTrail for audit

#### 6. Multi-Region Consistency

**Principle**: Data governance policies apply uniformly across regions.

**Rationale**:
- NXOP operates in us-east-1 (primary) and us-west-2 (secondary)
- Regional failover must be seamless (< 10 min RTO)
- Inconsistent policies across regions create failover risks

**Practical Implications**:
- Schema versions synchronized across regions
- Data quality rules identical in both regions
- Monitoring and alerting consistent across regions
- Failover procedures tested regularly

**Example - Schema Deployment**:
1. Developer proposes schema change in us-east-1
2. CI/CD pipeline validates schema
3. Schema deployed to Confluent Schema Registry in us-east-1
4. Schema automatically replicated to us-west-2
5. Both regions enforce same schema version
6. Failover to us-west-2 uses same schema (no compatibility issues)

#### 7. Backward Compatibility

**Principle**: Schema evolution maintains compatibility unless explicitly versioned.

**Rationale**:
- Breaking changes force all consumers to update simultaneously (coordination nightmare)
- Backward compatibility enables gradual consumer migration
- Explicit versioning signals breaking change (new topic, new collection)

**Practical Implications**:
- Confluent Schema Registry enforces backward compatibility mode
- Allowed changes: Add optional fields, remove optional fields, widen types
- Forbidden changes: Remove required fields, change types incompatibly, rename fields
- Breaking changes require new topic/collection with version suffix

**Example - Adding Optional Field**:
- **Old Schema**: `{flightNumber: string, departureTime: timestamp}`
- **New Schema**: `{flightNumber: string, departureTime: timestamp, estimatedDepartureTime: timestamp?}`
- **Backward Compatible**: Old consumers ignore new field
- **Forward Compatible**: New consumers handle missing field (null)
- **Deployment**: No coordination required, consumers update independently

**Example - Breaking Change**:
- **Old Schema**: `{flightNumber: string, departureTime: timestamp}`
- **New Schema**: `{flightNumber: int, departureTime: timestamp}` (type change)
- **Not Backward Compatible**: Old consumers expect string, get int
- **Solution**: Create new topic `flight-event-aa-time-v2-avro`
- **Migration**: Gradual consumer migration from v1 to v2 topic

#### 8. Metadata as Code

**Principle**: All governance artifacts version-controlled and CI/CD integrated.

**Rationale**:
- Manual governance processes don't scale (50+ topics, 24 collections, 25 flows)
- Version control provides audit trail (who changed what, when, why)
- CI/CD automation prevents human error
- Infrastructure as Code (IaC) enables reproducibility

**Practical Implications**:
- Avro schemas stored in Git repository
- DocumentDB schemas stored in Git repository
- GraphQL schemas stored in Git repository
- CI/CD pipeline validates schemas on pull request
- Automated deployment to Schema Registry and S3

**Example - Schema Change Workflow**:
1. Developer creates branch: `feature/add-estimated-departure-time`
2. Developer modifies Avro schema file: `schemas/flight/FlightTimes.avsc`
3. Developer commits and pushes to Git
4. CI/CD pipeline triggers:
   - Validates Avro schema syntax
   - Checks backward compatibility
   - Runs automated tests
   - Performs impact analysis (which flows affected)
5. Pull request created with impact analysis results
6. Data Steward reviews and approves
7. Merge triggers deployment:
   - Schema registered in Confluent Schema Registry (us-east-1)
   - Schema replicated to us-west-2
   - Schema documentation updated in Data Catalog

#### 9. Federated Ownership

**Principle**: Data domains owned by Operations, technical implementation by IT.

**Rationale**:
- Operations teams understand business semantics (what data means)
- IT teams understand technical implementation (how data is stored)
- Federated ownership prevents bottlenecks (single team owning everything)
- Clear accountability (Operations owns correctness, IT owns performance)

**Practical Implications**:
- Each domain has Data Steward from Operations team
- Data Steward defines logical data model (entities, attributes, relationships)
- IT team implements physical data model (DocumentDB collections, indexes, queries)
- Data Steward approves schema changes (business impact)
- IT team implements schema changes (technical implementation)

**Example - Flight Domain**:
- **Data Steward**: Flight Operations team member
- **Responsibilities**:
  - Define what FlightIdentity, FlightTimes, FlightLeg mean
  - Define business rules (departureTime < arrivalTime)
  - Approve schema changes affecting flight operations
  - Define data quality requirements (completeness, accuracy)
- **IT Team Responsibilities**:
  - Implement DocumentDB collections for Flight entities
  - Create indexes for query performance
  - Implement data validation logic
  - Monitor query performance and optimize
  - Implement backup and recovery procedures

#### 10. Resilience by Design

**Principle**: Governance supports < 10 min RTO for regional failover.

**Rationale**:
- Flight operations are 24/7 critical (cannot tolerate extended outages)
- Regional failures happen (AWS outages, network issues, natural disasters)
- Governance must not impede resilience (no single points of failure)

**Practical Implications**:
- Schema Registry replicated across regions
- Data Catalog available in both regions
- Governance policies don't require single-region resources
- Failover procedures tested regularly (chaos engineering)

**Example - Regional Failover**:
1. **Phase 0 (Continuous)**: Health monitoring detects us-east-1 degradation
2. **Phase 1 (< 5 min)**: 
   - Route53 DNS updates kafka.nxop.com → us-west-2
   - DocumentDB promotes us-west-2 to primary
3. **Phase 2 (< 3 min)**:
   - Akamai GTM routes API traffic to us-west-2
   - AMQP listeners reconnect to Flightkeys
   - Kafka connectors reconnect to MSK
4. **Phase 3 (< 2 min)**: Validate all 25 flows operational in us-west-2
5. **Total RTO**: < 10 minutes
6. **Governance Impact**: None (all governance artifacts available in us-west-2)


## Architecture

### NXOP Multi-Cloud Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS NXOP Platform                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  KPaaS (EKS Clusters)                                                 │  │
│  │  Account: NonProd (285282426848), Prod (045755618773)               │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │  │
│  │  │ Flight Data│  │ Aircraft   │  │ Flightkeys │  │ Notification│   │  │
│  │  │ Adapter    │  │ Data       │  │ Event      │  │ Service     │   │  │
│  │  │            │  │ Adapter    │  │ Processor  │  │             │   │  │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘   │  │
│  │        │                │                │                │           │  │
│  │        └────────────────┴────────────────┴────────────────┘           │  │
│  │                         │ Pod Identity (Cross-Account IAM)            │  │
│  └─────────────────────────┼─────────────────────────────────────────────┘  │
│                            │                                                 │
│  ┌─────────────────────────▼─────────────────────────────────────────────┐  │
│  │  NXOP Infrastructure (us-east-1, us-west-2)                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │  │
│  │  │ MSK Cluster  │  │ DocumentDB   │  │ S3 + Iceberg │               │  │
│  │  │ Cross-Region │  │ Global       │  │ Tables       │               │  │
│  │  │ Replication  │  │ Cluster      │  │              │               │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘               │  │
│  │         │                  │                  │                        │  │
│  │         │ Route53 DNS      │ Automatic        │ Multi-Region          │  │
│  │         │ (kafka.nxop.com) │ Failover         │ Replication           │  │
│  │         │ → NLB → Brokers  │ < 1 min          │                       │  │
│  └─────────┴──────────────────┴──────────────────┴───────────────────────┘  │
│                            │                                                 │
│  ┌─────────────────────────▼─────────────────────────────────────────────┐  │
│  │  Akamai GTM (Global Traffic Manager)                                  │  │
│  │  Routes external API traffic to healthy region                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌───────▼────────┐         ┌────────▼────────┐       ┌────────▼────────┐
│ Azure FXIP     │         │ On-Premises FOS │       │ External Systems│
│ Platform       │         │                 │       │                 │
│ ┌────────────┐ │         │ ┌────────────┐ │       │ ┌────────────┐ │
│ │ Flightkeys │ │         │ │ DECS       │ │       │ │ Flightkeys │ │
│ │ Event      │ │         │ │ Load Plan  │ │       │ │ (AWS)      │ │
│ │ Processor  │ │         │ │ Takeoff    │ │       │ │ CyberJet   │ │
│ │ ConsulDB   │ │         │ │ Crew Mgmt  │ │       │ │ FMS (AWS)  │ │
│ └────────────┘ │         │ └────────────┘ │       │ └────────────┘ │
│ ┌────────────┐ │         │ ┌────────────┐ │       └─────────────────┘
│ │ OpsHub     │ │         │ │ OpsHub     │ │
│ │ Event Hubs │ │         │ │ On-Prem    │ │
│ └────────────┘ │         │ │ AIRCOM     │ │
└────────────────┘         │ │ MQ-Kafka   │ │
                           │ │ Adapter    │ │
                           │ └────────────┘ │
                           └─────────────────┘
```

### Governance Architecture Layers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Governance Council Layer                                  │
│  (Decision Rights, Policies, Standards, RACI)                               │
│  Members: Todd Waller (Chair), Kevin (Co-Chair), NXOP Platform Lead,       │
│           Scott (Architecture), Prem (Physical Design), Data Stewards       │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌────────▼────────┐   ┌──────▼──────┐
│  Logical Data  │   │  Data Catalog   │   │   Schema    │
│  Model Layer   │   │  & Metadata     │   │  Registry   │
│  (5 Domains)   │   │  (25 Flows)     │   │  (Multi-    │
│  (24 Entities) │   │                 │   │  Technology)│
└───────┬────────┘   └────────┬────────┘   └──────┬──────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────────────────────┐
│              Physical Implementation Layer                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  DocumentDB  │  │  Kafka/Avro  │  │   Iceberg    │  │   GraphQL    │ │
│  │   Schemas    │  │   Schemas    │  │   Schemas    │  │   Schemas    │ │
│  │  (5 Domains) │  │  (50+ Topics)│  │  (Analytics) │  │  (Apollo     │ │
│  │              │  │              │  │              │  │  Federation) │ │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────────────────────┐
│                   Data Quality Layer                                       │
│  (Validation, Monitoring, Alerting across 25 Message Flows)              │
└───────────────────────────────────────────────────────────────────────────┘
```


### Component Interactions

Understanding how components interact is crucial for implementing and operating the NXOP data governance framework. This section provides detailed interaction flows with technical specifics.

#### Governance Flow (Policy Establishment and Enforcement)

**Purpose**: Establish and enforce data governance policies across all 25 message flows and 7 integration patterns.

**Detailed Flow**:

**Step 1: Policy Establishment by Governance Council**
- **Trigger**: New integration pattern proposed, or existing pattern needs policy update
- **Process**:
  1. Governance Council meeting scheduled (weekly during setup, bi-weekly during implementation, monthly during steady-state)
  2. Proposal presented with:
     - Business justification (why this policy is needed)
     - Technical impact analysis (which flows affected)
     - Risk assessment (what could go wrong)
     - Cost-benefit analysis (implementation cost vs. benefit)
  3. Council members review:
     - Todd Waller (Enterprise Data Strategy): Enterprise alignment
     - Kevin (Ops Data Strategy): Operational impact
     - Scott (Architecture): Technical feasibility
     - Prem (Physical Design): Implementation complexity
     - Data Stewards: Domain-specific impacts
  4. Decision made:
     - Consensus preferred (all agree)
     - Majority vote if consensus not reached (>50% approval)
     - Chair authority for time-sensitive decisions (Todd Waller)
  5. Policy documented in governance repository (Git)
  6. Policy communicated to all stakeholders (email, Slack, wiki)

**Step 2: Logical Data Model Definition by Data Stewards**
- **Trigger**: New domain entity needed, or existing entity needs modification
- **Process**:
  1. Data Steward identifies need (e.g., new flight metric required for OTP reporting)
  2. Data Steward defines logical model:
     - Entity name (e.g., FlightMetrics)
     - Attributes (e.g., fuelMetrics, passengerMetrics, payloadMetrics)
     - Relationships (e.g., FlightMetrics → FlightIdentity via flightKey)
     - Business rules (e.g., fuelMetrics.actualFuel <= fuelMetrics.plannedFuel)
  3. Data Steward documents in logical model repository (Git)
  4. Data Steward presents to Governance Council for approval
  5. Council approves or requests modifications
  6. Approved model becomes authoritative definition

**Step 3: Schema Registry Enforcement**
- **Trigger**: Developer implements physical schema based on logical model
- **Process**:
  1. Developer creates Avro schema file (for MSK topics):
     ```json
     {
       "type": "record",
       "name": "FlightMetrics",
       "namespace": "com.aa.nxop.flight",
       "fields": [
         {"name": "flightKey", "type": "string"},
         {"name": "fuelMetrics", "type": {
           "type": "record",
           "name": "FuelMetrics",
           "fields": [
             {"name": "plannedFuel", "type": "double"},
             {"name": "actualFuel", "type": "double"}
           ]
         }}
       ]
     }
     ```
  2. Developer commits schema to Git
  3. CI/CD pipeline validates:
     - Syntax correctness (valid Avro schema)
     - Backward compatibility (can old consumers read new data)
     - Naming conventions (follows NXOP standards)
     - Logical model alignment (matches Data Steward's definition)
  4. Pull request created with validation results
  5. Data Steward reviews and approves
  6. Merge triggers deployment:
     - Schema registered in Confluent Schema Registry (us-east-1)
     - Schema ID assigned (e.g., schema ID 42)
     - Schema replicated to us-west-2
     - Schema version incremented (e.g., v1.0.0 → v1.1.0)

**Step 4: Physical Schema Implementation**
- **Trigger**: Schema approved and registered
- **Process**:
  1. IT team implements physical schema:
     - **MSK**: Producers use schema ID 42 when producing messages
     - **DocumentDB**: Collection created with validation rules
     - **GraphQL**: Type definitions added to subgraph schema
  2. IT team creates indexes for query performance:
     - DocumentDB: Index on flightKey for fast lookups
     - DocumentDB: Compound index on (flightKey, timestamp) for time-series queries
  3. IT team implements data validation logic:
     - Application-level validation (before writing to DocumentDB)
     - Schema validation (Avro schema enforced by Kafka)
     - Business rule validation (actualFuel <= plannedFuel)
  4. IT team deploys to non-prod environment for testing
  5. IT team validates with sample data
  6. IT team deploys to prod after approval

**Step 5: Data Catalog Automatic Discovery**
- **Trigger**: New schema deployed to production
- **Process**:
  1. Data Catalog crawler runs (hourly for MSK, daily for DocumentDB)
  2. Crawler discovers new schema:
     - MSK: Queries Confluent Schema Registry for new schemas
     - DocumentDB: Queries DocumentDB for new collections
     - S3: Queries S3 for new Iceberg tables
  3. Crawler extracts metadata:
     - Schema name and version
     - Fields and data types
     - Relationships to other schemas
     - Producer and consumer applications
  4. Crawler updates Data Catalog:
     - Technical metadata (schema structure)
     - Operational metadata (creation time, last modified)
     - Lineage metadata (upstream and downstream dependencies)
  5. Data Catalog sends notification:
     - Slack message to #nxop-data-catalog channel
     - Email to Data Steward
     - Dashboard updated with new asset

**Step 6: Data Quality Validation at Ingestion**
- **Trigger**: Data ingested into NXOP (via MSK, HTTPS API, or batch upload)
- **Process**:
  1. Data arrives at ingestion point:
     - MSK: Producer sends message to topic
     - HTTPS API: Client sends POST request
     - Batch: File uploaded to S3
  2. Schema validation:
     - MSK: Confluent Schema Registry validates Avro schema
     - HTTPS API: GraphQL validates against schema
     - Batch: Iceberg validates against table schema
  3. Business rule validation:
     - Application validates business rules (actualFuel <= plannedFuel)
     - Referential integrity checked (flightKey exists in FlightIdentity)
     - Data quality rules applied (completeness, accuracy, consistency)
  4. Validation result:
     - **Pass**: Data accepted and processed
     - **Fail**: Data rejected or quarantined
  5. Validation logging:
     - CloudWatch Logs: Validation failures logged with details
     - CloudWatch Metrics: Validation failure rate tracked
     - Data Quality Dashboard: Metrics updated in real-time
  6. Alerting:
     - Critical failures: PagerDuty alert to on-call engineer
     - Warning failures: Slack message to #nxop-data-quality
     - Info failures: Email to Data Steward

**Governance Flow Metrics**:
- Policy approval time: Target < 1 week for non-breaking changes, < 2 weeks for breaking changes
- Schema registration time: Target < 1 hour (automated via CI/CD)
- Data Catalog discovery time: Target < 1 hour for MSK, < 24 hours for DocumentDB
- Validation failure rate: Target < 1% for all ingestion points

**Governance Flow Monitoring**:
- CloudWatch Dashboard: "NXOP Governance Flow"
- Metrics:
  - Policy approval backlog (number of pending approvals)
  - Schema registration success rate (% successful registrations)
  - Data Catalog coverage (% of assets cataloged)
  - Validation failure rate by domain (Flight, Aircraft, Station, Maintenance, ADL)
- Alerts:
  - Policy approval backlog > 10: Alert Governance Council
  - Schema registration failure: Alert IT team
  - Data Catalog coverage < 95%: Alert Data Catalog team
  - Validation failure rate > 5%: Alert Data Steward

**Schema Evolution Flow**:
1. Developer proposes schema change in version control (Avro, DocumentDB, or GraphQL)
2. CI/CD pipeline validates against compatibility rules and message flow dependencies
3. Schema Registry performs impact analysis across affected message flows (out of 25 total)
4. Automated tests verify backward/forward compatibility
5. Approval workflow routes to appropriate Data Steward based on domain
6. Upon approval, schema deployed with version increment to both regions (us-east-1, us-west-2)
7. Data Catalog updated with new schema version and cross-cloud lineage

**Cross-Account Access Flow** (Pod Identity):
1. EKS pod in KPaaS account assumes KPaaS account role (intermediate)
2. KPaaS account role assumes NXOP account role (target) with trust policy validation
3. NXOP account role grants least-privilege access to resources (DocumentDB, MSK, S3)
4. Pod accesses NXOP resources using temporary credentials
5. All access logged for audit and governance compliance

**Message Flow Governance Flow**:
1. New message flow proposed with integration pattern classification (1 of 7 patterns)
2. Impact analysis identifies affected domains, schemas, and infrastructure dependencies
3. Data Stewards review domain-specific impacts
4. Schema Registry validates schema compatibility
5. Governance Council approves if cross-domain or high-impact
6. Message flow deployed with monitoring and alerting
7. Data Catalog automatically discovers and catalogs new flow

## Components and Interfaces

### 1. Governance Council

**Purpose**: Central decision-making body for data governance policies, standards, and conflict resolution across AWS, Azure, and On-Premises environments.

**Composition**:
- **Chair**: Enterprise Data Strategy (Todd Waller)
- **Co-Chair**: Operations Data Strategy (Kevin)
- **Members**: 
  - NXOP Platform Lead
  - Data Architecture (Scott)
  - Physical Design (Prem)
  - KPaaS Team Representative
  - Data Stewards (one per domain: Flight, Aircraft, Station, Maintenance, ADL)
  - Business Stakeholder Representatives (Analytics, Solvers)

**Responsibilities**:
- Approve data governance policies for 25 message flows and 7 integration patterns
- Resolve conflicts between FOS, NXOP, and enterprise models
- Approve major schema changes affecting multiple domains or message flows
- Review and approve tool selections (Schema Registry, Data Catalog, Quality tools)
- Approve cross-account IAM policies and Pod Identity configurations
- Quarterly scope and priority reviews
- Multi-cloud governance policy alignment (AWS, Azure, On-Premises)

**Decision Framework**:
- **Consensus**: Preferred for policy decisions affecting all 25 message flows
- **Majority Vote**: For prioritization and resource allocation
- **Chair Authority**: For time-sensitive operational decisions
- **Escalation Path**: CIO office for strategic conflicts or multi-cloud alignment issues

**Meeting Cadence**:
- **Weekly**: During initial 3-month setup phase (Months 1-3)
- **Bi-weekly**: Months 4-12 during active implementation
- **Monthly**: Months 13-18+ during steady-state operations

**Key Decisions Requiring Council Approval**:
- New integration pattern definitions (beyond existing 7 patterns)
- Breaking schema changes affecting 3+ message flows
- New data domain additions (beyond existing 5 domains)
- Cross-account IAM policy changes affecting all 25 flows
- FOS vendor integration strategies
- Enterprise data alignment conflicts
- Multi-region failover governance policies


### 2. Message Flow Registry

**Purpose**: Centralized registry documenting all 25 message flows with their integration patterns, dependencies, and governance metadata.

**Message Flow Catalog Structure**:

**Flow Metadata**:
- Flow ID and Name
- Integration Pattern (1 of 7: Inbound, Outbound, Bidirectional, Notification, Document Assembly, Authorization, Data Maintenance)
- Source Systems (Flightkeys, FOS, CyberJet FMS, etc.)
- NXOP Components (EKS services, MSK topics, DocumentDB collections)
- Destination Systems (FOS, FXIP, CyberJet, etc.)
- Communication Protocols (HTTPS, AMQP, Kafka, MQ, ACARS, TCP)
- Infrastructure Dependencies (MSK, DocumentDB, Akamai GTM, Route53, Pod Identity)
- Criticality (Vital, Critical, Discretionary per NXOP charter)
- Data Domains Involved (Flight, Aircraft, Station, Maintenance, ADL)
- SLA Requirements (latency, throughput, availability)
- Resilience Strategy (HA Automated, Regional Switchover, Manual Intervention)

**Integration Pattern Definitions**:

**1. Inbound Data Ingestion** (10 flows):
- **Pattern**: External sources → NXOP → On-Prem
- **Characteristics**: Asynchronous ingestion, transformation, validation, routing
- **Governance Focus**: Schema validation at ingestion, data quality rules, lineage tracking
- **Example Flows**: Flow 2 (Flight plans from Flightkeys), Flow 5 (Audit logs to OpsHub Event Hubs)

**2. Outbound Data Publishing** (2 flows):
- **Pattern**: On-Prem → NXOP → External systems
- **Characteristics**: Event streaming, enrichment, protocol translation
- **Governance Focus**: Schema compatibility, transformation correctness, delivery guarantees
- **Example Flows**: Flow 1 (FOS events to Flightkeys), Flow 11 (Flight events to CyberJet)

**3. Bidirectional Sync** (6 flows):
- **Pattern**: Two-way data synchronization
- **Characteristics**: Conflict resolution, consistency maintenance, bidirectional lineage
- **Governance Focus**: Consistency rules, conflict resolution policies, sync lag monitoring
- **Example Flows**: Flow 13 (Aircraft FMS initialization), Flow 15 (Flight progress reports)

**4. Notification/Alert** (3 flows):
- **Pattern**: Event-driven notifications
- **Characteristics**: Multi-destination routing, priority handling, delivery confirmation
- **Governance Focus**: Notification schema standards, delivery SLAs, alert escalation
- **Example Flows**: Flow 7 (Flight release notifications), Flow 14 (ACARS free text)

**5. Document Assembly** (1 flow):
- **Pattern**: Multi-service document generation
- **Characteristics**: Orchestration, aggregation, document formatting
- **Governance Focus**: Document schema standards, assembly logic validation, versioning
- **Example Flows**: Flow 8 (Pilot briefing package)

**6. Authorization** (2 flows):
- **Pattern**: Electronic signature workflows
- **Characteristics**: Compliance requirements, audit trails, multi-step approval
- **Governance Focus**: Signature schema standards, audit logging, compliance validation
- **Example Flows**: Flow 9 (eSignature CCI), Flow 10 (eSignature ACARS)

**7. Data Maintenance** (1 flow):
- **Pattern**: Reference data management
- **Characteristics**: Master data updates, synchronization, versioning
- **Governance Focus**: Master data quality, change tracking, distribution
- **Example Flows**: Flow 16 (Ops engineering fleet/reference data)

**Infrastructure Dependency Tracking**:

**MSK-Dependent Flows** (6 flows - 24%):
- Flows: 1, 2, 5, 10, 18, 19
- Governance: Avro schema registration, topic retention policies, consumer group management
- Resilience: Cross-region replication, Route53 DNS failover, < 10 min RTO

**DocumentDB-Dependent Flows** (5 flows - 20%):
- Flows: 1, 8, 10, 18, 19
- Governance: Collection schemas, index optimization, query patterns
- Resilience: Global Cluster failover, < 1 minute RTO

**Cross-Account IAM-Dependent Flows** (ALL 25 flows - 100%):
- Governance: Pod Identity trust policies, least-privilege access, approval workflows
- Resilience: Multi-region IAM replication, monitoring for auth failures

**Akamai GTM-Dependent Flows** (API-dependent flows):
- Governance: Health check configurations, traffic routing policies
- Resilience: Regional failover, health-based routing

**Route53 DNS-Dependent Flows** (MSK-dependent flows):
- Governance: DNS routing policies for MSK bootstrap (kafka.nxop.com)
- Resilience: Multi-region DNS failover

**Flow Governance Metadata**:
- Schema versions (Avro, DocumentDB, GraphQL)
- Data quality rules applied
- Monitoring dashboards and alerts
- Runbooks and troubleshooting guides
- Ownership and on-call rotation
- Change history and audit trail


### 3. Data Domain Models

**Purpose**: Define the 5 core NXOP data domains with their 24 entities, relationships, and governance ownership.

#### Flight Domain (7 Entities)

**Domain Purpose**: Core operational truth of flight lifecycle from schedule → updates → completion

**Why Domain-Driven Design**:
- Operational Hot Tier: Flight data must support real-time reads/writes, low latency, multi-region active-active replication
- System of Record: GraphQL consumers expect one unified flight object without joins
- Event-Heavy Workload: OPSHUB generates millions of events → embedding events ensures fast retrieval
- Flexible Evolution: DocumentDB allows polymorphic sub-structures for OPSHUB's variable event schemas

**Entities and Relationships**:

**1. FlightIdentity (Parent Entity)**:
- **Purpose**: Defines unique identity of a flight on a given day, acts as master reference
- **Key Characteristics**: 
  - Represents one flight regardless of operational changes
  - flightKey is composite ID: carrier + flight number + flight date + departure station + dupDepCode
  - flightKey used as connection for all other Flight Domain entities
- **Core Fields**: flightKey (PK), carrierCode, flightNumber, flightDate, departureStation, arrivalStation, dupDepCode
- **Relationships**: 1→1 with FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning
- **Governance**: Operations team owns business semantics, IT team owns DocumentDB implementation

**2. FlightTimes**:
- **Purpose**: Captures time-related data across entire lifecycle (Scheduled, Estimated, Actual, Latest)
- **Core Objects**: Scheduled, Estimated, Actual, Latest, Metadata
- **Relationship**: N→1 with FlightIdentity via flightKey
- **Governance**: Critical for OTP (On-Time Performance) metrics, strict validation rules

**3. FlightLeg**:
- **Purpose**: Represents operational leg including routing, gate/terminal, equipment, status
- **Core Objects**: LegInfo, LegEquipment, LegLinkage, LegStatus, Metadata
- **Relationship**: N→1 with FlightIdentity via flightKey
- **Governance**: Integrates with Station Domain for gate/terminal data

**4. FlightEvent**:
- **Purpose**: Stores current and last known event state with computed values
- **Core Objects**: FUFI, currentEventType, currentEventTime, currentEventSequence, lastEventType, lastEventTime, metadata
- **Relationship**: 1→1 with FlightIdentity, 1→Many with EventHistory (Phase 2)
- **Governance**: Event schema versioning critical, high-volume writes

**5. FlightMetrics**:
- **Purpose**: KPI-level performance and operational metrics extracted from Flight and OPSHUB
- **Core Fields**: FuelMetrics, PassengerMetrics, PayloadMetrics, WeightMetrics, PerformanceMetrics
- **Relationship**: N→1 with FlightIdentity via flightKey
- **Governance**: Used by analytics and solver applications, data quality critical

**6. FlightPosition**:
- **Purpose**: Aircraft movement and telemetry events (ACARS/ADS-B/ATC feeds)
- **Core Objects**: geographic position, speed & altitude, ACARS message details, aircraft identifiers, OPSHUB metadata
- **Relationship**: N→1 with FlightIdentity via flightKey
- **Governance**: High-volume time-series data, retention policies important

**7. FlightLoadPlanning**:
- **Purpose**: Load plan for passengers, freight, bags, compartments, cabin capacity
- **Core Objects**: LoadPlanPaxCounts, LoadPlanWeights, CabinCapacity
- **Relationship**: N→1 with FlightIdentity via flightKey
- **Governance**: Integrates with FOS Load Planning system

**Domain Governance**:
- **Data Steward**: Flight Operations team member
- **Schema Owner**: NXOP Platform Team
- **Message Flows**: Flows 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14 (11 of 25 flows)
- **DocumentDB Collections**: 7 collections (one per entity)
- **MSK Topics**: 40+ flight-related topics (flight-event-*, soar-aa-flightplan-*)

#### Aircraft Domain (5 Entities)

**Domain Purpose**: Authoritative master record of every aircraft in airline's fleet

**Why Separate Domain**:
- Aircraft lifecycle is independent of Flight lifecycle
- Aircraft information is reused across multiple domains
- Relatively static data, changes infrequently

**Entities and Relationships**:

**1. AircraftIdentity (Parent Entity)**:
- **Purpose**: Core aircraft identifiers used across ops systems, aggregate root within domain
- **Core Fields**: carrierCode, noseNumber, registration, numericCode, mnemonicFleetCode, mnemonicTypeCode, marketingFleetCode, ATCType, FAANavCode, alternateFAANAVCode, heavyInd, LUSInd, specialInd
- **Relationships**: 1→1 with AircraftConfiguration, AircraftLocation, AircraftPerformance, AircraftMEL
- **Governance**: Master data, synchronized with enterprise aircraft registry

**2. AircraftConfiguration**:
- **Purpose**: Static structural configuration (cabin layout, type, SELCAL, operator-defined attributes)
- **Core Fields**: configuration.code, configuration.ATCType, configuration.FAANavCode, configuration.marketingFleetCode, configuration.SELCAL, cabinCapacity
- **Relationship**: N→1 with AircraftIdentity via noseNumber
- **Governance**: Changes require maintenance approval, version controlled

**3. AircraftLocation**:
- **Purpose**: Current operational state (last flight, next flight, overnight planning, out-of-service status)
- **Core Objects**: Location (aircraftStatus, controlledRouteInd, outOfServiceCode, openMELitems), LastCompletedFlight, NextFlight, PlannedOverNight
- **Relationship**: N→1 with AircraftIdentity via noseNumber
- **Governance**: Real-time updates, critical for flight planning

**4. AircraftPerformance**:
- **Purpose**: Weight limits, operational performance values, miscellaneous operational configuration
- **Core Objects**: weight (static: emptyOperatingWeight, maximumFuelCapacity, etc.), weightMisc (dynamic: fuelFlowCorrectionFactor, etc.)
- **Relationship**: N→1 with AircraftIdentity via noseNumber
- **Governance**: Used by FOS Takeoff Performance calculations, strict validation

**5. AircraftMEL**:
- **Purpose**: Active Minimum Equipment List items (issue, effectivity, subsystem, closure details)
- **Core Fields**: ATASystemID, AMRNumber, subSystem, systemCode, description, issue.dateTime, issue.station, effectivity, close.dateTime
- **Relationship**: N→1 with AircraftIdentity via noseNumber
- **Governance**: Compliance-critical, audit trail required, integrates with Maintenance Domain

**Domain Governance**:
- **Data Steward**: Fleet Management team member
- **Schema Owner**: NXOP Platform Team
- **Message Flows**: Flows 1, 10, 11, 13, 15 (5 of 25 flows)
- **DocumentDB Collections**: 5 collections (one per entity)
- **MSK Topics**: 9 aircraft-related topics (aircraft-snapshot-*, aircraft-update-*)

#### Station Domain (4 Entities)

**Domain Purpose**: Airports and airline stations used across all flight operations, single authoritative source of truth

**Why Separate Domain**:
- Provides single source of truth for station identity, geography, operational capabilities, authorization rules
- Data is relatively static, changes infrequently, heavily reused by multiple domains
- Primary data source: OPSHUB Station/AirportInfo Collections

**Entities and Relationships**:

**1. StationIdentity (Parent Entity)**:
- **Purpose**: Primary anchor for Station Domain, represents unique station from airline's perspective
- **Core Fields**: icaoAirportID, iataAirlineCode, airportName, stationName, ataAirportID, icaoAreaCode, intlStation, aaStation, cat3LandingsAllowed, coTerminalAllowed, stationMaintClass, actionCode, timeStamp
- **Relationships**: 1→1 with StationGeo, StationAuthorization, StationMetadata
- **Governance**: Master data, synchronized with enterprise airport registry

**2. StationGeo**:
- **Purpose**: Geographical and physical characteristics for operations, routing logic, performance calculations
- **Core Fields**: latitude, longitude, elevation, magneticVariation, longestRunwayLength, recommendedNAVAID, recommendedNAVAIDICAOAreaCode
- **Relationship**: N→1 with StationIdentity via icaoAirportID
- **Governance**: Used by FOS routing and performance calculations

**3. StationAuthorization**:
- **Purpose**: Landing authorization configurations, preserves OPSHUB structure
- **Core Objects**: scheduledLandingsAuthorized[], charteredLandingsAuthorized[], driftdownLandingsAuthorized[], alternateLandingsAuthorized[]
- **Relationship**: N→1 with StationIdentity via icaoAirportID
- **Governance**: Compliance-critical, FAA/IATA regulations

**4. StationMetadata**:
- **Purpose**: Operational metadata and additional station attributes
- **Relationship**: N→1 with StationIdentity via icaoAirportID
- **Governance**: Extensible for future operational needs

**Domain Governance**:
- **Data Steward**: Network Planning team member
- **Schema Owner**: NXOP Platform Team
- **Message Flows**: Flows 1, 2, 3, 4, 16 (5 of 25 flows)
- **DocumentDB Collections**: 4 collections (one per entity)
- **MSK Topics**: 3 station-related topics (airport-event-*, airport-update-*)


#### Maintenance Domain (6 Entities)

**Domain Purpose**: All aircraft maintenance operations reported through OPSHUB (deferred defects, out-of-service status, airframe metrics, complete maintenance event lifecycle)

**Key Characteristics**:
- Event-driven data (trackingID per event)
- Complex nested structures (DMI, OTS, LandingData)
- Historical event chains (100+ entries)
- Aircraft-centric and timestamp-heavy
- High variability and update frequency

**Entities and Relationships**:

**1. MaintenanceRecord (Parent Entity)**:
- **Purpose**: Top-level snapshot of maintenance event from OPSHUB, root for all child entities
- **Core Fields**: trackingID, airlineCode.iata, airlineCode.icao, tailNumber, registration, event, schemaVersion, fosPartition
- **Relationships**: 1→Many with MaintenanceDMI, MaintenanceEquipment, MaintenanceLandingData, MaintenanceOTS, MaintenanceEventHistory
- **Governance**: Event-driven, high-volume writes, retention policies critical

**2. MaintenanceDMI**:
- **Purpose**: List of deferred defects associated with aircraft at time of maintenance event
- **Core Fields**: dmiId.ataCode, dmiId.controlNumber, dmiId.dmiClass, dmiId.eqType, dmiData.position, dmiData.dmiText, dmiData.effectiveTime
- **Relationship**: N→1 with MaintenanceRecord via trackingID
- **Governance**: Compliance-critical, integrates with AircraftMEL entity

**3. MaintenanceEquipment**:
- **Purpose**: Aircraft equipment configuration as captured in maintenance event
- **Core Fields**: equip.fleetType, equip.typeEq, equip.numericEqType, equip.eventSourceTimeStamp, equip.updateTimeStamp
- **Relationship**: N→1 with MaintenanceRecord via trackingID
- **Governance**: Not static like Aircraft domain, event-specific snapshot

**4. MaintenanceLandingData**:
- **Purpose**: Aircraft's lifetime operational metrics and flight relationships (critical for heavy maintenance planning)
- **Core Fields**: ttlTime (total lifetime airframe time), cycles, lastFlt.ftNum, lastFlt.date, nextFlt.ftNum, nextFlt.date, landingData.eventSourceTimeStamp
- **Relationship**: N→1 with MaintenanceRecord via trackingID
- **Governance**: Used for maintenance scheduling, flight-worthiness checks

**5. MaintenanceOTS**:
- **Purpose**: Out-of-service status and related maintenance information
- **Relationship**: N→1 with MaintenanceRecord via trackingID
- **Governance**: Critical for aircraft availability planning

**6. MaintenanceEventHistory**:
- **Purpose**: Complete maintenance event lifecycle with historical event chains
- **Relationship**: N→1 with MaintenanceRecord via trackingID
- **Governance**: Audit trail, compliance, historical analysis

**Domain Governance**:
- **Data Steward**: Maintenance Operations team member
- **Schema Owner**: NXOP Platform Team
- **Message Flows**: Flows 1, 10, 16 (3 of 25 flows)
- **DocumentDB Collections**: 6 collections (one per entity)
- **MSK Topics**: 1 maintenance topic (internal-maintenanceevents-avro)

#### ADL Domain (2 Entities)

**Domain Purpose**: Authoritative, near-real-time flight metadata and snapshots sourced from FOS, representing operational state at time of ADL feed

**Why Separate Domain**:
- Complements ASM/OPSHUB by delivering unified, consistent snapshot of flight-level information
- Data is flattened, canonical, and FOS-derived, making it trusted operational reference
- ADL records include unique fields (snapshot timestamps, FOS indicators, ADL-specific metadata) that don't belong in core Flight domain
- Preserving ADL as own domain ensures clear lineage, easier ingestion logic, better traceability of FOS snapshots

**Key Characteristics**:
- FOS-derived snapshot layer
- Near-real-time operational reference
- Canonical format for downstream systems
- Preserves FOS indicators and metadata

**Entities and Relationships**:

**1. adlHeader (Parent Entity)**:
- **Purpose**: Top-level snapshot metadata for flight extracted from ADL (snapshot timestamp, ADL record ID, airline identifiers, key operational flags)
- **Core Fields**: activeGdp, adlID, employeeId, runId, sessionId
- **Relationships**: 1→1 with adlFlights
- **Governance**: FOS-sourced, preserves FOS metadata, version controlled

**2. adlFlights**:
- **Purpose**: Arrival and departure related metadata from ADL feed, reflects FOS' view of operations
- **Core Fields**: FlightKey, departureFlights, arrivalFlights, category, weightClass, delayCancelFlightSlotAvailability
- **Relationship**: N→1 with adlHeader via adlID
- **Governance**: FOS alignment critical, transformation rules documented

**Domain Governance**:
- **Data Steward**: FOS Integration team member
- **Schema Owner**: NXOP Platform Team
- **Message Flows**: Flows 1, 2, 5 (3 of 25 flows)
- **DocumentDB Collections**: 2 collections (one per entity)
- **MSK Topics**: 1 ADL topic (adl-data)

**Cross-Domain Relationships**:
- Flight Domain ↔ Aircraft Domain: FlightIdentity.tailNumber → AircraftIdentity.noseNumber
- Flight Domain ↔ Station Domain: FlightIdentity.departureStation/arrivalStation → StationIdentity.iataAirlineCode
- Aircraft Domain ↔ Maintenance Domain: AircraftIdentity.noseNumber → MaintenanceRecord.tailNumber
- Flight Domain ↔ ADL Domain: FlightIdentity.flightKey → adlFlights.FlightKey
- Maintenance Domain ↔ Aircraft Domain: MaintenanceRecord.tailNumber → AircraftIdentity.noseNumber, MaintenanceDMI → AircraftMEL


### 4. Cross-Account IAM and Pod Identity Design

**Purpose**: Enable secure, credential-free authentication for EKS workloads in KPaaS to access NXOP resources across AWS accounts.

**Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  KPaaS Account (NonProd: 285282426848, Prod: 045755618773)         │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  EKS Cluster                                                   │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Pod (Flight Data Adapter)                               │ │ │
│  │  │  Service Account: flight-data-adapter-sa                 │ │ │
│  │  │  Namespace: nxop-prod                                    │ │ │
│  │  │  Annotation: runway.aa.com/pod-identity:                 │ │ │
│  │  │              <NXOP_Account_ID>/flight-data-adapter-role  │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                         │                                      │ │
│  │                         │ 1. AssumeRole                        │ │
│  │                         ▼                                      │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  KPaaS Account Role (Intermediate)                       │ │ │
│  │  │  Managed by KPaaS Team                                   │ │ │
│  │  │  Trust Policy: EKS OIDC Provider                         │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ 2. AssumeRole (Cross-Account)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  NXOP Account                                                        │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  NXOP Account Role (Target)                                   │ │
│  │  Created by NXOP Team                                         │ │
│  │  Trust Policy:                                                │ │
│  │    - Principal: KPaaS Account Root                           │ │
│  │    - Conditions:                                              │ │
│  │      * kubernetes-namespace: nxop-prod                        │ │
│  │      * eks-cluster-arn: arn:aws:eks:*:285282426848:cluster/* │ │
│  │  Permissions:                                                 │ │
│  │    - DocumentDB: Read/Write specific collections             │ │
│  │    - MSK: Produce/Consume specific topics                    │ │
│  │    - S3: Read/Write specific buckets                         │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                         │                                           │
│                         │ 3. Access Resources                       │
│                         ▼                                           │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  NXOP Resources                                               │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ DocumentDB   │  │ MSK Cluster  │  │ S3 Buckets   │       │ │
│  │  │ Collections  │  │ Topics       │  │              │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Dual-Role Pattern**:

**Role 1: KPaaS Account Role (Intermediate)**:
- **Created By**: KPaaS Team
- **Purpose**: Assumed directly by EKS pod via IRSA (IAM Roles for Service Accounts)
- **Trust Policy**: EKS OIDC Provider
- **Permissions**: AssumeRole permission for NXOP account roles
- **Lifecycle**: Managed by KPaaS team, NXOP team has no control

**Role 2: NXOP Account Role (Target)**:
- **Created By**: NXOP Team
- **Purpose**: Grants actual permissions to NXOP resources
- **Trust Policy**: 
  - Principal: KPaaS Account Root (arn:aws:iam::285282426848:root for NonProd)
  - Conditions:
    - `aws:RequestTag/kubernetes-namespace`: Restricts to specific namespace
    - `aws:RequestTag/eks-cluster-arn`: Restricts to EKS clusters in KPaaS account
    - (Recommended) `aws:RequestTag/kubernetes-service-account`: Restricts to specific service account
- **Permissions**: Least-privilege access to specific NXOP resources
- **Lifecycle**: Managed by NXOP team via IaC (Terraform/CloudFormation)

**Trust Policy Example**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::285282426848:root"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/kubernetes-namespace": "nxop-prod",
          "aws:RequestTag/kubernetes-service-account": "flight-data-adapter-sa"
        },
        "StringLike": {
          "aws:RequestTag/eks-cluster-arn": "arn:aws:eks:*:285282426848:cluster/*"
        }
      }
    }
  ]
}
```

**Permissions Policy Example** (Flight Data Adapter):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "docdb:DescribeDBClusters",
        "docdb:DescribeDBInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "docdb:Connect"
      ],
      "Resource": [
        "arn:aws:rds:us-east-1:*:cluster:nxop-docdb-cluster",
        "arn:aws:rds:us-west-2:*:cluster:nxop-docdb-cluster"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kafka:DescribeCluster",
        "kafka:GetBootstrapBrokers"
      ],
      "Resource": [
        "arn:aws:kafka:us-east-1:*:cluster/nxop-msk-cluster/*",
        "arn:aws:kafka:us-west-2:*:cluster/nxop-msk-cluster/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData",
        "kafka-cluster:WriteData"
      ],
      "Resource": [
        "arn:aws:kafka:us-east-1:*:topic/nxop-msk-cluster/*/flight-event-*",
        "arn:aws:kafka:us-west-2:*:topic/nxop-msk-cluster/*/flight-event-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::nxop-flight-data-*/enrichment/*"
      ]
    }
  ]
}
```

**KPaaS WebApp Configuration**:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flight-data-adapter-sa
  namespace: nxop-prod
  annotations:
    runway.aa.com/pod-identity: "<NXOP_Account_ID>/flight-data-adapter-role"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flight-data-adapter
  namespace: nxop-prod
spec:
  template:
    spec:
      serviceAccountName: flight-data-adapter-sa
      containers:
      - name: adapter
        image: flight-data-adapter:latest
        env:
        - name: AWS_ROLE_ARN
          value: "arn:aws:iam::<NXOP_Account_ID>:role/flight-data-adapter-role"
        - name: AWS_WEB_IDENTITY_TOKEN_FILE
          value: "/var/run/secrets/eks.amazonaws.com/serviceaccount/token"
```

**Governance Policies**:

**Role Creation Process**:
1. Application team submits Pod Identity request with resource requirements
2. NXOP security team reviews and approves least-privilege permissions
3. KPaaS security team reviews and approves trust policy conditions
4. NXOP team creates role via IaC with approved permissions
5. Application team adds annotation to KPaaS WebApp configuration
6. Deployment tested in non-prod before prod rollout

**Role Modification Process**:
1. Application team submits change request with justification
2. Impact analysis performed across all 25 message flows
3. Joint approval from NXOP and KPaaS security teams
4. Role updated via IaC with version control
5. Deployment tested and validated
6. Audit log reviewed for unexpected access patterns

**Monitoring and Alerting**:
- AssumeRole denials logged and alerted (CloudWatch Logs + SNS)
- Permission denials logged and alerted (CloudTrail + CloudWatch)
- Unusual access patterns detected (GuardDuty + Security Hub)
- Role usage metrics tracked (CloudWatch Metrics)
- Quarterly access reviews for all Pod Identity roles

**Impact on Message Flows**:
- **ALL 25 flows** depend on Pod Identity for cross-account access
- Pod Identity failure = complete NXOP platform outage
- Monitoring and alerting critical for operational resilience
- Multi-region IAM replication ensures failover capability



### 5. MSK and Event Streaming Governance

**Purpose**: Govern MSK clusters and event streaming infrastructure supporting 6 MSK-dependent message flows (24% of all flows).

**MSK Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  us-east-1 (Primary Region)                                         │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  MSK Cluster (nxop-msk-cluster-east)                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Broker 1     │  │ Broker 2     │  │ Broker 3     │       │ │
│  │  │ AZ: us-e-1a  │  │ AZ: us-e-1b  │  │ AZ: us-e-1c  │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  │         │                  │                  │               │ │
│  │         └──────────────────┴──────────────────┘               │ │
│  │                         │                                      │ │
│  │                         ▼                                      │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Network Load Balancer (NLB)                             │ │ │
│  │  │  Internal: nxop-msk-nlb-east.internal                    │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Cross-Region Replication
                              │ (Bidirectional)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  us-west-2 (Secondary Region)                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  MSK Cluster (nxop-msk-cluster-west)                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Broker 1     │  │ Broker 2     │  │ Broker 3     │       │ │
│  │  │ AZ: us-w-2a  │  │ AZ: us-w-2b  │  │ AZ: us-w-2c  │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  │         │                  │                  │               │ │
│  │         └──────────────────┴──────────────────┘               │ │
│  │                         │                                      │ │
│  │                         ▼                                      │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Network Load Balancer (NLB)                             │ │ │
│  │  │  Internal: nxop-msk-nlb-west.internal                    │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Route53 DNS (kafka.nxop.com)                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Health-Based Routing Policy                                  │ │
│  │  Primary: nxop-msk-nlb-east.internal                         │ │
│  │  Secondary: nxop-msk-nlb-west.internal                       │ │
│  │  Failover: < 10 min RTO                                      │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**MSK-Dependent Message Flows** (6 flows - 24%):
- **Flow 1**: Publish FOS Event Data to Flightkeys
- **Flow 2**: Receive and Publish Flight Plans from Flightkeys
- **Flow 5**: Receive and Publish Audit Logs, Weather, FK OFP Data
- **Flow 10**: Pilot eSignature for Flight Release - ACARS
- **Flow 18**: (Additional flow - TBD)
- **Flow 19**: (Additional flow - TBD)


**Topic Governance Structure**:

**Flight Domain Topics** (40+ topics):
- `flight-event-aa-*-avro`: American Airlines flight events (aircraft, departure-arrival, flightplan, fuel, init, load, misc, schedule, time)
- `flight-event-mq-*-avro`: Envoy Air flight events (same categories)
- `flight-event-te-*-avro`: PSA Airlines flight events (same categories)
- `flight-event-y6-*-avro`: Piedmont Airlines flight events (departure-arrival, time)
- `soar-aa-flightplan-*`: Flight plan data (gzip, auditevents-xml, auditlog-xml, fkofp-gzip, weather-xml, flighthistory)
- `internal-flightevent-avro`: OpsHub On-Prem flight events (72 hours retention, 32 partitions)
- `internal-flightevent-future-avro`: Future flight events (72 hours retention, 12 partitions)

**Aircraft Domain Topics** (9 topics):
- `aircraft-snapshot-*-location-avro`: Aircraft location snapshots (aa, mq, te)
- `aircraft-snapshot-*-static-avro`: Aircraft static data snapshots (aa, mq, te)
- `aircraft-update-*-location-avro`: Aircraft location updates (aa, mq, te)
- `internal-aircraftevents-avro`: OpsHub On-Prem aircraft events (72 hours retention, 8 partitions)

**Station Domain Topics** (3 topics):
- `airport-event-aa-misc-avro`: Airport miscellaneous events (3 days retention, 4 partitions)
- `airport-update-aa-avro`: Airport updates (3 days retention, 4 partitions)
- `ext-airport-event-ramp-avro`: External ramp events (3 days retention, 8 partitions)
- `internal-airportevents-avro`: OpsHub On-Prem airport events (72 hours retention, 4 partitions)

**Maintenance Domain Topics** (1 topic):
- `internal-maintenanceevents-avro`: OpsHub On-Prem maintenance events (72 hours retention, 8 partitions)

**ADL Domain Topics** (1 topic):
- `adl-data`: ADL feed data (72 hours retention, 12 partitions)

**Topic Retention Policies**:
- **1 day**: Aircraft snapshots and updates (operational data, high volume)
- **3 days**: Flight events, airport events (operational data, moderate volume)
- **72 hours**: Internal events from OpsHub On-Prem, SOAR flight plans, ADL data (compliance, audit trail)

**Topic Partition Strategy**:
- **4 partitions**: Low-volume topics (init events, airport events)
- **8 partitions**: Medium-volume topics (aircraft events, maintenance events, external ramp events)
- **12 partitions**: High-volume topics (future flight events, ADL data)
- **16 partitions**: Very high-volume topics (flight events for aa carrier)
- **32 partitions**: Extremely high-volume topics (internal flight events from OpsHub)

**Avro Schema Registry**:
- **Technology**: Confluent Schema Registry
- **Deployment**: Multi-region (us-east-1, us-west-2) with replication
- **Compatibility Mode**: Backward compatibility (default) for operational topics
- **Schema Versioning**: Semantic versioning (major.minor.patch)
- **Schema Evolution**: Backward-compatible changes allowed, breaking changes require new topic


**Producer Governance**:
- **MQ-Kafka Adapter** (On-Prem): Produces to flight, aircraft, airport, maintenance topics from FOS
- **Flight Data Adapter** (EKS): Produces to flight-event-* topics
- **Aircraft Data Adapter** (EKS): Produces to aircraft-* topics
- **FXIP Audit Log Processor** (EKS): Produces to soar-aa-flightplan-auditlog-xml
- **Flightkeys Event Processor** (EKS): Produces to internal-flightevent-avro

**Consumer Governance**:
- **Flight Data Adapter** (EKS): Consumes from flight-event-* topics
- **Aircraft Data Adapter** (EKS): Consumes from aircraft-* topics
- **Kafka Connector** (Azure): Consumes from MSK and publishes to OpsHub Event Hubs
- **MQ-Kafka Adapter** (On-Prem): Consumes from MSK and publishes to FOS MQ

**Cross-Region Replication**:
- **Replication Type**: Bidirectional (us-east-1 ↔ us-west-2)
- **Replication Lag**: < 1 second (target)
- **Replication Monitoring**: CloudWatch metrics for replication lag, throughput, errors
- **Failover Strategy**: Route53 DNS failover to secondary region (< 10 min RTO)

**Route53 DNS Routing**:
- **DNS Name**: kafka.nxop.com
- **Routing Policy**: Health-based failover
- **Primary Target**: nxop-msk-nlb-east.internal (us-east-1)
- **Secondary Target**: nxop-msk-nlb-west.internal (us-west-2)
- **Health Checks**: MSK broker availability, consumer lag, replication lag
- **TTL**: 60 seconds (fast failover)

**Bootstrap Connection Flow**:
1. Producer/Consumer resolves kafka.nxop.com via Route53
2. Route53 returns NLB endpoint based on health checks
3. Producer/Consumer connects to NLB
4. NLB routes to healthy MSK brokers
5. After bootstrap, Producer/Consumer connects directly to brokers
6. If broker fails, Producer/Consumer reconnects via NLB

**Governance Policies**:
- **Topic Creation**: Requires approval from Data Steward and NXOP Platform Team
- **Schema Registration**: Automated via CI/CD pipeline with compatibility validation
- **Consumer Group Management**: Naming convention enforced (domain-app-env-consumer)
- **Retention Policy Changes**: Requires approval from Governance Council
- **Partition Count Changes**: Requires capacity planning review and approval
- **Cross-Region Replication**: Enabled by default for all operational topics

**Monitoring and Alerting**:
- **Broker Health**: CPU, memory, disk, network utilization
- **Topic Metrics**: Message rate, byte rate, partition count, retention
- **Consumer Lag**: Per consumer group, alerting on lag > 1000 messages
- **Replication Lag**: Cross-region replication lag, alerting on lag > 5 seconds
- **Schema Registry**: Schema registration failures, compatibility violations

**Resilience Strategy**:
- **HA Automated**: Broker failures handled by MSK (automatic replacement)
- **Regional Switchover**: Route53 DNS failover to secondary region (< 10 min RTO)
- **Manual Intervention**: Schema compatibility violations, topic configuration errors


### 6. DocumentDB Global Cluster Governance

**Purpose**: Govern DocumentDB Global Clusters supporting 5 DocumentDB-dependent message flows (20% of all flows).

**DocumentDB Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  us-east-1 (Primary Region)                                         │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  DocumentDB Global Cluster (nxop-docdb-global)               │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Primary      │  │ Replica 1    │  │ Replica 2    │       │ │
│  │  │ Instance     │  │ AZ: us-e-1b  │  │ AZ: us-e-1c  │       │ │
│  │  │ AZ: us-e-1a  │  │              │  │              │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  │         │                  │                  │               │ │
│  │         └──────────────────┴──────────────────┘               │ │
│  │                         │                                      │ │
│  │                         ▼                                      │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Cluster Endpoint (Read/Write)                           │ │ │
│  │  │  nxop-docdb-global.cluster-xxx.us-east-1.docdb.aws.com  │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Reader Endpoint (Read-Only)                             │ │ │
│  │  │  nxop-docdb-global.cluster-ro-xxx.us-east-1.docdb.aws   │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Global Cluster Replication
                              │ (Asynchronous, < 1 second lag)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  us-west-2 (Secondary Region)                                       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  DocumentDB Global Cluster (nxop-docdb-global)               │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Secondary    │  │ Replica 1    │  │ Replica 2    │       │ │
│  │  │ Instance     │  │ AZ: us-w-2b  │  │ AZ: us-w-2c  │       │ │
│  │  │ AZ: us-w-2a  │  │              │  │              │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  │         │                  │                  │               │ │
│  │         └──────────────────┴──────────────────┘               │ │
│  │                         │                                      │ │
│  │                         ▼                                      │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Cluster Endpoint (Read-Only during normal operation)   │ │ │
│  │  │  nxop-docdb-global.cluster-xxx.us-west-2.docdb.aws.com  │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │  Reader Endpoint (Read-Only)                             │ │ │
│  │  │  nxop-docdb-global.cluster-ro-xxx.us-west-2.docdb.aws   │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```


**DocumentDB-Dependent Message Flows** (5 flows - 20%):
- **Flow 1**: Publish FOS Event Data to Flightkeys (reference data enrichment)
- **Flow 8**: Retrieve Pilot Briefing Package (metadata storage)
- **Flow 10**: Pilot eSignature for Flight Release - ACARS (signature validation)
- **Flow 18**: (Additional flow - TBD)
- **Flow 19**: (Additional flow - TBD)

**Collection Structure by Domain**:

**Flight Domain Collections** (7 collections):
- `FlightIdentity`: Parent entity with flightKey composite ID
- `FlightTimes`: Scheduled, estimated, actual, latest times
- `FlightLeg`: Routing, gate/terminal, equipment, status
- `FlightEvent`: Current and last known event state
- `FlightMetrics`: KPI-level performance metrics
- `FlightPosition`: Aircraft movement and telemetry
- `FlightLoadPlanning`: Load plan for passengers, freight, bags

**Aircraft Domain Collections** (5 collections):
- `AircraftIdentity`: Parent entity with noseNumber
- `AircraftConfiguration`: Static structural configuration
- `AircraftLocation`: Current operational state
- `AircraftPerformance`: Weight limits, operational performance
- `AircraftMEL`: Active Minimum Equipment List items

**Station Domain Collections** (4 collections):
- `StationIdentity`: Parent entity with ICAO + IATA
- `StationGeo`: Geographical and physical characteristics
- `StationAuthorization`: Landing authorization configurations
- `StationMetadata`: Operational metadata

**Maintenance Domain Collections** (6 collections):
- `MaintenanceRecord`: Parent entity with trackingID
- `MaintenanceDMI`: Deferred defects list
- `MaintenanceEquipment`: Equipment configuration at event time
- `MaintenanceLandingData`: Lifetime operational metrics
- `MaintenanceOTS`: Out-of-service status
- `MaintenanceEventHistory`: Complete maintenance event lifecycle

**ADL Domain Collections** (2 collections):
- `adlHeader`: Snapshot metadata
- `adlFlights`: Arrival/departure metadata from ADL feed

**Total Collections**: 24 collections (one per entity across 5 domains)

**Schema Governance**:
- **Schema Format**: JSON Schema with validation rules
- **Schema Versioning**: Version field in each document (schemaVersion)
- **Schema Evolution**: Additive changes allowed, breaking changes require migration
- **Schema Validation**: Enforced at application layer (not database layer)
- **Schema Documentation**: Maintained in version control with examples

**Index Strategy**:

**Flight Domain Indexes**:
- `FlightIdentity`: flightKey (unique), carrierCode + flightNumber + flightDate
- `FlightTimes`: flightKey, departureTime, arrivalTime
- `FlightLeg`: flightKey, departureStation, arrivalStation
- `FlightEvent`: flightKey, currentEventType, currentEventTime
- `FlightMetrics`: flightKey, performanceMetrics
- `FlightPosition`: flightKey, positionTime
- `FlightLoadPlanning`: flightKey

**Aircraft Domain Indexes**:
- `AircraftIdentity`: noseNumber (unique), registration, carrierCode
- `AircraftConfiguration`: noseNumber
- `AircraftLocation`: noseNumber, aircraftStatus
- `AircraftPerformance`: noseNumber
- `AircraftMEL`: noseNumber, ATASystemID

**Station Domain Indexes**:
- `StationIdentity`: icaoAirportID (unique), iataAirlineCode
- `StationGeo`: icaoAirportID
- `StationAuthorization`: icaoAirportID
- `StationMetadata`: icaoAirportID

**Maintenance Domain Indexes**:
- `MaintenanceRecord`: trackingID (unique), tailNumber, event
- `MaintenanceDMI`: trackingID
- `MaintenanceEquipment`: trackingID
- `MaintenanceLandingData`: trackingID
- `MaintenanceOTS`: trackingID
- `MaintenanceEventHistory`: trackingID

**ADL Domain Indexes**:
- `adlHeader`: adlID (unique), runId, sessionId
- `adlFlights`: adlID, FlightKey


**Access Patterns**:

**Read-Heavy Collections**:
- `AircraftConfiguration`: Referenced for enrichment in Flow 1 (FOS event publishing)
- `StationGeo`: Referenced for routing and performance calculations
- `FlightIdentity`: Referenced for flight lookups across all flows

**Write-Heavy Collections**:
- `FlightEvent`: High-volume writes from OpsHub events
- `FlightPosition`: High-volume writes from ACARS/ADS-B feeds
- `MaintenanceRecord`: Event-driven writes from maintenance events

**Mixed Access Collections**:
- `FlightTimes`: Frequent reads and updates as flight progresses
- `AircraftLocation`: Frequent reads and updates as aircraft moves
- `FlightLoadPlanning`: Reads for briefing packages, writes for load updates

**Global Cluster Replication**:
- **Replication Type**: Asynchronous (Primary → Secondary)
- **Replication Lag**: < 1 second (target)
- **Replication Monitoring**: CloudWatch metrics for replication lag, throughput
- **Failover Strategy**: Automatic failover to secondary region (< 1 minute RTO)
- **Failover Trigger**: Primary region unavailable, manual promotion

**Failover Behavior**:
- **Normal Operation**: Primary (us-east-1) handles all writes, both regions handle reads
- **Failover**: Secondary (us-west-2) promoted to primary, handles all writes
- **Failback**: Manual process after primary region recovery

**Connection Management**:
- **Connection Pooling**: Enabled at application layer (EKS pods)
- **Connection String**: Cluster endpoint for writes, reader endpoint for reads
- **Connection Retry**: Exponential backoff with jitter
- **Connection Timeout**: 5 seconds (configurable)

**Governance Policies**:
- **Collection Creation**: Requires approval from Data Steward and NXOP Platform Team
- **Schema Changes**: Automated via CI/CD pipeline with validation
- **Index Creation**: Requires capacity planning review and approval
- **Data Retention**: Defined per collection based on compliance requirements
- **Backup Strategy**: Automated daily backups with 35-day retention

**Monitoring and Alerting**:
- **Instance Health**: CPU, memory, disk, network utilization
- **Connection Metrics**: Active connections, connection errors, connection pool exhaustion
- **Query Performance**: Slow queries (> 1 second), query execution time
- **Replication Lag**: Cross-region replication lag, alerting on lag > 5 seconds
- **Failover Status**: Automatic failover events, manual promotion events

**Resilience Strategy**:
- **HA Automated**: Instance failures handled by DocumentDB (automatic replacement)
- **Regional Switchover**: Automatic failover to secondary region (< 1 minute RTO)
- **Manual Intervention**: Schema validation errors, index creation failures


### 7. Schema Registry Design

**Purpose**: Centralized schema management and versioning across Avro (MSK), DocumentDB, and GraphQL schemas.

**Multi-Technology Schema Registry**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Schema Registry Architecture                                        │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Confluent Schema Registry (Avro/Kafka)                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ us-east-1    │  │ us-west-2    │  │ Replication  │       │ │
│  │  │ Primary      │  │ Secondary    │  │ Bidirectional│       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Custom Schema Registry (DocumentDB/GraphQL)                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Git Repo     │  │ CI/CD        │  │ S3 Storage   │       │ │
│  │  │ (Source)     │  │ (Validation) │  │ (Versioned)  │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Unified Schema Catalog                                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Schema       │  │ Lineage      │  │ Impact       │       │ │
│  │  │ Metadata     │  │ Tracking     │  │ Analysis     │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Confluent Schema Registry (Avro/Kafka)**:

**Deployment**:
- **Primary**: us-east-1 (read/write)
- **Secondary**: us-west-2 (read-only during normal operation)
- **Replication**: Bidirectional for disaster recovery
- **High Availability**: 3 instances per region (across AZs)

**Schema Subjects**:
- **Naming Convention**: `<topic-name>-key` and `<topic-name>-value`
- **Example**: `flight-event-aa-aircraft-avro-value`
- **Total Subjects**: 100+ (50+ topics × 2 subjects per topic)

**Compatibility Modes**:
- **BACKWARD** (default): New schema can read data written with old schema
- **FORWARD**: Old schema can read data written with new schema
- **FULL**: Both backward and forward compatible
- **NONE**: No compatibility checks (use with caution)

**Schema Evolution Rules**:
- **Backward Compatible Changes** (allowed):
  - Add optional fields with defaults
  - Remove optional fields
  - Widen field types (int → long)
- **Breaking Changes** (requires new topic):
  - Remove required fields
  - Change field types (incompatible)
  - Rename fields


**Custom Schema Registry (DocumentDB/GraphQL)**:

**Git-Based Schema Management**:
- **Repository**: `nxop-schemas` (version controlled)
- **Structure**:
  ```
  /schemas
    /documentdb
      /flight
        FlightIdentity.json
        FlightTimes.json
        ...
      /aircraft
        AircraftIdentity.json
        ...
    /graphql
      /flight
        flight.graphql
      /aircraft
        aircraft.graphql
  ```
- **Versioning**: Git tags for schema versions (v1.0.0, v1.1.0, etc.)
- **CI/CD Integration**: Automated validation on pull requests

**Schema Validation Pipeline**:
1. Developer proposes schema change via pull request
2. CI/CD pipeline validates schema syntax and structure
3. Impact analysis identifies affected collections/queries
4. Automated tests verify backward compatibility
5. Data Steward reviews and approves
6. Schema merged and deployed to S3
7. Applications updated to use new schema version

**S3 Schema Storage**:
- **Bucket**: `nxop-schemas-<region>`
- **Structure**: `<domain>/<entity>/<version>/schema.json`
- **Versioning**: S3 versioning enabled
- **Access Control**: Read-only for applications, write for CI/CD

**GraphQL Schema Federation**:
- **Technology**: Apollo Federation
- **Subgraphs**: One per domain (Flight, Aircraft, Station, Maintenance, ADL)
- **Gateway**: Apollo Gateway aggregating all subgraphs
- **Schema Composition**: Automated via Apollo Studio

**Unified Schema Catalog**:

**Schema Metadata**:
- Schema name and version
- Technology (Avro, DocumentDB, GraphQL)
- Domain and entity
- Owner (Data Steward)
- Creation and modification timestamps
- Compatibility mode
- Deprecation status

**Lineage Tracking**:
- Source systems producing data
- NXOP components processing data
- Destination systems consuming data
- Message flows using schema
- Transformations applied

**Impact Analysis**:
- Affected message flows (out of 25 total)
- Affected producers and consumers
- Affected collections and queries
- Estimated migration effort
- Risk assessment

**Schema Governance Workflow**:

**New Schema Creation**:
1. Data Steward defines logical data model
2. Developer creates physical schema (Avro/DocumentDB/GraphQL)
3. Schema submitted via pull request
4. CI/CD validates syntax and structure
5. Impact analysis performed
6. Governance Council approves (if cross-domain)
7. Schema registered and deployed

**Schema Evolution**:
1. Developer proposes schema change
2. Compatibility check performed
3. Impact analysis identifies affected flows
4. Automated tests verify compatibility
5. Data Steward approves
6. Schema version incremented
7. Consumers migrated gradually

**Schema Deprecation**:
1. Deprecation notice published (90 days advance)
2. Consumers notified via email and dashboard
3. Migration guide provided
4. Monitoring tracks consumer migration
5. Schema removed after all consumers migrated

**Monitoring and Alerting**:
- Schema registration failures
- Compatibility violations
- Deprecated schema usage
- Schema version mismatches
- Impact analysis errors


### 8. Data Catalog System

**Purpose**: Centralized metadata repository documenting all data assets, lineage, and relationships across NXOP.

**Data Catalog Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Data Catalog System                                                 │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Asset Discovery Layer                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ MSK Topics   │  │ DocumentDB   │  │ S3 Buckets   │       │ │
│  │  │ Crawler      │  │ Crawler      │  │ Crawler      │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Metadata Management Layer                                    │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Technical    │  │ Business     │  │ Operational  │       │ │
│  │  │ Metadata     │  │ Metadata     │  │ Metadata     │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Lineage Tracking Layer                                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Data Flow    │  │ Message Flow │  │ Transformation│       │ │
│  │  │ Lineage      │  │ Lineage      │  │ Lineage       │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Search and Discovery Layer                                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Full-Text    │  │ Faceted      │  │ Relationship │       │ │
│  │  │ Search       │  │ Search       │  │ Navigation   │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Asset Discovery**:

**MSK Topics Crawler**:
- **Discovery Method**: MSK Admin API
- **Metadata Captured**: Topic name, partition count, retention, replication factor, producers, consumers
- **Crawl Frequency**: Hourly
- **Schema Integration**: Links to Confluent Schema Registry

**DocumentDB Collections Crawler**:
- **Discovery Method**: DocumentDB Admin API
- **Metadata Captured**: Collection name, document count, indexes, size, access patterns
- **Crawl Frequency**: Daily
- **Schema Integration**: Links to custom schema registry (S3)

**S3 Buckets Crawler**:
- **Discovery Method**: S3 API
- **Metadata Captured**: Bucket name, object count, size, storage class, lifecycle policies
- **Crawl Frequency**: Daily
- **Schema Integration**: Links to Iceberg table schemas

**Metadata Management**:

**Technical Metadata**:
- Data type and format
- Schema version
- Storage location
- Partition strategy
- Compression codec
- Encryption status

**Business Metadata**:
- Business name and description
- Data domain (Flight, Aircraft, Station, Maintenance, ADL)
- Data owner (Data Steward)
- Business glossary terms
- Data classification (Public, Internal, Confidential, Restricted)
- Compliance tags (PII, PCI, GDPR)

**Operational Metadata**:
- Creation and modification timestamps
- Last access timestamp
- Access frequency
- Data quality scores
- SLA requirements
- Monitoring dashboards


**Lineage Tracking**:

**Data Flow Lineage**:
- **Source Systems**: Flightkeys, FOS, CyberJet FMS, FXIP, OpsHub
- **NXOP Components**: MSK, DocumentDB, S3, EKS services
- **Destination Systems**: Flightkeys, FOS, CyberJet, FXIP, OpsHub
- **Lineage Graph**: Directed acyclic graph (DAG) showing data flow

**Message Flow Lineage**:
- **Flow ID**: Unique identifier for each of 25 message flows
- **Integration Pattern**: One of 7 patterns
- **Source → NXOP → Destination**: Complete flow path
- **Dependencies**: Infrastructure dependencies (MSK, DocumentDB, Pod Identity)

**Transformation Lineage**:
- **Transformation Type**: Enrichment, filtering, aggregation, format conversion
- **Transformation Logic**: Code references and business rules
- **Input/Output Schemas**: Schema versions before and after transformation
- **Data Quality Impact**: Quality metrics before and after transformation

**Search and Discovery**:

**Full-Text Search**:
- **Search Engine**: OpenSearch (AWS)
- **Indexed Fields**: Asset name, description, business glossary terms, tags
- **Search Features**: Autocomplete, fuzzy matching, relevance ranking
- **Search Filters**: Domain, data type, owner, classification

**Faceted Search**:
- **Facets**: Domain, data type, owner, classification, compliance tags
- **Drill-Down**: Multi-level facet navigation
- **Facet Counts**: Number of assets per facet value

**Relationship Navigation**:
- **Upstream Dependencies**: Data sources feeding this asset
- **Downstream Dependencies**: Data consumers using this asset
- **Cross-Domain Relationships**: Relationships across domains (e.g., Flight → Aircraft)
- **Message Flow Relationships**: Assets used in specific message flows

**Data Catalog Integration**:

**Schema Registry Integration**:
- Catalog links to schema versions in Confluent Schema Registry and S3
- Schema changes automatically update catalog metadata
- Catalog displays schema evolution history

**Data Quality Integration**:
- Catalog displays data quality scores and trends
- Quality rules linked to catalog assets
- Quality incidents tracked in catalog

**Monitoring Integration**:
- Catalog links to CloudWatch dashboards for each asset
- Operational metrics displayed in catalog
- Alerting status visible in catalog

**Governance Policies**:
- **Asset Registration**: Automated via crawlers, manual for external assets
- **Metadata Updates**: Automated for technical metadata, manual for business metadata
- **Access Control**: Role-based access control (RBAC) for catalog access
- **Data Classification**: Required for all assets, enforced via policy
- **Compliance Tagging**: Required for PII/PCI/GDPR data, enforced via policy

**Monitoring and Alerting**:
- Crawler failures
- Metadata staleness (> 7 days)
- Missing business metadata
- Missing data classification
- Lineage gaps


### 9. Data Quality Framework

**Purpose**: Ensure data quality, consistency, and compliance across all 25 message flows and 5 data domains.

**Data Quality Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Data Quality Framework                                              │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Validation Layer                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Schema       │  │ Business     │  │ Referential  │       │ │
│  │  │ Validation   │  │ Rule         │  │ Integrity    │       │ │
│  │  │              │  │ Validation   │  │ Validation   │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Monitoring Layer                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Completeness │  │ Accuracy     │  │ Consistency  │       │ │
│  │  │ Metrics      │  │ Metrics      │  │ Metrics      │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Alerting Layer                                               │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Threshold    │  │ Anomaly      │  │ Trend        │       │ │
│  │  │ Alerts       │  │ Detection    │  │ Alerts       │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Remediation Layer                                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Auto-Correct │  │ Quarantine   │  │ Manual       │       │ │
│  │  │              │  │              │  │ Review       │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Validation Rules**:

**Schema Validation**:
- **Avro Schemas**: Enforced by Confluent Schema Registry at produce time
- **DocumentDB Schemas**: Enforced at application layer (EKS pods)
- **GraphQL Schemas**: Enforced by Apollo Gateway at query time
- **Validation Failures**: Rejected with error message, logged for analysis

**Business Rule Validation**:

**Flight Domain Rules**:
- flightKey must be unique per flight per day
- departureTime must be before arrivalTime
- Scheduled times must be before Estimated times
- Actual times must be after Scheduled times
- Aircraft tailNumber must exist in Aircraft domain

**Aircraft Domain Rules**:
- noseNumber must be unique per aircraft
- emptyOperatingWeight must be > 0
- maximumFuelCapacity must be > 0
- MEL items must have valid ATASystemID

**Station Domain Rules**:
- icaoAirportID must be unique per station
- latitude must be between -90 and 90
- longitude must be between -180 and 180
- elevation must be >= 0

**Maintenance Domain Rules**:
- trackingID must be unique per maintenance event
- tailNumber must exist in Aircraft domain
- effectiveTime must be <= current time

**ADL Domain Rules**:
- adlID must be unique per ADL record
- FlightKey must exist in Flight domain

**Referential Integrity Validation**:
- Flight.tailNumber → Aircraft.noseNumber
- Flight.departureStation → Station.icaoAirportID
- Flight.arrivalStation → Station.icaoAirportID
- Maintenance.tailNumber → Aircraft.noseNumber
- ADL.FlightKey → Flight.flightKey


**Data Quality Dimensions**:

**Completeness**:
- **Metric**: Percentage of required fields populated
- **Target**: 99% for critical fields, 95% for optional fields
- **Measurement**: Per message flow, per domain, per entity
- **Alerting**: Alert if completeness < target for 3 consecutive measurements

**Accuracy**:
- **Metric**: Percentage of values matching expected format/range
- **Target**: 99.5% for operational data
- **Measurement**: Per field, per domain
- **Alerting**: Alert if accuracy < target for 3 consecutive measurements

**Consistency**:
- **Metric**: Percentage of cross-domain references valid
- **Target**: 99.9% for referential integrity
- **Measurement**: Per relationship, per domain pair
- **Alerting**: Alert if consistency < target immediately

**Timeliness**:
- **Metric**: Time from event occurrence to data availability
- **Target**: < 5 seconds for real-time flows, < 1 minute for batch flows
- **Measurement**: Per message flow
- **Alerting**: Alert if timeliness > target for 5 consecutive measurements

**Uniqueness**:
- **Metric**: Percentage of duplicate records
- **Target**: 0% for unique identifiers (flightKey, noseNumber, etc.)
- **Measurement**: Per entity, per domain
- **Alerting**: Alert if duplicates detected immediately

**Validity**:
- **Metric**: Percentage of values conforming to business rules
- **Target**: 99% for business rules
- **Measurement**: Per rule, per domain
- **Alerting**: Alert if validity < target for 3 consecutive measurements

**Monitoring and Alerting**:

**CloudWatch Metrics**:
- `DataQuality/Completeness/<Domain>/<Entity>/<Field>`
- `DataQuality/Accuracy/<Domain>/<Entity>/<Field>`
- `DataQuality/Consistency/<Domain>/<Relationship>`
- `DataQuality/Timeliness/<MessageFlow>`
- `DataQuality/Uniqueness/<Domain>/<Entity>`
- `DataQuality/Validity/<Domain>/<Rule>`

**Composite Alarms**:
- **Critical Data Quality**: Completeness < 95% OR Accuracy < 95% OR Consistency < 99%
- **Warning Data Quality**: Completeness < 99% OR Accuracy < 99.5% OR Timeliness > target

**Alerting Channels**:
- **Critical**: PagerDuty (24/7 on-call)
- **Warning**: Slack channel (#nxop-data-quality)
- **Info**: Email to Data Stewards

**Remediation Strategies**:

**Auto-Correct**:
- **Applicable**: Minor formatting issues (trim whitespace, case normalization)
- **Process**: Automated correction at ingestion time
- **Logging**: All corrections logged for audit

**Quarantine**:
- **Applicable**: Data failing validation but not critical
- **Process**: Data moved to quarantine queue for manual review
- **SLA**: Review within 4 hours for critical flows, 24 hours for non-critical

**Manual Review**:
- **Applicable**: Complex validation failures requiring human judgment
- **Process**: Data Steward reviews and approves/rejects
- **SLA**: Review within 1 hour for critical flows, 8 hours for non-critical

**Reject**:
- **Applicable**: Data failing critical validation rules
- **Process**: Data rejected immediately, producer notified
- **Logging**: All rejections logged with reason

**Data Quality Dashboard**:
- **Overall Score**: Weighted average of all quality dimensions
- **Domain Scores**: Quality score per domain (Flight, Aircraft, Station, Maintenance, ADL)
- **Message Flow Scores**: Quality score per message flow (25 flows)
- **Trend Analysis**: Quality trends over time (daily, weekly, monthly)
- **Top Issues**: Most frequent validation failures
- **Remediation Status**: Quarantine queue size, manual review backlog


### 10. Multi-Region Resilience Design

**Purpose**: Ensure NXOP platform resilience with < 10 min RTO for regional failover and < 1 minute RTO for DocumentDB failover.

**Resilience Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Multi-Region Resilience Architecture                                │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Health Monitoring Layer (Continuous)                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ MSK Health   │  │ DocumentDB   │  │ EKS Health   │       │ │
│  │  │ Checks       │  │ Health       │  │ Checks       │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Failover Orchestration Layer                                 │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ Route53 DNS  │  │ Akamai GTM   │  │ ARC Control  │       │ │
│  │  │ Failover     │  │ Failover     │  │ Plane        │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Application Recovery Layer                                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │ AMQP         │  │ Kafka        │  │ EKS Pod      │       │ │
│  │  │ Reconnect    │  │ Consumer     │  │ Restart      │       │ │
│  │  │              │  │ Rebalance    │  │              │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Health Monitoring (Phase 0 - Continuous)**:

**L1 - Component Health**:
- **MSK Brokers**: Broker availability, CPU, memory, disk
- **DocumentDB Instances**: Instance availability, CPU, memory, connections
- **EKS Nodes**: Node availability, CPU, memory, pod count
- **S3**: Bucket availability, request rate, error rate
- **Network**: NLB health, VPC connectivity, DNS resolution

**L2 - Service Health**:
- **MSK Topics**: Topic availability, partition health, replication lag
- **DocumentDB Collections**: Collection availability, query performance
- **EKS Pods**: Pod availability, container health, restart count
- **Kafka Consumers**: Consumer lag, rebalance frequency

**L3 - Integration Health**:
- **Message Flows**: End-to-end latency, throughput, error rate
- **Cross-Account IAM**: AssumeRole success rate, permission errors
- **AMQP Connections**: Connection health, message delivery rate
- **HTTPS APIs**: API availability, response time, error rate

**L4 - Business Health**:
- **Flight Operations**: Flight event processing rate, flight data completeness
- **Aircraft Operations**: Aircraft event processing rate, aircraft data accuracy
- **Maintenance Operations**: Maintenance event processing rate
- **Data Quality**: Overall quality score, validation failure rate

**Composite Health Score**:
- **Formula**: Weighted average of L1-L4 scores
- **Weights**: L1 (30%), L2 (30%), L3 (25%), L4 (15%)
- **Threshold**: 90%+ required for healthy region
- **Measurement**: Every 30 seconds


**Failover Orchestration**:

**Phase 1 - Infrastructure Isolation (Concurrent)**:

**MSK Failover** (< 5 min):
1. **Route53 DNS Update**: kafka.nxop.com → nxop-msk-nlb-west.internal
2. **DNS Propagation**: 60 second TTL ensures fast propagation
3. **Producer/Consumer Reconnect**: Automatic reconnection to new brokers
4. **Consumer Group Rebalance**: Automatic rebalancing to new brokers
5. **Validation**: Verify message production and consumption in us-west-2

**DocumentDB Failover** (< 1 min):
1. **Automatic Promotion**: Secondary (us-west-2) promoted to primary
2. **Connection String Update**: Applications reconnect to new primary
3. **Replication Lag Check**: Verify replication lag < 1 second before promotion
4. **Validation**: Verify read/write operations in us-west-2

**Phase 2 - Application Failover (Concurrent with Phase 1)**:

**Akamai GTM Failover** (< 2 min):
1. **Health Check Failure**: Akamai detects us-east-1 API unavailability
2. **Traffic Routing**: Akamai routes traffic to us-west-2 endpoints
3. **DNS Propagation**: Fast propagation due to low TTL
4. **Validation**: Verify API requests routed to us-west-2

**AMQP Listener Reconnect** (< 3 min):
1. **Connection Failure Detection**: EKS pods detect AMQP connection loss
2. **Automatic Reconnection**: Pods reconnect to Flightkeys AMQP
3. **Message Consumption Resume**: Pods resume consuming messages
4. **Validation**: Verify message consumption in us-west-2

**Kafka Connector Reconnect** (< 3 min):
1. **Connection Failure Detection**: Azure Kafka Connector detects MSK unavailability
2. **Automatic Reconnection**: Connector reconnects via Route53 DNS
3. **Message Consumption Resume**: Connector resumes consuming from MSK
4. **Validation**: Verify messages flowing to OpsHub Event Hubs

**Phase 3 - Post-Failover Validation** (< 2 min):

**L1-L4 Health Checks**:
1. Verify all L1 component health checks pass in us-west-2
2. Verify all L2 service health checks pass in us-west-2
3. Verify all L3 integration health checks pass in us-west-2
4. Verify all L4 business health checks pass in us-west-2
5. Verify composite health score > 90% in us-west-2

**Message Flow Validation**:
1. Verify all 25 message flows operational in us-west-2
2. Verify end-to-end latency within SLA
3. Verify data quality metrics within target
4. Verify no message loss during failover

**Total Failover Time**: < 10 minutes (Phase 1 + Phase 2 + Phase 3 concurrent execution)

**Rollback Procedures**:

**Automatic Rollback Triggers**:
- Composite health score < 80% in us-west-2 after failover
- Message loss detected during failover
- Data corruption detected in us-west-2
- Critical message flows unavailable in us-west-2

**Rollback Process**:
1. **Immediate**: Revert Route53 DNS to us-east-1
2. **Immediate**: Revert Akamai GTM to us-east-1
3. **Wait**: Allow AMQP/Kafka reconnections to complete (< 3 min)
4. **Validate**: Verify all message flows operational in us-east-1
5. **Investigate**: Root cause analysis of failover failure

**Manual Rollback**:
- Initiated by incident commander
- Requires approval from NXOP Platform Lead
- Follows same process as automatic rollback

**Failover Testing**:

**Chaos Engineering**:
- **Monthly**: Simulate MSK broker failures
- **Quarterly**: Simulate DocumentDB instance failures
- **Bi-Annually**: Full regional failover drill
- **Annually**: Multi-component failure simulation

**Failover Metrics**:
- **RTO Actual**: Measured time from failure detection to full recovery
- **RPO Actual**: Measured data loss during failover
- **Success Rate**: Percentage of successful failovers
- **Rollback Rate**: Percentage of failovers requiring rollback

**Governance Policies**:
- **Failover Authority**: Incident commander with NXOP Platform Lead approval
- **Failover Criteria**: Composite health score < 70% in primary region for > 5 minutes
- **Rollback Authority**: Incident commander (immediate), NXOP Platform Lead (post-incident)
- **Post-Incident Review**: Required for all failovers within 24 hours


## Correctness Properties

**Purpose**: Define executable correctness properties for property-based testing to validate NXOP data governance implementation.

### Property 1: Schema Compatibility Preservation

**Validates**: Requirements 7.2, 7.6, 7.12

**Property Statement**: For all schema evolution operations, if a schema change is classified as backward-compatible, then all existing consumers can successfully deserialize messages produced with the new schema.

**Property-Based Test**:
```python
@given(
    old_schema=avro_schema_strategy(),
    new_schema=backward_compatible_schema_strategy(old_schema),
    message=message_strategy(old_schema)
)
def test_backward_compatibility_preserved(old_schema, new_schema, message):
    # Serialize message with old schema
    serialized = serialize(message, old_schema)
    
    # Deserialize with new schema
    deserialized = deserialize(serialized, new_schema)
    
    # Assert all fields from old schema are present
    assert all(field in deserialized for field in message.keys())
```

### Property 2: Cross-Domain Referential Integrity

**Validates**: Requirements 3.2, 3.4, 9.4

**Property Statement**: For all flight records, if a flight references an aircraft tailNumber, then that aircraft must exist in the Aircraft domain with matching noseNumber.

**Property-Based Test**:
```python
@given(
    flight=flight_record_strategy(),
    aircraft_db=aircraft_database_strategy()
)
def test_flight_aircraft_referential_integrity(flight, aircraft_db):
    if flight.tailNumber is not None:
        # Assert aircraft exists
        assert aircraft_db.exists(noseNumber=flight.tailNumber)
        
        # Assert aircraft data is consistent
        aircraft = aircraft_db.get(noseNumber=flight.tailNumber)
        assert aircraft.noseNumber == flight.tailNumber
```

### Property 3: Message Flow End-to-End Latency

**Validates**: Requirements 2.8, 5.8

**Property Statement**: For all message flows classified as "Vital" or "Critical", the end-to-end latency from source to destination must be < 5 seconds for 99% of messages.

**Property-Based Test**:
```python
@given(
    message_flow=critical_message_flow_strategy(),
    messages=st.lists(message_strategy(), min_size=100, max_size=1000)
)
def test_message_flow_latency_sla(message_flow, messages):
    latencies = []
    
    for message in messages:
        start_time = time.time()
        message_flow.send(message)
        message_flow.receive()
        end_time = time.time()
        latencies.append(end_time - start_time)
    
    # Assert 99th percentile latency < 5 seconds
    p99_latency = np.percentile(latencies, 99)
    assert p99_latency < 5.0
```


### Property 4: Pod Identity Cross-Account Access

**Validates**: Requirements 4.2, 4.3, 4.6

**Property Statement**: For all EKS pods with Pod Identity annotations, the pod can successfully assume the NXOP account role and access NXOP resources without static credentials.

**Property-Based Test**:
```python
@given(
    pod_identity=pod_identity_strategy(),
    nxop_resource=nxop_resource_strategy()
)
def test_pod_identity_cross_account_access(pod_identity, nxop_resource):
    # Assume NXOP account role
    credentials = pod_identity.assume_role()
    
    # Assert credentials are temporary (no static credentials)
    assert credentials.is_temporary()
    assert credentials.expiration > time.time()
    
    # Access NXOP resource
    result = nxop_resource.access(credentials)
    
    # Assert access successful
    assert result.success
```

### Property 5: Multi-Region Data Consistency

**Validates**: Requirements 5.8, 6.7, 10

**Property Statement**: For all data written to the primary region, the data must be replicated to the secondary region within 1 second with identical content.

**Property-Based Test**:
```python
@given(
    data=data_record_strategy(),
    primary_region="us-east-1",
    secondary_region="us-west-2"
)
def test_multi_region_data_consistency(data, primary_region, secondary_region):
    # Write to primary region
    primary_db = get_database(primary_region)
    write_time = time.time()
    primary_db.write(data)
    
    # Wait for replication (max 1 second)
    time.sleep(1.1)
    
    # Read from secondary region
    secondary_db = get_database(secondary_region)
    replicated_data = secondary_db.read(data.id)
    
    # Assert data is identical
    assert replicated_data == data
    
    # Assert replication lag < 1 second
    replication_lag = secondary_db.get_replication_lag()
    assert replication_lag < 1.0
```

### Property 6: Data Quality Validation Rules

**Validates**: Requirements 9.1, 9.2, 9.3

**Property Statement**: For all data ingested into NXOP, if the data fails validation rules, it must be rejected or quarantined with a clear error message.

**Property-Based Test**:
```python
@given(
    data=invalid_data_strategy(),
    validation_rules=validation_rules_strategy()
)
def test_data_quality_validation_enforcement(data, validation_rules):
    # Attempt to ingest invalid data
    result = ingest_data(data, validation_rules)
    
    # Assert data is rejected or quarantined
    assert result.status in ["rejected", "quarantined"]
    
    # Assert error message is clear
    assert result.error_message is not None
    assert len(result.error_message) > 0
    
    # Assert validation rule that failed is identified
    assert result.failed_rule in validation_rules
```

### Property 7: Schema Registry Compatibility Enforcement

**Validates**: Requirements 7.2, 7.6, 7.11

**Property Statement**: For all schema registration attempts, if the new schema is incompatible with the existing schema, the registration must be rejected.

**Property-Based Test**:
```python
@given(
    existing_schema=avro_schema_strategy(),
    incompatible_schema=incompatible_schema_strategy(existing_schema)
)
def test_schema_registry_compatibility_enforcement(existing_schema, incompatible_schema):
    # Register existing schema
    schema_registry.register(existing_schema)
    
    # Attempt to register incompatible schema
    result = schema_registry.register(incompatible_schema)
    
    # Assert registration is rejected
    assert result.status == "rejected"
    
    # Assert compatibility error is reported
    assert "compatibility" in result.error_message.lower()
```

### Property 8: Message Flow Dependency Tracking

**Validates**: Requirements 2.3, 2.4, 2.7

**Property Statement**: For all message flows, the Data Catalog must accurately track all source systems, NXOP components, and destination systems involved in the flow.

**Property-Based Test**:
```python
@given(
    message_flow=message_flow_strategy()
)
def test_message_flow_dependency_tracking(message_flow):
    # Get dependencies from Data Catalog
    catalog_dependencies = data_catalog.get_dependencies(message_flow.id)
    
    # Get actual dependencies from message flow execution
    actual_dependencies = message_flow.execute_and_track_dependencies()
    
    # Assert all actual dependencies are tracked in catalog
    assert set(actual_dependencies.sources) == set(catalog_dependencies.sources)
    assert set(actual_dependencies.nxop_components) == set(catalog_dependencies.nxop_components)
    assert set(actual_dependencies.destinations) == set(catalog_dependencies.destinations)
```

### Property 9: Governance Council Approval Workflow

**Validates**: Requirements 1.4, 3.7, 7.11

**Property Statement**: For all schema changes affecting 3+ message flows, the change must be approved by the Governance Council before deployment.

**Property-Based Test**:
```python
@given(
    schema_change=schema_change_strategy(),
    affected_flows=st.lists(message_flow_strategy(), min_size=3, max_size=10)
)
def test_governance_council_approval_required(schema_change, affected_flows):
    # Attempt to deploy schema change without approval
    result = deploy_schema_change(schema_change, approval=None)
    
    # Assert deployment is blocked
    assert result.status == "blocked"
    assert "governance council approval required" in result.message.lower()
    
    # Get approval from Governance Council
    approval = governance_council.approve(schema_change, affected_flows)
    
    # Attempt to deploy with approval
    result = deploy_schema_change(schema_change, approval=approval)
    
    # Assert deployment is successful
    assert result.status == "success"
```

### Property 10: Multi-Region Failover RTO

**Validates**: Requirements 5.8, 6.7, 10

**Property Statement**: For all regional failover scenarios, the total failover time from failure detection to full recovery must be < 10 minutes.

**Property-Based Test**:
```python
@given(
    failure_scenario=regional_failure_strategy()
)
def test_multi_region_failover_rto(failure_scenario):
    # Simulate regional failure
    start_time = time.time()
    failure_scenario.trigger()
    
    # Wait for automatic failover
    failover_complete = wait_for_failover_complete(timeout=600)  # 10 minutes
    end_time = time.time()
    
    # Assert failover completed successfully
    assert failover_complete
    
    # Assert RTO < 10 minutes
    rto = end_time - start_time
    assert rto < 600
    
    # Assert all message flows operational in secondary region
    for flow_id in range(1, 26):
        assert message_flow_operational(flow_id, region="us-west-2")
```


## Error Handling

**Purpose**: Define error handling strategies for common failure scenarios across NXOP data governance.

### Schema Validation Errors

**Scenario**: Producer attempts to publish message with invalid schema

**Error Handling**:
1. **Detection**: Confluent Schema Registry rejects message at produce time
2. **Response**: Producer receives error with schema validation details
3. **Logging**: Error logged to CloudWatch with schema ID, message ID, validation error
4. **Alerting**: Alert sent to #nxop-schema-errors Slack channel
5. **Remediation**: Producer fixes schema and retries

**Retry Strategy**: No retry (schema must be fixed first)

### Cross-Account IAM Errors

**Scenario**: EKS pod fails to assume NXOP account role

**Error Handling**:
1. **Detection**: AssumeRole API call returns AccessDenied error
2. **Response**: Pod logs error and enters crash loop backoff
3. **Logging**: Error logged to CloudWatch with pod identity, role ARN, error details
4. **Alerting**: PagerDuty alert sent to on-call engineer (critical)
5. **Remediation**: Verify trust policy, verify Pod Identity annotation, verify IAM role exists

**Retry Strategy**: Exponential backoff (1s, 2s, 4s, 8s, 16s, max 60s)

### DocumentDB Connection Errors

**Scenario**: Application fails to connect to DocumentDB

**Error Handling**:
1. **Detection**: Connection timeout or connection refused error
2. **Response**: Application retries with exponential backoff
3. **Logging**: Error logged to CloudWatch with connection string, error details
4. **Alerting**: Alert sent to #nxop-database-errors Slack channel after 3 consecutive failures
5. **Remediation**: Verify DocumentDB cluster health, verify network connectivity, verify credentials

**Retry Strategy**: Exponential backoff with jitter (1s, 2s, 4s, 8s, 16s, max 60s)

### MSK Broker Failures

**Scenario**: MSK broker becomes unavailable

**Error Handling**:
1. **Detection**: Producer/Consumer receives broker unavailable error
2. **Response**: Producer/Consumer automatically reconnects to healthy broker
3. **Logging**: Error logged to CloudWatch with broker ID, error details
4. **Alerting**: Alert sent to #nxop-kafka-errors Slack channel
5. **Remediation**: MSK automatically replaces failed broker

**Retry Strategy**: Automatic reconnection by Kafka client library

### Data Quality Validation Failures

**Scenario**: Ingested data fails business rule validation

**Error Handling**:
1. **Detection**: Validation rule engine detects violation
2. **Response**: Data quarantined for manual review
3. **Logging**: Error logged to CloudWatch with data ID, validation rule, error details
4. **Alerting**: Alert sent to Data Steward via email
5. **Remediation**: Data Steward reviews and approves/rejects data

**Retry Strategy**: No retry (manual review required)

### Regional Failover Failures

**Scenario**: Automatic regional failover fails

**Error Handling**:
1. **Detection**: Post-failover validation detects health score < 80%
2. **Response**: Automatic rollback to primary region
3. **Logging**: Error logged to CloudWatch with failover details, health scores
4. **Alerting**: PagerDuty alert sent to incident commander (critical)
5. **Remediation**: Root cause analysis, manual failover if necessary

**Retry Strategy**: No automatic retry (manual intervention required)


## Testing Strategy

**Purpose**: Define comprehensive testing strategy including property-based tests, unit tests, and integration tests.

### Property-Based Testing

**Framework**: Hypothesis (Python)

**Test Coverage**:
- 10 correctness properties defined above
- 100+ test cases generated per property
- Shrinking enabled for minimal failing examples

**Execution**:
- Run on every pull request (CI/CD)
- Run nightly with extended test cases (1000+ per property)
- Run weekly with chaos engineering scenarios

**Failure Handling**:
- Failing test blocks pull request merge
- Failing example logged for analysis
- Root cause analysis required before retry


### Unit Testing

**Framework**: pytest (Python), JUnit (Java)

**Test Coverage**:
- Schema validation logic (100% coverage)
- Business rule validation logic (100% coverage)
- Data transformation logic (100% coverage)
- Error handling logic (100% coverage)

**Test Organization**:
- Tests co-located with source code (`test_*.py` files)
- Test fixtures for common test data
- Mocking for external dependencies (MSK, DocumentDB, S3)

**Execution**:
- Run on every pull request (CI/CD)
- Run on every commit to main branch
- Coverage report generated and published

### Integration Testing

**Framework**: pytest (Python), Testcontainers (Docker)

**Test Scenarios**:
- End-to-end message flow testing (all 25 flows)
- Cross-account IAM testing (Pod Identity)
- Multi-region replication testing (MSK, DocumentDB)
- Schema evolution testing (backward/forward compatibility)
- Data quality validation testing (all validation rules)

**Test Environment**:
- Dedicated test environment (AWS account)
- Testcontainers for local testing (MSK, DocumentDB, S3)
- Mock external systems (Flightkeys, FOS, CyberJet)

**Execution**:
- Run on every pull request (CI/CD)
- Run nightly with full test suite
- Run weekly with chaos engineering scenarios

### Chaos Engineering

**Framework**: AWS Fault Injection Simulator (FIS)

**Chaos Experiments**:
- **MSK Broker Failure**: Terminate random MSK broker
- **DocumentDB Instance Failure**: Terminate random DocumentDB instance
- **EKS Node Failure**: Terminate random EKS node
- **Network Partition**: Simulate network partition between regions
- **Cross-Account IAM Failure**: Simulate AssumeRole failures
- **Regional Failover**: Simulate complete regional failure

**Execution**:
- Run monthly for individual component failures
- Run quarterly for multi-component failures
- Run bi-annually for full regional failover

**Success Criteria**:
- RTO < 10 minutes for regional failover
- RPO < 1 minute for data loss
- All message flows operational after recovery
- No data corruption detected

### Performance Testing

**Framework**: Locust (Python), JMeter (Java)

**Test Scenarios**:
- **Load Testing**: Simulate normal operational load (1000 msg/sec)
- **Stress Testing**: Simulate peak load (5000 msg/sec)
- **Spike Testing**: Simulate sudden traffic spike (10000 msg/sec)
- **Endurance Testing**: Simulate sustained load for 24 hours

**Metrics**:
- Message throughput (messages/second)
- End-to-end latency (p50, p95, p99)
- Error rate (errors/second)
- Resource utilization (CPU, memory, disk, network)

**Execution**:
- Run weekly for load testing
- Run monthly for stress/spike testing
- Run quarterly for endurance testing

### Security Testing

**Framework**: AWS Security Hub, Prowler

**Test Scenarios**:
- **IAM Policy Testing**: Verify least-privilege access
- **Encryption Testing**: Verify data encryption at rest and in transit
- **Network Security Testing**: Verify security group rules
- **Compliance Testing**: Verify GDPR, PCI, SOC2 compliance

**Execution**:
- Run on every pull request (CI/CD)
- Run daily with full security scan
- Run quarterly with penetration testing


## Risk Management

**Purpose**: Identify and mitigate risks to NXOP data governance implementation.

### Risk Register

**Risk 1: Cross-Account IAM Single Point of Failure**

**Description**: All 25 message flows depend on Pod Identity cross-account IAM. Failure of this mechanism causes complete NXOP platform outage.

**Likelihood**: Low (2/5)  
**Impact**: Critical (5/5)  
**Risk Score**: 10/25

**Mitigation**:
- Implement comprehensive monitoring and alerting for AssumeRole failures
- Implement automatic retry with exponential backoff
- Implement fallback mechanism (static credentials in break-glass scenario)
- Conduct monthly chaos engineering tests
- Maintain detailed runbooks for troubleshooting

**Owner**: NXOP Platform Team

---

**Risk 2: Schema Evolution Breaking Changes**

**Description**: Incompatible schema changes could break existing consumers, causing message flow failures.

**Likelihood**: Medium (3/5)  
**Impact**: High (4/5)  
**Risk Score**: 12/25

**Mitigation**:
- Enforce backward compatibility via Confluent Schema Registry
- Implement automated compatibility testing in CI/CD
- Require Governance Council approval for breaking changes
- Implement parallel schema support during transitions
- Maintain schema evolution documentation and training

**Owner**: Data Stewards

---

**Risk 3: Multi-Region Failover Complexity**

**Description**: Regional failover involves multiple components (MSK, DocumentDB, Akamai, Route53) with complex orchestration. Failure could result in extended outage.

**Likelihood**: Medium (3/5)  
**Impact**: Critical (5/5)  
**Risk Score**: 15/25

**Mitigation**:
- Implement continuous health monitoring (Phase 0)
- Implement concurrent failover execution (Phase 1 + Phase 2)
- Implement automatic rollback on failure
- Conduct bi-annual full regional failover drills
- Maintain detailed runbooks and automation scripts

**Owner**: NXOP Platform Team

---

**Risk 4: Data Quality Degradation**

**Description**: Poor data quality could impact operational decision-making and compliance.

**Likelihood**: Medium (3/5)  
**Impact**: High (4/5)  
**Risk Score**: 12/25

**Mitigation**:
- Implement comprehensive data quality validation rules
- Implement real-time data quality monitoring and alerting
- Implement quarantine mechanism for invalid data
- Conduct monthly data quality reviews with Data Stewards
- Maintain data quality dashboard and reports

**Owner**: Data Stewards

---

**Risk 5: FOS Vendor Integration Delays**

**Description**: Delays in FOS vendor integrations could impact NXOP strategic evolution timeline.

**Likelihood**: High (4/5)  
**Impact**: Medium (3/5)  
**Risk Score**: 12/25

**Mitigation**:
- Establish clear integration patterns and templates
- Conduct early vendor workshops to align on data models
- Implement phased integration approach (Phase 1, 2, 3)
- Maintain parallel data structure support during transitions
- Establish clear escalation paths for integration issues

**Owner**: Integration Architects

---

**Risk 6: Enterprise Data Alignment Conflicts**

**Description**: Conflicts between NXOP and Enterprise data models could delay convergence efforts.

**Likelihood**: Medium (3/5)  
**Impact**: Medium (3/5)  
**Risk Score**: 9/25

**Mitigation**:
- Establish Governance Council with Enterprise representation
- Conduct quarterly alignment reviews with Todd Waller's team
- Implement semantic mapping layer for model differences
- Maintain clear boundaries between NXOP and Enterprise domains
- Establish conflict resolution process

**Owner**: Governance Council

---

**Risk 7: DocumentDB Performance Degradation**

**Description**: High-volume writes and complex queries could degrade DocumentDB performance, impacting message flow latency.

**Likelihood**: Medium (3/5)  
**Impact**: High (4/5)  
**Risk Score**: 12/25

**Mitigation**:
- Implement comprehensive index strategy
- Implement read replicas for read-heavy collections
- Implement connection pooling and query optimization
- Conduct monthly performance testing and capacity planning
- Implement caching layer for frequently accessed data

**Owner**: NXOP Platform Team

---

**Risk 8: MSK Consumer Lag**

**Description**: Consumer lag could cause message processing delays, impacting operational timeliness.

**Likelihood**: Medium (3/5)  
**Impact**: High (4/5)  
**Risk Score**: 12/25

**Mitigation**:
- Implement consumer lag monitoring and alerting
- Implement auto-scaling for consumer groups
- Implement partition rebalancing strategies
- Conduct monthly capacity planning reviews
- Maintain consumer lag runbooks

**Owner**: NXOP Platform Team


## Implementation Roadmap

**Purpose**: Define phased implementation approach for NXOP data governance framework.

### Phase 1: Foundation (Months 1-3)

**Objectives**:
- Establish Governance Council
- Define data governance policies
- Implement Schema Registry (Confluent + Custom)
- Implement Data Catalog (basic)
- Implement Data Quality Framework (basic)

**Deliverables**:
- Governance Council charter and RACI matrix
- Data governance policy documents
- Confluent Schema Registry deployed (us-east-1, us-west-2)
- Custom Schema Registry (Git + S3) deployed
- Data Catalog with asset discovery (MSK, DocumentDB, S3)
- Data Quality validation rules for Flight domain

**Success Criteria**:
- Governance Council meets weekly
- All 50+ MSK topics registered in Confluent Schema Registry
- All 24 DocumentDB collections documented in Data Catalog
- Data Quality validation rules enforced for Flight domain

### Phase 2: Expansion (Months 4-6)

**Objectives**:
- Expand Data Quality Framework to all domains
- Implement Data Lineage tracking
- Implement Multi-Region Resilience (basic)
- Onboard first FOS vendor integration

**Deliverables**:
- Data Quality validation rules for all 5 domains
- Data Lineage tracking for all 25 message flows
- Multi-region health monitoring (Phase 0)
- Regional failover procedures documented
- First FOS vendor integration completed

**Success Criteria**:
- Data Quality score > 95% for all domains
- Data Lineage tracked for all 25 message flows
- Regional failover drill completed successfully (< 10 min RTO)
- First FOS vendor integration operational

### Phase 3: Optimization (Months 7-9)

**Objectives**:
- Optimize Data Quality Framework (auto-correct, quarantine)
- Optimize Multi-Region Resilience (concurrent failover)
- Implement Enterprise Data Alignment
- Onboard additional FOS vendor integrations

**Deliverables**:
- Data Quality auto-correct and quarantine mechanisms
- Concurrent regional failover (Phase 1 + Phase 2)
- Enterprise data alignment for shared domains (Crew, Network)
- Additional FOS vendor integrations completed

**Success Criteria**:
- Data Quality score > 99% for all domains
- Regional failover RTO < 10 minutes (concurrent execution)
- Enterprise data alignment for Crew and Network domains
- 3+ FOS vendor integrations operational

### Phase 4: Maturity (Months 10-12)

**Objectives**:
- Implement advanced Data Catalog features (impact analysis, recommendations)
- Implement Parallel Data Structure Management
- Conduct comprehensive chaos engineering
- Establish steady-state operations

**Deliverables**:
- Data Catalog impact analysis and recommendations
- Parallel data structure support for legacy and new models
- Chaos engineering experiments for all failure modes
- Steady-state operations runbooks

**Success Criteria**:
- Data Catalog used by 100% of development teams
- Parallel data structures operational for 3+ transitions
- Chaos engineering experiments pass with < 10 min RTO
- Governance Council meets monthly (steady-state)

### Phase 5: Continuous Improvement (Months 13-18+)

**Objectives**:
- Continuous optimization based on operational learnings
- Expand FOS vendor integrations (Phase 3)
- Enhance Enterprise data alignment
- Implement advanced analytics and ML for data quality

**Deliverables**:
- Quarterly optimization reviews
- Additional FOS vendor integrations
- Enhanced Enterprise data alignment
- ML-based data quality anomaly detection

**Success Criteria**:
- Data Quality score > 99.5% for all domains
- 5+ FOS vendor integrations operational
- Enterprise data alignment for all shared domains
- ML-based anomaly detection operational


## Conclusion

This design document provides a comprehensive framework for AA NXOP Data Model Governance, addressing the strategic challenge of governing data across a complex multi-cloud architecture (AWS, Azure, On-Premises) while supporting 25 message flows, 7 integration patterns, and 5 core data domains.

The design establishes:
- **Governance Council** for centralized decision-making and policy enforcement
- **Message Flow Registry** documenting all 25 flows with their dependencies
- **Data Domain Models** for 5 domains (Flight, Aircraft, Station, Maintenance, ADL) with 24 entities
- **Cross-Account IAM and Pod Identity** for secure, credential-free access
- **MSK and Event Streaming Governance** for 6 MSK-dependent flows (24%)
- **DocumentDB Global Cluster Governance** for 5 DocumentDB-dependent flows (20%)
- **Schema Registry** for Avro, DocumentDB, and GraphQL schemas
- **Data Catalog** for metadata management and lineage tracking
- **Data Quality Framework** for validation, monitoring, and alerting
- **Multi-Region Resilience** with < 10 min RTO for regional failover

The design includes 10 correctness properties for property-based testing, comprehensive error handling strategies, and a phased implementation roadmap spanning 18+ months.

**Next Steps**:
1. Review and approve design document with Governance Council
2. Create implementation tasks based on Phase 1 deliverables
3. Begin Governance Council formation and charter development
4. Initiate Schema Registry deployment (Confluent + Custom)
5. Begin Data Catalog implementation

