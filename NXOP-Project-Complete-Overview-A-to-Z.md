# NXOP Project 
## Comprehensive Guide to American Airlines' Next Generation Operations Platform

**Document Version**: 2.0  
**Date**: February 2, 2026  
**Classification**: Internal Use  
**Owner**: NXOP Platform Team & Enterprise Data Office  
**Purpose**: Complete reference for NXOP architecture, governance, data models, and implementation

---

## Document Overview

This comprehensive document consolidates all information about American Airlines' Next Generation Operations Platform (NXOP) into a single authoritative reference spanning 60-75 pages. It integrates content from multiple source documents including the NXOP design specification, data model governance framework, and detailed governance implementation guide.

**Document Structure**:
1. Executive Summary (2-3 pages)
2. Project Overview (10-12 pages)
3. Architecture (8-10 pages)
4. Technology Stack (10-12 pages)
5. Data Domain Models (12-15 pages)
6. Integration Patterns (6-8 pages)
7. Message Flows (4-5 pages)
8. Infrastructure Components (8-10 pages)
9. Security & Identity (3-4 pages)
10. Resilience & Disaster Recovery (3-4 pages)
11. Monitoring & Observability (2-3 pages)
12. Migration Strategy (2-3 pages)
13. Operational Procedures (2-3 pages)
14. Data Governance Framework (8-10 pages)
15. Implementation Roadmap (2-3 pages)
16. Conclusion (1-2 pages)

---

## 1. Executive Summary

### 1.1 Purpose and Strategic Importance

The Next Generation Operations Platform (NXOP) represents American Airlines' strategic initiative to modernize flight operations infrastructure, replacing legacy systems with a cloud-native, event-driven architecture. NXOP is mission-critical because:

**Flight Safety**: Accurate, real-time operational data directly impacts passenger and crew safety through better decision-making and situational awareness.

**Regulatory Compliance**: FAA, EASA, and international aviation authorities require strict data management, audit trails, and operational transparency.

**Operational Efficiency**: Airlines operate on thin margins (3-5% profit margins industry-wide). Data-driven optimization of fuel consumption, crew utilization, and aircraft scheduling can save millions annually.

**Customer Experience**: On-time performance (OTP), baggage handling, and service quality depend on accurate, timely operational data flowing between systems.

**Revenue Management**: Dynamic pricing, yield management, and capacity planning require trusted, real-time operational data to maximize revenue per available seat mile (RASM).


### 1.2 Scope and Scale

**Multi-Cloud Architecture**:
- **AWS NXOP Platform**: Primary operational platform in us-east-1 (N. Virginia) and us-west-2 (Oregon)
- **Azure FXIP Platform**: Flight planning and crew integration platform
- **On-Premises FOS**: Legacy Future of Operations Solutions systems

**Operational Scale**:
- **25 Message Flows**: Distinct data exchange pathways between systems
- **7 Integration Patterns**: Standardized approaches for data exchange
- **5 Data Domains**: Flight, Aircraft, Station, Maintenance, ADL
- **24 Core Entities**: Operational data models for real-time flight operations
- **50+ Kafka Topics**: Event streaming infrastructure
- **24 DocumentDB Collections**: Operational data storage
- **100+ EKS Pods**: Microservices running in Kubernetes

**Data Volume**:
- **Millions of events per day**: Flight events, aircraft updates, maintenance records
- **10,000+ writes/second**: Peak operational load during busy periods
- **Sub-second latency**: Real-time data requirements for operational decisions
- **Multi-terabyte storage**: Historical data for analytics and compliance

### 1.3 Key Stakeholders

**Executive Leadership**:
- Chief Information Officer (CIO): Executive sponsor
- Chief Data Officer (CDO): Enterprise data governance
- VP Flight Operations Technology: NXOP platform ownership
- VP Fleet Management: Aircraft domain ownership
- VP Maintenance & Engineering: Maintenance domain ownership

**Operational Teams**:
- Flight Operations: Flight domain data stewardship
- Network Operations: Station domain data stewardship
- Maintenance Operations: Maintenance domain data stewardship
- FOS Integration: ADL domain and vendor integration

**Technology Teams**:
- NXOP Platform Team (15-20 engineers): Platform development and operations
- Integration Team (5-7 engineers): Vendor integration and FOS connectivity
- Enterprise Data Office: Canonical model alignment
- KPaaS Team: Kubernetes infrastructure management

**External Partners**:
- FOS Vendors: DECS, Load Planning, Takeoff Performance, Crew Management
- Flightkeys (Azure FXIP): Flight planning and crew integration
- ACARS Providers: Aircraft communications
- Weather Services: Real-time weather data

### 1.4 Success Metrics

**Operational Excellence**:
- > 99.9% platform uptime
- < 10 minutes RTO (Recovery Time Objective) for regional failover
- < 1 minute RTO for DocumentDB failover
- < 5 seconds end-to-end latency for critical message flows

**Data Quality**:
- > 99.5% data quality score across all domains
- > 99.9% schema validation pass rate
- < 0.1% duplicate record rate
- > 99% referential integrity compliance

**Integration Efficiency**:
- < 6 months average vendor onboarding time
- 100% vendor compliance with integration standards
- > 70% integration pattern reuse
- < 24 hours for vendor integration issue resolution

**Governance Maturity**:
- Level 4 (Quantitatively Managed) within 18 months
- 100% semantic mappings documented for shared domains
- < 2 weeks for operational data model change approvals
- 95% governance compliance across all teams

---

## 2. Project Overview

### 2.1 Business Context and Strategic Drivers

American Airlines operates one of the world's largest airline networks with:
- **6,800+ daily flights** across 350+ destinations
- **950+ aircraft** in active fleet
- **130,000+ employees** including 15,000+ pilots and 25,000+ flight attendants
- **200+ million passengers** annually
- **$50+ billion** annual revenue

**Legacy Challenges**:
- **Fragmented Systems**: 20+ legacy systems with inconsistent data models
- **Manual Processes**: Paper-based workflows and manual data entry
- **Limited Real-Time Visibility**: Batch processing delays operational decisions
- **Integration Complexity**: Point-to-point integrations creating maintenance burden
- **Scalability Constraints**: Monolithic architectures unable to handle growth
- **Vendor Lock-In**: Proprietary systems limiting flexibility and innovation

**Strategic Drivers for NXOP**:
1. **Digital Transformation**: Modernize flight operations with cloud-native architecture
2. **Operational Resilience**: Multi-region active-active for business continuity
3. **Data-Driven Decisions**: Real-time analytics and machine learning capabilities
4. **Vendor Ecosystem**: Flexible integration of best-of-breed FOS solutions
5. **Cost Optimization**: Cloud economics and operational efficiency gains
6. **Regulatory Compliance**: Enhanced audit trails and data governance


### 2.2 Vision and Objectives

**Vision Statement**:
"Transform American Airlines flight operations through a modern, cloud-native platform that enables real-time decision-making, operational excellence, and seamless integration of best-of-breed solutions while maintaining the highest standards of safety, reliability, and data governance."

**Strategic Objectives**:

**1. Operational Excellence**:
- Achieve > 99.9% platform uptime for mission-critical operations
- Enable sub-second data latency for real-time operational decisions
- Support 10,000+ concurrent users across flight operations teams
- Process millions of operational events daily without degradation

**2. Data Governance**:
- Establish comprehensive three-tier governance model (Enterprise, NXOP Domain, Vendor)
- Achieve > 99.5% data quality across all operational domains
- Implement automated schema validation and compatibility enforcement
- Maintain complete audit trails for regulatory compliance

**3. Integration Agility**:
- Reduce vendor onboarding time from 9-12 months to < 6 months
- Standardize 7 integration patterns for 70% reuse across vendors
- Enable parallel operation of legacy and modern systems during 18-month transitions
- Support seamless failover between cloud regions and platforms

**4. Business Resilience**:
- Implement multi-region active-active architecture with < 10 min RTO
- Ensure zero data loss during regional failovers (RPO = 0)
- Support graceful degradation during partial system failures
- Enable rapid recovery from operational incidents

**5. Cost Optimization**:
- Leverage cloud economics for infrastructure cost reduction
- Optimize resource utilization through auto-scaling and right-sizing
- Reduce integration maintenance burden through standardization
- Enable faster time-to-market for new capabilities

### 2.3 Design Principles

**1. Multi-Cloud First**:
- Governance policies apply uniformly across AWS, Azure, and On-Premises
- Consistent schema validation across all platforms
- Unified monitoring and alerting regardless of cloud provider
- Platform-agnostic data quality checks

**Rationale**: American Airlines operates across multiple cloud platforms due to legacy investments, strategic partnerships, and vendor requirements. Inconsistent governance creates data silos and integration complexity.

**2. Message Flow Centric**:
- All governance decisions consider impact on 25 message flows
- Schema changes require impact analysis across affected flows
- Infrastructure changes validated against all flows
- Performance optimization targets specific flows

**Rationale**: Message flows represent actual business processes (flight planning, crew assignment, maintenance tracking). Changes that break message flows directly impact flight operations.

**3. Domain-Driven Design**:
- 5 operational domains with clear boundaries (Flight, Aircraft, Station, Maintenance, ADL)
- Each domain has dedicated Data Steward and Technical Owner
- Independent schema evolution within domains
- Explicit cross-domain relationships with referential integrity

**Rationale**: Complex systems need clear boundaries to manage complexity. Domain boundaries align with organizational structure and enable independent evolution.

**4. Event-Driven Architecture**:
- All data changes flow through MSK/Kafka with schema validation
- Avro schemas enforced via Confluent Schema Registry
- Event replay enables debugging and recovery
- Audit trail for all data changes

**Rationale**: Event-driven architecture decouples producers from consumers, provides audit trails, and enables event replay for debugging and recovery.

**5. Cross-Account Security**:
- Pod Identity enables secure, credential-free access
- Temporary credentials expire after 1 hour
- Full audit trail via CloudTrail
- Least-privilege access per pod

**Rationale**: Static credentials in pods are security risks. Pod Identity uses temporary credentials with automatic rotation and full audit trails.

**6. Multi-Region Consistency**:
- Data governance policies apply uniformly across regions
- Schema versions synchronized across regions
- Data quality rules identical in both regions
- Failover procedures tested regularly

**Rationale**: NXOP operates in us-east-1 (primary) and us-west-2 (secondary). Regional failover must be seamless with < 10 min RTO.

**7. Backward Compatibility**:
- Schema evolution maintains compatibility unless explicitly versioned
- Confluent Schema Registry enforces backward compatibility mode
- Breaking changes require new topic/collection with version suffix
- Gradual consumer migration for breaking changes

**Rationale**: Breaking changes force all consumers to update simultaneously (coordination nightmare). Backward compatibility enables gradual consumer migration.

**8. Metadata as Code**:
- All governance artifacts version-controlled in Git
- CI/CD integration for schema validation and deployment
- Automated impact analysis on pull requests
- Infrastructure as Code (IaC) for reproducibility

**Rationale**: Manual governance processes don't scale (50+ topics, 24 collections, 25 flows). Version control provides audit trails and CI/CD automation prevents human error.

**9. Federated Ownership**:
- Data domains owned by Operations, technical implementation by IT
- Clear accountability (Operations owns correctness, IT owns performance)
- Prevents bottlenecks (single team owning everything)
- Domain Data Stewards define logical models, IT implements physical models

**Rationale**: Operations teams understand business semantics (what data means). IT teams understand technical implementation (how data is stored).

**10. Resilience by Design**:
- Governance supports < 10 min RTO for regional failover
- Schema Registry replicated across regions
- Data Catalog available in both regions
- No single points of failure in governance processes

**Rationale**: Flight operations are 24/7 critical (cannot tolerate extended outages). Governance must not impede resilience.


---

## 3. Architecture

### 3.1 Multi-Cloud Architecture Overview

NXOP operates as a multi-region, event-driven architecture designed to support American Airlines' critical flight operations in real-time across three cloud platforms:

**AWS NXOP Platform (Primary Operational Platform)**:
- **Regions**: us-east-1 (N. Virginia - Primary), us-west-2 (Oregon - Secondary)
- **Purpose**: Real-time flight operations, event processing, operational data storage
- **Why Multi-Region**: 
  - Disaster recovery with < 10 minute RTO
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
  - DECS (Dispatch Environmental Control System): Weather, NOTAMs, flight planning
  - Load Planning: Cargo and passenger weight distribution, balance calculations
  - Takeoff Performance: Runway analysis, performance calculations
  - Crew Management: Crew assignments, qualifications, scheduling
  - Maintenance Systems: Work orders, MEL tracking, parts management
- **Integration Point**: MQ-Kafka adapters bridge on-premises MQ to NXOP MSK
- **Why On-Premises**: Regulatory requirements, vendor constraints, gradual cloud migration

### 3.2 High-Level Architecture Diagram

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
│ │ Flightkeys │ │         │ │ DECS       │ │       │ │ ACARS      │ │
│ │ Event      │ │         │ │ Load Plan  │ │       │ │ Weather    │ │
│ │ Processors │ │         │ │ Takeoff    │ │       │ │ Services   │ │
│ │            │ │         │ │ Perf       │ │       │ │            │ │
│ └────────────┘ │         │ └────────────┘ │       │ └────────────┘ │
│ ┌────────────┐ │         │ ┌────────────┐ │       │                 │
│ │ ConsulDB   │ │         │ │ MQ-Kafka   │ │       │                 │
│ │ (Reference │ │         │ │ Adapters   │ │       │                 │
│ │ Data)      │ │         │ │            │ │       │                 │
│ └────────────┘ │         │ └────────────┘ │       │                 │
│ ┌────────────┐ │         │                 │       │                 │
│ │ OpsHub     │ │         │                 │       │                 │
│ │ Event Hubs │ │         │                 │       │                 │
│ └────────────┘ │         │                 │       │                 │
└────────────────┘         └─────────────────┘       └─────────────────┘
```

### 3.3 Account Structure

**KPaaS Accounts (Kubernetes Infrastructure)**:
- **KPaaS NonProd (285282426848)**: Development, testing, staging environments
- **KPaaS Prod (045755618773)**: Production flight operations
- **Managed By**: American Airlines' internal KPaaS (Kubernetes Platform as a Service) team
- **Responsibilities**: Infrastructure (nodes, networking, monitoring), cluster management

**NXOP Accounts (Application and Data)**:
- **NXOP NonProd**: Development, testing, staging data and services
- **NXOP Prod**: Production operational data and services
- **Managed By**: NXOP Platform Team
- **Responsibilities**: Applications (pods, services, deployments), data storage, integration

**Separation of Concerns**:
- KPaaS manages infrastructure, NXOP teams manage applications
- Clear boundaries and responsibilities
- Pod Identity enables secure cross-account access
- Independent scaling and lifecycle management


### 3.4 Network Architecture

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

**Akamai Global Traffic Manager (GTM)**:
- **Purpose**: Routes external API traffic to healthy region
- **Features**:
  - Health-based routing (monitors endpoint availability)
  - Geographic routing (routes to nearest region)
  - DDoS protection and rate limiting
  - Automatic failover between regions

---

## 4. Technology Stack

### 4.1 Compute Layer - EKS in KPaaS

**What**: Kubernetes clusters managed by American Airlines' internal KPaaS (Kubernetes Platform as a Service) team

**Why Separate Accounts**:
- KPaaS manages infrastructure (nodes, networking, monitoring)
- NXOP teams manage applications (pods, services, deployments)
- Clear separation of concerns and responsibilities

**Account Structure**:
- KPaaS NonProd: 285282426848 (development, testing, staging environments)
- KPaaS Prod: 045755618773 (production flight operations)

**Pod Identity**:
- Enables EKS pods to assume IAM roles in NXOP account without static credentials
- Security benefit: No long-lived credentials stored in pods
- Operational benefit: Automatic credential rotation
- Compliance benefit: Full audit trail of all access

**Key Microservices**:
- **Flight Data Adapter**: Processes flight events, updates DocumentDB
- **Aircraft Data Adapter**: Processes aircraft events, updates DocumentDB
- **Flightkeys Event Processor**: Integrates with Azure FXIP platform
- **Notification Service**: Sends alerts via email/SMS/push
- **GraphQL Gateway**: Apollo Federation gateway for unified API

### 4.2 Storage Layer - Multi-Technology Approach

**DocumentDB Global Clusters (Operational Data)**:

**What**: MongoDB-compatible database service with multi-region replication

**Why DocumentDB**:
- Flexible schema for evolving operational data structures
- High write throughput for real-time flight events (10,000+ writes/sec)
- Complex nested documents match operational data patterns (flight events with embedded metadata)
- Global Cluster provides automatic failover (< 1 minute RTO)

**Data Stored**:
- Flight operational data (24 collections across 5 domains)
- Aircraft configurations and status
- Station (airport) information
- Maintenance records
- ADL (FOS-derived) snapshots

**Access Patterns**:
- Read-heavy for reference data (aircraft configs, station data)
- Write-heavy for event data (flight events, position updates)
- Mixed for operational data (flight times, aircraft location)

**Configuration**:
- **Instance Type**: r6g.2xlarge (8 vCPU, 64 GB RAM)
- **Instances per Region**: 3 (1 primary, 2 replicas across AZs)
- **Storage**: Encrypted at rest with AWS KMS
- **Backup**: Automated daily backups with 35-day retention
- **Replication Lag**: < 1 second between regions

**S3 + Apache Iceberg (Analytics Data)**:

**What**: Object storage with Iceberg table format for analytics workloads

**Why Iceberg**:
- ACID transactions on S3 data
- Time travel queries for historical analysis
- Schema evolution without rewriting data
- Efficient partition pruning for large datasets

**Data Stored**:
- Historical flight data (years of operational history)
- Analytics aggregations (OTP metrics, fuel efficiency)
- Compliance archives (7-year retention for FAA)

**Access Patterns**:
- Batch reads for analytics (Databricks, Orion)
- Append-only writes from operational systems
- Time-series queries for trend analysis

**Configuration**:
- **Storage Class**: S3 Intelligent-Tiering (automatic cost optimization)
- **Lifecycle Policies**: Transition to Glacier after 90 days
- **Partitioning**: By date, carrier, flight number
- **Compression**: Parquet with Snappy compression

### 4.3 Streaming Layer - MSK/Kafka

**What**: Managed Kafka service for event streaming

**Why Kafka**:
- High throughput (millions of events per day)
- Durable message storage (3-day to 72-hour retention)
- Decouples producers from consumers
- Enables event replay for debugging and recovery

**Cross-Region Replication**:
- Bidirectional replication between us-east-1 and us-west-2
- Replication lag < 1 second (target)
- Automatic failover via Route53 DNS

**Topics**: 50+ Kafka topics organized by domain and carrier
- Flight events: flight-event-aa-*, flight-event-mq-*, flight-event-te-*
- Aircraft events: aircraft-snapshot-*, aircraft-update-*
- Station events: airport-event-*, airport-update-*
- Maintenance events: internal-maintenanceevents-avro
- ADL data: adl-data

**Avro Schemas**:
- Enforced via Confluent Schema Registry
- Backward compatibility ensures consumers don't break
- Schema evolution tracked with version numbers

**Configuration**:
- **Broker Type**: kafka.m5.2xlarge (8 vCPU, 32 GB RAM)
- **Brokers per Region**: 3 (across 3 AZs)
- **Storage**: 1 TB EBS per broker (gp3)
- **Encryption**: TLS in transit, encryption at rest
- **Authentication**: IAM authentication for producers/consumers

### 4.4 API Layer - GraphQL with Apollo Federation

**What**: Unified API layer aggregating data from multiple sources

**Why GraphQL**:
- Clients request only needed data (reduces bandwidth)
- Single endpoint for multiple data sources
- Strong typing with schema validation
- Real-time subscriptions for live updates

**Apollo Federation**:
- Each domain (Flight, Aircraft, Station, Maintenance, ADL) has its own subgraph
- Gateway composes subgraphs into unified schema
- Enables independent deployment of domain services

**Akamai GTM (Global Traffic Manager)**:
- Routes external API traffic to healthy region
- Health-based routing (monitors endpoint availability)
- Geographic routing (routes to nearest region)
- DDoS protection and rate limiting

**Configuration**:
- **Gateway Instances**: 3 per region (auto-scaling)
- **Subgraph Instances**: 2 per domain per region
- **Cache**: Redis for query result caching
- **Rate Limiting**: 1000 requests/minute per client

### 4.5 Schema Management

**Confluent Schema Registry (Avro/Kafka)**:
- **Deployment**: Multi-region (us-east-1, us-west-2) with replication
- **Compatibility Mode**: Backward compatibility (default)
- **Schema Versioning**: Semantic versioning (major.minor.patch)
- **Total Subjects**: 100+ (50+ topics × 2 subjects per topic)

**Custom Schema Registry (DocumentDB/GraphQL)**:
- **Storage**: Git repository + S3 for versioned schemas
- **Validation**: CI/CD pipeline validates syntax and compatibility
- **Documentation**: Automated generation from schemas
- **Integration**: Links to Data Catalog for metadata

### 4.6 Monitoring and Observability

**CloudWatch**:
- **Metrics**: Custom metrics for all services (latency, throughput, errors)
- **Logs**: Centralized logging with log groups per service
- **Alarms**: Composite alarms for critical conditions
- **Dashboards**: Operational dashboards for each domain

**Prometheus + Grafana**:
- **Metrics Collection**: Prometheus scrapes metrics from EKS pods
- **Visualization**: Grafana dashboards for detailed analysis
- **Alerting**: Alert Manager for complex alerting rules
- **Retention**: 30 days in Prometheus, long-term in CloudWatch

**X-Ray**:
- **Distributed Tracing**: End-to-end request tracing across services
- **Service Map**: Visual representation of service dependencies
- **Performance Analysis**: Identify bottlenecks and latency issues

---

## 5. Data Domain Models

### 5.1 Domain-Driven Design Approach

NXOP data architecture is organized into five core operational domains, each representing a critical aspect of airline operations. This approach provides:

**Clear Boundaries**: Each domain has well-defined responsibilities and ownership
**Independent Evolution**: Changes in one domain don't break others
**Scalability**: Domains can scale independently based on load
**Organizational Alignment**: Domain boundaries align with business units

### 5.2 Flight Domain (7 Entities)

**Domain Purpose**: Core operational truth of flight lifecycle from schedule → updates → completion

**Why Domain-Driven Design**:
- Operational Hot Tier: Flight data must support real-time reads/writes, low latency
- System of Record: GraphQL consumers expect one unified flight object without joins
- Event-Heavy Workload: OPSHUB generates millions of events
- Flexible Evolution: DocumentDB allows polymorphic sub-structures

**Data Steward**: Director of Flight Operations
**Technical Owner**: NXOP Platform Team - Flight Services
**Primary Consumers**: Dispatch, Crew, Maintenance, Customer Service, Network Operations

#### 5.2.1 FlightIdentity (Parent Entity)

**Purpose**: Defines unique identity of a flight on a given day, acts as master reference

**Key Characteristics**:
- Represents one flight regardless of operational changes
- flightKey is composite ID: carrier + flight number + flight date + departure station + dupDepCode
- flightKey used as connection for all other Flight Domain entities

**Core Fields**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "carrierCode": "AA",
  "flightNumber": "1234",
  "flightDate": "2026-02-02",
  "departureStation": "DFW",
  "arrivalStation": "LAX",
  "dupDepCode": "0"
}
```

**Relationships**: 1→1 with FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning

**Update Frequency**: Once per flight (immutable after creation)

**Governance**: Operations team owns business semantics, IT team owns DocumentDB implementation

#### 5.2.2 FlightTimes

**Purpose**: Captures time-related data across entire lifecycle (Scheduled, Estimated, Actual, Latest)

**Core Objects**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "scheduled": {
    "departureTime": "2026-02-02T10:00:00Z",
    "arrivalTime": "2026-02-02T12:30:00Z"
  },
  "estimated": {
    "departureTime": "2026-02-02T10:15:00Z",
    "arrivalTime": "2026-02-02T12:45:00Z"
  },
  "actual": {
    "departureTime": "2026-02-02T10:12:00Z",
    "arrivalTime": "2026-02-02T12:40:00Z"
  },
  "latest": {
    "departureTime": "2026-02-02T10:12:00Z",
    "arrivalTime": "2026-02-02T12:40:00Z"
  }
}
```

**Business Rules**: 
- actualDeparture must be <= actualArrival
- Estimated times updated based on operational events
- Latest times reflect most current information

**Update Frequency**: High (multiple updates per flight as conditions change)

**Governance**: Critical for OTP (On-Time Performance) metrics, strict validation rules

#### 5.2.3 FlightLeg

**Purpose**: Represents operational leg including routing, gate/terminal, equipment, status

**Core Objects**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "legInfo": {
    "departureGate": "D15",
    "arrivalGate": "42A",
    "departureTerminal": "D",
    "arrivalTerminal": "4"
  },
  "legEquipment": {
    "equipmentType": "737-800",
    "tailNumber": "N12345"
  },
  "legLinkage": {
    "previousLeg": "AA1233-20260202-LAX-0",
    "nextLeg": "AA1235-20260202-LAX-0"
  },
  "legStatus": "ACTIVE"
}
```

**Business Rules**:
- Gate assignments must be valid for station
- Equipment must be available
- Tail number must exist in Aircraft domain

**Update Frequency**: Medium (updates for gate changes, equipment swaps)

**Governance**: Integrates with Station Domain for gate/terminal data

#### 5.2.4 FlightEvent

**Purpose**: Stores current and last known event state with computed values

**Core Objects**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "FUFI": "FK-AA1234-20260202-DFW",
  "currentEventType": "DEPARTED",
  "currentEventTime": "2026-02-02T10:12:00Z",
  "currentEventSequence": 5,
  "lastEventType": "BOARDING",
  "lastEventTime": "2026-02-02T09:45:00Z",
  "metadata": {
    "source": "OPSHUB",
    "timestamp": "2026-02-02T10:12:05Z"
  }
}
```

**Business Rules**:
- Events must be in chronological order
- Event types follow operational sequence
- FUFI (Flightkeys Unique Flight Identifier) links to external systems

**Update Frequency**: Very high (real-time event processing from OpsHub)

**Governance**: Event schema versioning critical, high-volume writes

#### 5.2.5 FlightMetrics

**Purpose**: KPI-level performance and operational metrics extracted from Flight and OPSHUB

**Core Fields**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "fuelMetrics": {
    "plannedFuel": 15000,
    "actualFuel": 14800,
    "variance": -200
  },
  "passengerMetrics": {
    "booked": 150,
    "boarded": 148,
    "revenue": 45000
  },
  "performanceMetrics": {
    "onTimePerformance": true,
    "delayMinutes": 0
  }
}
```

**Update Frequency**: Medium (calculated after key operational milestones)

**Governance**: Used by analytics and solver applications, data quality critical

#### 5.2.6 FlightPosition

**Purpose**: Aircraft movement and telemetry events (ACARS/ADS-B/ATC feeds)

**Core Objects**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "latitude": 33.9425,
  "longitude": -118.4081,
  "altitude": 35000,
  "speed": 450,
  "heading": 270,
  "timestamp": "2026-02-02T11:30:00Z",
  "acarsMessage": {
    "messageType": "POSITION_REPORT",
    "details": "..."
  }
}
```

**Business Rules**:
- Position updates must be sequential
- Used for flight tracking
- High-volume time-series data

**Update Frequency**: Very high (position updates every 1-15 minutes during flight)

**Governance**: Retention policies important for compliance

#### 5.2.7 FlightLoadPlanning

**Purpose**: Load plan for passengers, freight, bags, compartments, cabin capacity

**Core Objects**:
```json
{
  "flightKey": "AA1234-20260202-DFW-0",
  "passengerCounts": {
    "first": 12,
    "business": 20,
    "economy": 116
  },
  "bagCounts": {
    "checked": 180,
    "carry": 148
  },
  "cargoCounts": {
    "freight": 2500,
    "mail": 500
  },
  "cabinCapacity": {
    "first": 16,
    "business": 30,
    "economy": 120
  }
}
```

**Business Rules**:
- Total weight must not exceed aircraft limits
- Balance requirements must be met
- Integrates with FOS Load Planning system

**Update Frequency**: Medium (updates during boarding and cargo loading)


### 5.3 Aircraft Domain (5 Entities)

**Domain Purpose**: Authoritative master record of every aircraft in airline's fleet

**Why Separate Domain**:
- Aircraft lifecycle is independent of Flight lifecycle
- Aircraft information is reused across multiple domains
- Relatively static data, changes infrequently

**Data Steward**: Fleet Management team member
**Technical Owner**: NXOP Platform Team - Aircraft Services
**Primary Consumers**: Flight Planning, Maintenance, Load Planning, Performance Calculations

#### 5.3.1 AircraftIdentity (Parent Entity)

**Purpose**: Core aircraft identifiers used across ops systems, aggregate root within domain

**Core Fields**:
```json
{
  "carrierCode": "AA",
  "noseNumber": "12345",
  "registration": "N12345",
  "numericCode": "12345",
  "mnemonicFleetCode": "738",
  "mnemonicTypeCode": "73H",
  "marketingFleetCode": "738",
  "ATCType": "B738",
  "FAANavCode": "B738",
  "alternateFAANAVCode": "B737",
  "heavyInd": false,
  "LUSInd": false,
  "specialInd": false
}
```

**Relationships**: 1→1 with AircraftConfiguration, AircraftLocation, AircraftPerformance, AircraftMEL

**Update Frequency**: Low (changes only for fleet modifications)

**Governance**: Master data, synchronized with enterprise aircraft registry

#### 5.3.2 AircraftConfiguration

**Purpose**: Static structural configuration (cabin layout, type, SELCAL, operator-defined attributes)

**Core Fields**:
```json
{
  "noseNumber": "12345",
  "configuration": {
    "code": "738-V1",
    "ATCType": "B738",
    "FAANavCode": "B738",
    "marketingFleetCode": "738",
    "SELCAL": "ABCD"
  },
  "cabinCapacity": {
    "first": 16,
    "business": 30,
    "economy": 120,
    "total": 166
  },
  "galleys": 3,
  "lavatories": 4
}
```

**Business Rules**:
- Configuration changes require maintenance approval
- Cabin capacity must match physical layout
- Version controlled for historical tracking

**Update Frequency**: Very low (only for major reconfigurations)

**Governance**: Changes require maintenance approval, version controlled

#### 5.3.3 AircraftLocation

**Purpose**: Current operational state (last flight, next flight, overnight planning, out-of-service status)

**Core Objects**:
```json
{
  "noseNumber": "12345",
  "location": {
    "aircraftStatus": "IN_SERVICE",
    "currentStation": "DFW",
    "controlledRouteInd": true,
    "outOfServiceCode": null,
    "openMELitems": 2
  },
  "lastCompletedFlight": {
    "flightKey": "AA1233-20260202-LAX-0",
    "arrivalTime": "2026-02-02T09:30:00Z"
  },
  "nextFlight": {
    "flightKey": "AA1234-20260202-DFW-0",
    "departureTime": "2026-02-02T10:00:00Z"
  },
  "plannedOverNight": {
    "station": "LAX",
    "date": "2026-02-02"
  }
}
```

**Business Rules**:
- Aircraft status must be valid operational state
- Location must match last completed flight arrival station
- Next flight departure station must match current location

**Update Frequency**: High (real-time updates as flights complete)

**Governance**: Real-time updates, critical for flight planning

#### 5.3.4 AircraftPerformance

**Purpose**: Weight limits, operational performance values, miscellaneous operational configuration

**Core Objects**:
```json
{
  "noseNumber": "12345",
  "weight": {
    "emptyOperatingWeight": 91300,
    "maximumTakeoffWeight": 174200,
    "maximumLandingWeight": 146300,
    "maximumZeroFuelWeight": 138300,
    "maximumFuelCapacity": 26020
  },
  "weightMisc": {
    "fuelFlowCorrectionFactor": 1.02,
    "cruiseSpeedCorrection": 0.98
  },
  "performance": {
    "cruiseSpeed": 450,
    "maxAltitude": 41000,
    "range": 3115
  }
}
```

**Business Rules**:
- Weight values must be within aircraft type limits
- Performance values used by FOS Takeoff Performance calculations
- Strict validation required for safety

**Update Frequency**: Low (changes only for weight modifications or performance updates)

**Governance**: Used by FOS Takeoff Performance calculations, strict validation

#### 5.3.5 AircraftMEL

**Purpose**: Active Minimum Equipment List items (issue, effectivity, subsystem, closure details)

**Core Fields**:
```json
{
  "noseNumber": "12345",
  "ATASystemID": "32",
  "AMRNumber": "MEL-2026-001",
  "subSystem": "Landing Gear",
  "systemCode": "32-10",
  "description": "Nose gear position indicator inoperative",
  "issue": {
    "dateTime": "2026-02-01T14:30:00Z",
    "station": "DFW",
    "reportedBy": "Pilot"
  },
  "effectivity": {
    "startDate": "2026-02-01",
    "expiryDate": "2026-02-11",
    "flightLimitations": "Day VFR only"
  },
  "close": {
    "dateTime": null,
    "station": null,
    "closedBy": null
  }
}
```

**Business Rules**:
- MEL items must have valid ATA system codes
- Effectivity dates must be within regulatory limits
- Open MEL items affect aircraft dispatch eligibility

**Update Frequency**: Medium (new items added, existing items closed)

**Governance**: Compliance-critical, audit trail required, integrates with Maintenance Domain

**Domain Governance Summary**:
- **Message Flows**: Flows 1, 10, 11, 13, 15 (5 of 25 flows)
- **DocumentDB Collections**: 5 collections (one per entity)
- **MSK Topics**: 9 aircraft-related topics (aircraft-snapshot-*, aircraft-update-*)

### 5.4 Station Domain (4 Entities)

**Domain Purpose**: Airports and airline stations used across all flight operations, single authoritative source of truth

**Why Separate Domain**:
- Provides single source of truth for station identity, geography, operational capabilities, authorization rules
- Data is relatively static, changes infrequently, heavily reused by multiple domains
- Primary data source: OPSHUB Station/AirportInfo Collections

**Data Steward**: Network Planning team member
**Technical Owner**: NXOP Platform Team - Station Services
**Primary Consumers**: Flight Planning, Routing, Performance Calculations, Network Operations

#### 5.4.1 StationIdentity (Parent Entity)

**Purpose**: Primary anchor for Station Domain, represents unique station from airline's perspective

**Core Fields**:
```json
{
  "icaoAirportID": "KDFW",
  "iataAirlineCode": "DFW",
  "airportName": "Dallas/Fort Worth International Airport",
  "stationName": "Dallas Fort Worth",
  "ataAirportID": "DFW",
  "icaoAreaCode": "K",
  "intlStation": true,
  "aaStation": true,
  "cat3LandingsAllowed": true,
  "coTerminalAllowed": false,
  "stationMaintClass": "A",
  "actionCode": "ACTIVE",
  "timeStamp": "2026-02-02T00:00:00Z"
}
```

**Relationships**: 1→1 with StationGeo, StationAuthorization, StationMetadata

**Update Frequency**: Very low (changes only for new stations or major updates)

**Governance**: Master data, synchronized with enterprise airport registry

#### 5.4.2 StationGeo

**Purpose**: Geographical and physical characteristics for operations, routing logic, performance calculations

**Core Fields**:
```json
{
  "icaoAirportID": "KDFW",
  "latitude": 32.8968,
  "longitude": -97.0380,
  "elevation": 607,
  "magneticVariation": 4.5,
  "longestRunwayLength": 13401,
  "recommendedNAVAID": "DFW",
  "recommendedNAVAIDICAOAreaCode": "K",
  "timezone": "America/Chicago",
  "daylightSavings": true
}
```

**Business Rules**:
- Coordinates must be valid lat/long
- Elevation in feet above sea level
- Magnetic variation updated annually

**Update Frequency**: Low (changes for runway modifications or NAVAID updates)

**Governance**: Used by FOS routing and performance calculations

#### 5.4.3 StationAuthorization

**Purpose**: Landing authorization configurations, preserves OPSHUB structure

**Core Objects**:
```json
{
  "icaoAirportID": "KDFW",
  "scheduledLandingsAuthorized": [
    {
      "equipmentType": "737-800",
      "authorized": true,
      "restrictions": []
    },
    {
      "equipmentType": "777-300ER",
      "authorized": true,
      "restrictions": ["Runway 18R/36L only"]
    }
  ],
  "charteredLandingsAuthorized": [
    {
      "equipmentType": "737-800",
      "authorized": true
    }
  ],
  "driftdownLandingsAuthorized": [
    {
      "equipmentType": "777-300ER",
      "authorized": true,
      "conditions": ["Emergency only"]
    }
  ],
  "alternateLandingsAuthorized": [
    {
      "equipmentType": "ALL",
      "authorized": true
    }
  ]
}
```

**Business Rules**:
- Authorization must comply with FAA/IATA regulations
- Equipment type must exist in Aircraft domain
- Restrictions must be documented and validated

**Update Frequency**: Low (changes for regulatory updates or operational changes)

**Governance**: Compliance-critical, FAA/IATA regulations

#### 5.4.4 StationMetadata

**Purpose**: Operational metadata and additional station attributes

**Core Fields**:
```json
{
  "icaoAirportID": "KDFW",
  "operationalNotes": "Hub station with full maintenance capabilities",
  "customsAvailable": true,
  "fuelAvailable": true,
  "cateringAvailable": true,
  "maintenanceCapabilities": ["Line", "Heavy"],
  "operatingHours": "24/7",
  "slotControlled": false
}
```

**Update Frequency**: Low (changes for operational capability updates)

**Governance**: Extensible for future operational needs

**Domain Governance Summary**:
- **Message Flows**: Flows 1, 2, 3, 4, 16 (5 of 25 flows)
- **DocumentDB Collections**: 4 collections (one per entity)
- **MSK Topics**: 3 station-related topics (airport-event-*, airport-update-*)

### 5.5 Maintenance Domain (6 Entities)

**Domain Purpose**: All aircraft maintenance operations reported through OPSHUB (deferred defects, out-of-service status, airframe metrics, complete maintenance event lifecycle)

**Key Characteristics**:
- Event-driven data (trackingID per event)
- Complex nested structures (DMI, OTS, LandingData)
- Historical event chains (100+ entries)
- Aircraft-centric and timestamp-heavy
- High variability and update frequency

**Data Steward**: Maintenance Operations team member
**Technical Owner**: NXOP Platform Team - Maintenance Services
**Primary Consumers**: Maintenance Planning, Fleet Management, Compliance, Safety

#### 5.5.1 MaintenanceRecord (Parent Entity)

**Purpose**: Top-level snapshot of maintenance event from OPSHUB, root for all child entities

**Core Fields**:
```json
{
  "trackingID": "MAINT-2026-02-02-12345-001",
  "airlineCode": {
    "iata": "AA",
    "icao": "AAL"
  },
  "tailNumber": "N12345",
  "registration": "N12345",
  "event": {
    "type": "SCHEDULED_MAINTENANCE",
    "timestamp": "2026-02-02T08:00:00Z",
    "station": "DFW"
  },
  "schemaVersion": "1.0",
  "fosPartition": "AA"
}
```

**Relationships**: 1→Many with MaintenanceDMI, MaintenanceEquipment, MaintenanceLandingData, MaintenanceOTS, MaintenanceEventHistory

**Update Frequency**: High (event-driven, multiple events per day per aircraft)

**Governance**: Event-driven, high-volume writes, retention policies critical

#### 5.5.2 MaintenanceDMI

**Purpose**: List of deferred defects associated with aircraft at time of maintenance event

**Core Fields**:
```json
{
  "trackingID": "MAINT-2026-02-02-12345-001",
  "dmiId": {
    "ataCode": "32",
    "controlNumber": "DMI-001",
    "dmiClass": "B",
    "eqType": "738"
  },
  "dmiData": {
    "position": "Nose Gear",
    "dmiText": "Position indicator inoperative",
    "effectiveTime": "2026-02-01T14:30:00Z",
    "expiryTime": "2026-02-11T14:30:00Z",
    "limitations": "Day VFR only"
  }
}
```

**Business Rules**:
- DMI items must have valid ATA codes
- Effectivity must be within regulatory limits
- Links to AircraftMEL entity for cross-validation

**Update Frequency**: Medium (new DMIs added, existing DMIs closed)

**Governance**: Compliance-critical, integrates with AircraftMEL entity

#### 5.5.3 MaintenanceEquipment

**Purpose**: Aircraft equipment configuration as captured in maintenance event

**Core Fields**:
```json
{
  "trackingID": "MAINT-2026-02-02-12345-001",
  "equip": {
    "fleetType": "738",
    "typeEq": "B738",
    "numericEqType": "73H",
    "eventSourceTimeStamp": "2026-02-02T08:00:00Z",
    "updateTimeStamp": "2026-02-02T08:05:00Z"
  },
  "engines": [
    {
      "position": "LEFT",
      "serialNumber": "ENG-12345",
      "model": "CFM56-7B27",
      "totalTime": 45000,
      "cyclesSinceNew": 32000
    },
    {
      "position": "RIGHT",
      "serialNumber": "ENG-12346",
      "model": "CFM56-7B27",
      "totalTime": 43000,
      "cyclesSinceNew": 30000
    }
  ]
}
```

**Business Rules**:
- Equipment configuration must match aircraft type
- Engine serial numbers must be unique
- Time and cycle tracking for maintenance scheduling

**Update Frequency**: Medium (updates for equipment changes)

**Governance**: Not static like Aircraft domain, event-specific snapshot

#### 5.5.4 MaintenanceLandingData

**Purpose**: Aircraft's lifetime operational metrics (total time, cycles, last/next flight)

**Core Fields**:
```json
{
  "trackingID": "MAINT-2026-02-02-12345-001",
  "ttlTime": 65000,
  "cycles": 48000,
  "lastFlt": {
    "ftNum": "AA1233",
    "date": "2026-02-02",
    "departureStation": "LAX",
    "arrivalStation": "DFW",
    "blockTime": 3.5
  },
  "nextFlt": {
    "ftNum": "AA1234",
    "date": "2026-02-02",
    "departureStation": "DFW",
    "arrivalStation": "LAX"
  },
  "landingData": {
    "eventSourceTimeStamp": "2026-02-02T09:30:00Z",
    "hardLandings": 0,
    "overweightLandings": 0
  }
}
```

**Business Rules**:
- Total time and cycles must be monotonically increasing
- Used for maintenance scheduling and flight-worthiness checks
- Hard landing events trigger inspections

**Update Frequency**: High (updates after each flight)

**Governance**: Used for maintenance scheduling, flight-worthiness checks

#### 5.5.5 MaintenanceOTS

**Purpose**: Out-of-service status and related maintenance information

**Core Fields**:
```json
{
  "trackingID": "MAINT-2026-02-02-12345-001",
  "otsStatus": "IN_SERVICE",
  "otsCode": null,
  "otsReason": null,
  "otsStartTime": null,
  "otsEndTime": null,
  "estimatedReturnToService": null,
  "maintenanceType": "SCHEDULED",
  "workOrders": [
    {
      "workOrderNumber": "WO-2026-001",
      "description": "A-Check",
      "status": "COMPLETED"
    }
  ]
}
```

**Business Rules**:
- OTS status affects aircraft availability
- Work orders must be tracked for compliance
- Estimated return to service critical for planning

**Update Frequency**: Medium (updates for maintenance events)

**Governance**: Critical for aircraft availability planning

#### 5.5.6 MaintenanceEventHistory

**Purpose**: Complete maintenance event lifecycle with historical event chains

**Core Fields**:
```json
{
  "trackingID": "MAINT-2026-02-02-12345-001",
  "eventHistory": [
    {
      "eventSequence": 1,
      "eventType": "MAINTENANCE_SCHEDULED",
      "eventTime": "2026-01-15T10:00:00Z",
      "eventDetails": "A-Check scheduled for 2026-02-02"
    },
    {
      "eventSequence": 2,
      "eventType": "MAINTENANCE_STARTED",
      "eventTime": "2026-02-02T08:00:00Z",
      "eventDetails": "A-Check started at DFW"
    },
    {
      "eventSequence": 3,
      "eventType": "MAINTENANCE_COMPLETED",
      "eventTime": "2026-02-02T16:00:00Z",
      "eventDetails": "A-Check completed, aircraft returned to service"
    }
  ],
  "totalEvents": 3
}
```

**Business Rules**:
- Events must be in chronological order
- Event sequence must be unique and sequential
- Complete audit trail for compliance

**Update Frequency**: High (new events added throughout maintenance lifecycle)

**Governance**: Audit trail, compliance, historical analysis

**Domain Governance Summary**:
- **Message Flows**: Flows 1, 10, 16 (3 of 25 flows)
- **DocumentDB Collections**: 6 collections (one per entity)
- **MSK Topics**: 1 maintenance topic (internal-maintenanceevents-avro)

---

### 5.6 ADL Domain (2 Entities)

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

**Data Steward**: FOS Integration team member
**Technical Owner**: NXOP Platform Team - ADL Services
**Primary Consumers**: FOS Systems, Analytics, Reporting

#### 5.6.1 adlHeader (Parent Entity)

**Purpose**: Top-level snapshot metadata for flight extracted from ADL (snapshot timestamp, ADL record ID, airline identifiers, key operational flags)

**Core Fields**:
```json
{
  "activeGdp": false,
  "adlID": "ADL-2026-02-02-001",
  "employeeId": "EMP12345",
  "runId": "RUN-2026-02-02-08",
  "sessionId": "SESSION-001",
  "snapshotTimestamp": "2026-02-02T08:00:00Z",
  "fosVersion": "FOS-2024.1"
}
```

**Relationships**: 1→1 with adlFlights

**Update Frequency**: High (multiple ADL feeds per day)

**Governance**: FOS-sourced, preserves FOS metadata, version controlled

#### 5.6.2 adlFlights

**Purpose**: Arrival and departure related metadata from ADL feed, reflects FOS' view of operations

**Core Fields**:
```json
{
  "adlID": "ADL-2026-02-02-001",
  "FlightKey": "AA1234-20260202-DFW-0",
  "departureFlights": {
    "scheduledDeparture": "2026-02-02T10:00:00Z",
    "estimatedDeparture": "2026-02-02T10:15:00Z",
    "actualDeparture": "2026-02-02T10:12:00Z",
    "departureGate": "D15",
    "departureStatus": "DEPARTED"
  },
  "arrivalFlights": {
    "scheduledArrival": "2026-02-02T12:30:00Z",
    "estimatedArrival": "2026-02-02T12:45:00Z",
    "actualArrival": null,
    "arrivalGate": "42A",
    "arrivalStatus": "EN_ROUTE"
  },
  "category": "SCHEDULED",
  "weightClass": "MEDIUM",
  "delayCancelFlightSlotAvailability": {
    "delayMinutes": 12,
    "cancelStatus": false,
    "slotAvailable": true
  }
}
```

**Business Rules**:
- FlightKey must match Flight domain FlightIdentity
- FOS-derived data is authoritative for ADL consumers
- Transformation rules documented for NXOP alignment

**Update Frequency**: High (updates with each ADL feed)

**Governance**: FOS alignment critical, transformation rules documented

**Domain Governance Summary**:
- **Message Flows**: Flows 1, 2, 5 (3 of 25 flows)
- **DocumentDB Collections**: 2 collections (one per entity)
- **MSK Topics**: 1 ADL topic (adl-data)

**Cross-Domain Relationships Summary**:
- Flight Domain ↔ Aircraft Domain: FlightIdentity.tailNumber → AircraftIdentity.noseNumber
- Flight Domain ↔ Station Domain: FlightIdentity.departureStation/arrivalStation → StationIdentity.iataAirlineCode
- Aircraft Domain ↔ Maintenance Domain: AircraftIdentity.noseNumber → MaintenanceRecord.tailNumber
- Flight Domain ↔ ADL Domain: FlightIdentity.flightKey → adlFlights.FlightKey
- Maintenance Domain ↔ Aircraft Domain: MaintenanceRecord.tailNumber → AircraftIdentity.noseNumber, MaintenanceDMI → AircraftMEL

---

## 6. Integration Patterns

### 6.1 Integration Pattern Overview

NXOP standardizes data exchange across 25 message flows using 7 integration patterns. These patterns reduce complexity, enable reuse, and simplify governance by providing consistent approaches for common integration scenarios.

**Pattern Benefits**:
- **Reusability**: 70% of integrations use existing patterns
- **Consistency**: Uniform approach across all vendors and systems
- **Governance**: Centralized policy enforcement
- **Velocity**: Faster vendor onboarding (< 6 months target)
- **Maintainability**: Simplified troubleshooting and monitoring

### 6.2 Pattern 1: Inbound Data Ingestion (10 flows)

**Pattern Description**: External sources → NXOP → On-Prem

**Characteristics**:
- Asynchronous ingestion from external systems
- Schema validation at ingestion point
- Transformation to NXOP canonical model
- Routing to appropriate downstream consumers
- Data quality checks and enrichment

**Flow Characteristics**:
- **Protocol**: HTTPS, AMQP, Kafka, MQ
- **Data Format**: JSON, Avro, XML
- **Latency**: < 5 seconds end-to-end
- **Throughput**: 1000+ messages/minute peak
- **Error Handling**: Retry with exponential backoff, dead letter queue

**Example Flows**:
- **Flow 2**: Receive and Publish Flight Plans from Flightkeys
  - Source: Azure FXIP (Flightkeys)
  - Protocol: AMQP
  - NXOP Processing: Validate schema, enrich with aircraft/station data, publish to MSK
  - Destination: FOS via MQ-Kafka adapter
  
- **Flow 5**: Receive and Publish Audit Logs, Weather, FK OFP Data
  - Source: Azure FXIP (Flightkeys)
  - Protocol: HTTPS
  - NXOP Processing: Parse XML/JSON, validate, route to appropriate topics
  - Destination: FOS, Analytics systems

**Governance Focus**:
- Schema validation at ingestion (Avro, JSON Schema)
- Data quality rules (completeness, accuracy, consistency)
- Lineage tracking (source → NXOP → destination)
- Monitoring and alerting (ingestion failures, validation errors)

**Infrastructure Dependencies**:
- MSK for event streaming
- DocumentDB for reference data enrichment
- Pod Identity for cross-account access
- Akamai GTM for API traffic routing

### 6.3 Pattern 2: Outbound Data Publishing (2 flows)

**Pattern Description**: On-Prem → NXOP → External systems

**Characteristics**:
- Event streaming from on-premises FOS systems
- Protocol translation (MQ → Kafka → AMQP/HTTPS)
- Enrichment with NXOP operational data
- Delivery guarantees (at-least-once)
- Consumer acknowledgment tracking

**Flow Characteristics**:
- **Protocol**: MQ → Kafka → AMQP/HTTPS
- **Data Format**: Avro, JSON
- **Latency**: < 10 seconds end-to-end
- **Throughput**: 500+ messages/minute
- **Error Handling**: Retry with backoff, alerting on persistent failures

**Example Flows**:
- **Flow 1**: Publish FOS Event Data to Flightkeys
  - Source: On-Prem FOS (OPSHUB)
  - Protocol: MQ → Kafka → AMQP
  - NXOP Processing: MQ-Kafka adapter ingests, enriches with aircraft/station data, publishes to Azure Event Hubs
  - Destination: Azure FXIP (Flightkeys Event Processors)

- **Flow 11**: Publish Flight Events to CyberJet FMS
  - Source: On-Prem FOS
  - Protocol: MQ → Kafka → HTTPS
  - NXOP Processing: Transform to CyberJet API format, authenticate, POST to CyberJet endpoints
  - Destination: CyberJet FMS (AWS)

**Governance Focus**:
- Schema compatibility (ensure consumers don't break)
- Transformation correctness (validate mappings)
- Delivery guarantees (at-least-once semantics)
- Consumer health monitoring

**Infrastructure Dependencies**:
- MQ-Kafka adapters (on-premises)
- MSK for event buffering
- Kafka Connectors for Azure Event Hubs
- Akamai GTM for external API calls

### 6.4 Pattern 3: Bidirectional Sync (6 flows)

**Pattern Description**: Two-way data synchronization between systems

**Characteristics**:
- Conflict resolution policies
- Consistency maintenance across systems
- Bidirectional lineage tracking
- Sync lag monitoring
- Eventual consistency guarantees

**Flow Characteristics**:
- **Protocol**: Varies (HTTPS, AMQP, Kafka, TCP)
- **Data Format**: JSON, Avro, Binary
- **Latency**: < 30 seconds for sync
- **Throughput**: Varies by flow
- **Error Handling**: Conflict resolution, manual intervention for complex conflicts

**Example Flows**:
- **Flow 13**: Aircraft FMS Initialization
  - Systems: NXOP ↔ CyberJet FMS
  - Protocol: HTTPS bidirectional
  - Sync: Aircraft configuration, flight plans, performance data
  - Conflict Resolution: NXOP is source of truth for aircraft config, CyberJet for FMS-specific data

- **Flow 15**: Flight Progress Reports
  - Systems: NXOP ↔ FOS ↔ CyberJet
  - Protocol: ACARS (TCP) ↔ NXOP (Kafka) ↔ CyberJet (HTTPS)
  - Sync: Real-time position updates, fuel burn, ETA updates
  - Conflict Resolution: Most recent timestamp wins

**Governance Focus**:
- Consistency rules (define authoritative source per data element)
- Conflict resolution policies (timestamp-based, source priority)
- Sync lag monitoring (alert on lag > threshold)
- Bidirectional lineage (track data flow in both directions)

**Infrastructure Dependencies**:
- MSK for event buffering
- DocumentDB for state management
- Conflict resolution service (EKS)
- Monitoring for sync lag

### 6.5 Pattern 4: Notification/Alert (3 flows)

**Pattern Description**: Event-driven notifications to multiple destinations

**Characteristics**:
- Multi-destination routing (email, SMS, push, in-app)
- Priority handling (critical, warning, info)
- Delivery confirmation tracking
- Template-based message formatting
- Subscription management

**Flow Characteristics**:
- **Protocol**: HTTPS, SMTP, SMS Gateway, Push Notification Services
- **Data Format**: JSON, HTML, Plain Text
- **Latency**: < 10 seconds for critical alerts
- **Throughput**: 100+ notifications/minute
- **Error Handling**: Retry with backoff, fallback channels

**Example Flows**:
- **Flow 7**: Flight Release Notifications
  - Trigger: Flight released by dispatcher
  - Recipients: Pilots, crew, gate agents, operations
  - Channels: Email, SMS, mobile app push
  - Priority: Critical (must deliver)

- **Flow 14**: ACARS Free Text Messages
  - Trigger: Free text message from cockpit
  - Recipients: Dispatch, maintenance, operations
  - Channels: Email, in-app notification
  - Priority: Varies (critical for emergencies, info for routine)

**Governance Focus**:
- Notification schema standards (consistent format)
- Delivery SLAs (critical < 10 sec, warning < 30 sec, info < 60 sec)
- Alert escalation policies (retry, fallback channels)
- Subscription management (opt-in/opt-out)

**Infrastructure Dependencies**:
- Notification Service (EKS)
- MSK for event triggers
- SNS/SES for email/SMS
- Mobile push notification services

### 6.6 Pattern 5: Document Assembly (1 flow)

**Pattern Description**: Multi-service document generation and assembly

**Characteristics**:
- Orchestration of multiple data sources
- Aggregation of disparate data elements
- Document formatting (PDF, HTML, XML)
- Version control and archival
- Compliance with regulatory requirements

**Flow Characteristics**:
- **Protocol**: Internal service calls (gRPC, HTTPS)
- **Data Format**: JSON (internal), PDF/HTML (output)
- **Latency**: < 60 seconds for document assembly
- **Throughput**: 50+ documents/minute
- **Error Handling**: Retry failed data fetches, partial document generation

**Example Flow**:
- **Flow 8**: Retrieve Pilot Briefing Package
  - Data Sources: Flight plan (Flightkeys), weather (DECS), NOTAMs (DECS), aircraft MEL (NXOP), load plan (FOS)
  - Orchestration: Document Assembly Service coordinates data fetches
  - Assembly: Combine data into structured briefing package
  - Format: PDF for pilot tablet, JSON for mobile app
  - Archival: Store in S3 for 7 years (FAA compliance)

**Governance Focus**:
- Document schema standards (consistent structure)
- Assembly logic validation (ensure completeness)
- Versioning (track document versions)
- Archival policies (retention, retrieval)

**Infrastructure Dependencies**:
- Document Assembly Service (EKS)
- DocumentDB for metadata
- S3 for document storage
- Multiple data source APIs

### 6.7 Pattern 6: Authorization (2 flows)

**Pattern Description**: Electronic signature workflows for compliance

**Characteristics**:
- Multi-step approval process
- Compliance requirements (FAA, company policy)
- Audit trails (who, what, when, where)
- Digital signature validation
- Non-repudiation guarantees

**Flow Characteristics**:
- **Protocol**: HTTPS, ACARS (TCP)
- **Data Format**: JSON, ACARS binary
- **Latency**: < 30 seconds for signature validation
- **Throughput**: 100+ signatures/hour
- **Error Handling**: Retry on network failure, manual fallback for critical failures

**Example Flows**:
- **Flow 9**: eSignature CCI (Crew Communication Interface)
  - Trigger: Pilot reviews flight release
  - Process: Pilot signs via tablet app
  - Validation: Verify pilot credentials, flight eligibility
  - Storage: Store signature in DocumentDB, audit trail in S3
  - Notification: Confirm to dispatch, crew, operations

- **Flow 10**: eSignature ACARS
  - Trigger: Pilot reviews flight release via ACARS
  - Process: Pilot sends signature command via ACARS
  - Validation: Verify ACARS message authenticity, pilot credentials
  - Storage: Store signature with ACARS message metadata
  - Notification: Confirm to dispatch

**Governance Focus**:
- Signature schema standards (consistent format)
- Audit logging (complete trail for compliance)
- Compliance validation (FAA requirements)
- Non-repudiation (cryptographic signatures)

**Infrastructure Dependencies**:
- Authorization Service (EKS)
- DocumentDB for signature storage
- S3 for audit trails
- ACARS gateway for cockpit communication

### 6.8 Pattern 7: Data Maintenance (1 flow)

**Pattern Description**: Reference data management and synchronization

**Characteristics**:
- Master data updates from authoritative sources
- Synchronization across multiple systems
- Versioning and change tracking
- Distribution to consumers
- Validation and quality checks

**Flow Characteristics**:
- **Protocol**: HTTPS, Kafka
- **Data Format**: JSON, Avro
- **Latency**: < 5 minutes for reference data updates
- **Throughput**: Low volume, high importance
- **Error Handling**: Validation before distribution, rollback on errors

**Example Flow**:
- **Flow 16**: Ops Engineering Fleet/Reference Data
  - Source: Operations Engineering systems
  - Data Types: Aircraft configurations, airport data, performance tables, MEL items
  - Process: Validate data quality, version control, distribute to NXOP and FOS
  - Consumers: Flight planning, performance calculations, dispatch
  - Validation: Schema validation, business rule checks, cross-reference validation

**Governance Focus**:
- Master data quality (completeness, accuracy, consistency)
- Change tracking (audit trail of all changes)
- Distribution (ensure all consumers receive updates)
- Versioning (track data versions across systems)

**Infrastructure Dependencies**:
- Data Maintenance Service (EKS)
- DocumentDB for reference data storage
- MSK for change event distribution
- Data quality validation service

---

## 7. Message Flows

### 7.1 Message Flow Catalog

NXOP supports 25 distinct message flows across 7 integration patterns. Each flow represents a specific business process with defined source systems, NXOP processing, and destination systems.

**Flow Classification**:
- **Criticality**: Vital (flight safety), Critical (operations), Discretionary (analytics)
- **Resilience**: HA Automated, Regional Switchover, Manual Intervention
- **Latency**: Real-time (< 5 sec), Near real-time (< 30 sec), Batch (< 5 min)

### 7.2 Complete Flow Catalog

**Flow 1: Publish FOS Event Data to Flightkeys**
- **Pattern**: Outbound Data Publishing
- **Source**: On-Prem FOS (OPSHUB)
- **Protocol**: MQ → Kafka → AMQP
- **NXOP Components**: MQ-Kafka Adapter, MSK, Kafka Connector (Azure)
- **Destination**: Azure FXIP (Flightkeys Event Processors)
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, DocumentDB (enrichment), Pod Identity, Kafka Connector

**Flow 2: Receive and Publish Flight Plans from Flightkeys**
- **Pattern**: Inbound Data Ingestion
- **Source**: Azure FXIP (Flightkeys)
- **Protocol**: AMQP → Kafka → MQ
- **NXOP Components**: AMQP Listener, MSK, MQ-Kafka Adapter
- **Destination**: On-Prem FOS
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 5 seconds
- **Dependencies**: MSK, DocumentDB (validation), Pod Identity

**Flow 3: Receive Flight Plan Updates**
- **Pattern**: Inbound Data Ingestion
- **Source**: Azure FXIP (Flightkeys)
- **Protocol**: AMQP → Kafka
- **NXOP Components**: AMQP Listener, MSK, Flight Data Adapter
- **Destination**: DocumentDB (FlightTimes, FlightLeg)
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 5 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 4: Receive Aircraft Updates**
- **Pattern**: Inbound Data Ingestion
- **Source**: Azure FXIP (Flightkeys)
- **Protocol**: AMQP → Kafka
- **NXOP Components**: AMQP Listener, MSK, Aircraft Data Adapter
- **Destination**: DocumentDB (AircraftLocation, AircraftPerformance)
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 5 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 5: Receive and Publish Audit Logs, Weather, FK OFP Data**
- **Pattern**: Inbound Data Ingestion
- **Source**: Azure FXIP (Flightkeys)
- **Protocol**: HTTPS → Kafka → MQ
- **NXOP Components**: HTTPS API, MSK, MQ-Kafka Adapter
- **Destination**: On-Prem FOS, S3 (archival)
- **Criticality**: Critical
- **Resilience**: Regional Switchover
- **Latency**: < 30 seconds
- **Dependencies**: MSK, S3, Akamai GTM, Pod Identity

**Flow 6: Receive Station/Airport Updates**
- **Pattern**: Inbound Data Ingestion
- **Source**: Azure FXIP, External Airport Data Providers
- **Protocol**: HTTPS → Kafka
- **NXOP Components**: HTTPS API, MSK, Station Data Adapter
- **Destination**: DocumentDB (StationIdentity, StationGeo, StationAuthorization)
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 5 minutes (not real-time)
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 7: Flight Release Notifications**
- **Pattern**: Notification/Alert
- **Source**: On-Prem FOS (Dispatch)
- **Protocol**: MQ → Kafka → HTTPS/SMTP/SMS
- **NXOP Components**: MQ-Kafka Adapter, MSK, Notification Service
- **Destination**: Pilots (email, SMS, app), Crew, Gate Agents, Operations
- **Criticality**: Vital
- **Resilience**: HA Automated with fallback channels
- **Latency**: < 10 seconds
- **Dependencies**: MSK, Notification Service, SNS/SES, Pod Identity

**Flow 8: Retrieve Pilot Briefing Package**
- **Pattern**: Document Assembly
- **Source**: Multiple (Flightkeys, DECS, NXOP, FOS)
- **Protocol**: Internal service calls (gRPC, HTTPS)
- **NXOP Components**: Document Assembly Service, DocumentDB, S3
- **Destination**: Pilot tablet, mobile app
- **Criticality**: Vital
- **Resilience**: Regional Switchover
- **Latency**: < 60 seconds
- **Dependencies**: DocumentDB, S3, Multiple APIs, Pod Identity

**Flow 9: eSignature CCI (Crew Communication Interface)**
- **Pattern**: Authorization
- **Source**: Pilot tablet app
- **Protocol**: HTTPS → Kafka
- **NXOP Components**: Authorization Service, MSK, DocumentDB
- **Destination**: DocumentDB (signature storage), S3 (audit trail), Dispatch (notification)
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 30 seconds
- **Dependencies**: DocumentDB, S3, MSK, Pod Identity

**Flow 10: eSignature ACARS**
- **Pattern**: Authorization
- **Source**: Aircraft ACARS
- **Protocol**: ACARS (TCP) → Kafka
- **NXOP Components**: ACARS Gateway, MSK, Authorization Service, DocumentDB
- **Destination**: DocumentDB (signature storage), S3 (audit trail), Dispatch (notification)
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 30 seconds
- **Dependencies**: MSK, DocumentDB, S3, ACARS Gateway, Pod Identity

**Flow 11: Publish Flight Events to CyberJet FMS**
- **Pattern**: Outbound Data Publishing
- **Source**: On-Prem FOS
- **Protocol**: MQ → Kafka → HTTPS
- **NXOP Components**: MQ-Kafka Adapter, MSK, CyberJet Adapter
- **Destination**: CyberJet FMS (AWS)
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, Akamai GTM, Pod Identity

**Flow 12: Receive Weather Updates**
- **Pattern**: Inbound Data Ingestion
- **Source**: External Weather Services
- **Protocol**: HTTPS → Kafka
- **NXOP Components**: Weather Adapter, MSK
- **Destination**: DocumentDB, S3, FOS
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 30 seconds
- **Dependencies**: MSK, DocumentDB, S3, Akamai GTM

**Flow 13: Aircraft FMS Initialization**
- **Pattern**: Bidirectional Sync
- **Source/Destination**: NXOP ↔ CyberJet FMS
- **Protocol**: HTTPS bidirectional
- **NXOP Components**: FMS Sync Service, DocumentDB
- **Data**: Aircraft configuration, flight plans, performance data
- **Criticality**: Vital
- **Resilience**: Regional Switchover
- **Latency**: < 30 seconds
- **Dependencies**: DocumentDB, Akamai GTM, Pod Identity

**Flow 14: ACARS Free Text Messages**
- **Pattern**: Notification/Alert
- **Source**: Aircraft ACARS
- **Protocol**: ACARS (TCP) → Kafka → HTTPS/Email
- **NXOP Components**: ACARS Gateway, MSK, Notification Service
- **Destination**: Dispatch, Maintenance, Operations
- **Criticality**: Critical (varies by message)
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, ACARS Gateway, Notification Service, Pod Identity

**Flow 15: Flight Progress Reports**
- **Pattern**: Bidirectional Sync
- **Source/Destination**: Aircraft ACARS ↔ NXOP ↔ CyberJet ↔ FOS
- **Protocol**: ACARS (TCP) ↔ Kafka ↔ HTTPS ↔ MQ
- **NXOP Components**: ACARS Gateway, MSK, Flight Data Adapter, DocumentDB
- **Data**: Position updates, fuel burn, ETA updates
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 15 seconds
- **Dependencies**: MSK, DocumentDB, ACARS Gateway, Pod Identity

**Flow 16: Ops Engineering Fleet/Reference Data**
- **Pattern**: Data Maintenance
- **Source**: Operations Engineering systems
- **Protocol**: HTTPS → Kafka
- **NXOP Components**: Data Maintenance Service, MSK, DocumentDB
- **Destination**: NXOP (DocumentDB), FOS (MQ)
- **Data**: Aircraft configurations, airport data, performance tables, MEL items
- **Criticality**: Critical
- **Resilience**: Manual Intervention (low frequency)
- **Latency**: < 5 minutes
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 17: Maintenance Event Processing**
- **Pattern**: Inbound Data Ingestion
- **Source**: On-Prem FOS (OPSHUB Maintenance)
- **Protocol**: MQ → Kafka
- **NXOP Components**: MQ-Kafka Adapter, MSK, Maintenance Data Adapter
- **Destination**: DocumentDB (Maintenance Domain collections)
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 18: Analytics Data Export**
- **Pattern**: Outbound Data Publishing
- **Source**: NXOP (DocumentDB, S3)
- **Protocol**: Batch export to S3 Iceberg tables
- **NXOP Components**: Analytics Export Service, S3
- **Destination**: Databricks, Orion Analytics Platform
- **Criticality**: Discretionary
- **Resilience**: Manual Intervention
- **Latency**: < 1 hour (batch)
- **Dependencies**: DocumentDB, S3, Pod Identity

**Flow 19: Real-Time Metrics Streaming**
- **Pattern**: Outbound Data Publishing
- **Source**: NXOP (MSK)
- **Protocol**: Kafka → Kinesis Data Streams
- **NXOP Components**: Kinesis Connector, MSK
- **Destination**: Real-time dashboards, monitoring systems
- **Criticality**: Discretionary
- **Resilience**: HA Automated
- **Latency**: < 5 seconds
- **Dependencies**: MSK, Kinesis, Pod Identity

**Flow 20: Load Planning Integration**
- **Pattern**: Bidirectional Sync
- **Source/Destination**: NXOP ↔ FOS Load Planning
- **Protocol**: MQ ↔ Kafka ↔ HTTPS
- **NXOP Components**: MQ-Kafka Adapter, MSK, Load Planning Adapter, DocumentDB
- **Data**: Passenger counts, bag counts, cargo weights, load plans
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 21: Crew Assignment Updates**
- **Pattern**: Inbound Data Ingestion
- **Source**: Azure FXIP (Crew Management)
- **Protocol**: AMQP → Kafka
- **NXOP Components**: AMQP Listener, MSK, Crew Data Adapter
- **Destination**: DocumentDB (crew assignments), FOS
- **Criticality**: Critical
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 22: Takeoff Performance Calculations**
- **Pattern**: Bidirectional Sync
- **Source/Destination**: NXOP ↔ FOS Takeoff Performance
- **Protocol**: MQ ↔ Kafka ↔ HTTPS
- **NXOP Components**: MQ-Kafka Adapter, MSK, Performance Adapter, DocumentDB
- **Data**: Runway data, aircraft performance, weather, calculated takeoff parameters
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 15 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 23: NOTAM Distribution**
- **Pattern**: Inbound Data Ingestion
- **Source**: External NOTAM providers, FOS DECS
- **Protocol**: HTTPS → Kafka
- **NXOP Components**: NOTAM Adapter, MSK, DocumentDB
- **Destination**: DocumentDB, Pilot briefing packages, FOS
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 30 seconds
- **Dependencies**: MSK, DocumentDB, Akamai GTM

**Flow 24: Fuel Planning Integration**
- **Pattern**: Bidirectional Sync
- **Source/Destination**: NXOP ↔ FOS Fuel Planning
- **Protocol**: MQ ↔ Kafka ↔ HTTPS
- **NXOP Components**: MQ-Kafka Adapter, MSK, Fuel Planning Adapter, DocumentDB
- **Data**: Fuel requirements, fuel prices, fuel availability, actual fuel loaded
- **Criticality**: Vital
- **Resilience**: HA Automated
- **Latency**: < 10 seconds
- **Dependencies**: MSK, DocumentDB, Pod Identity

**Flow 25: Regulatory Compliance Reporting**
- **Pattern**: Outbound Data Publishing
- **Source**: NXOP (DocumentDB, S3)
- **Protocol**: Batch export to S3
- **NXOP Components**: Compliance Export Service, S3
- **Destination**: FAA reporting systems, internal compliance systems
- **Criticality**: Critical
- **Resilience**: Manual Intervention (scheduled batch)
- **Latency**: < 24 hours (daily batch)
- **Dependencies**: DocumentDB, S3, Pod Identity

---

## 8. Infrastructure Components

### 8.1 MSK (Managed Streaming for Kafka)

**Purpose**: Event streaming backbone for 6 MSK-dependent flows (24% of all flows)

**Architecture**:
- **Regions**: us-east-1 (primary), us-west-2 (secondary)
- **Brokers**: 3 per region across 3 AZs
- **Broker Type**: kafka.m5.2xlarge (8 vCPU, 32 GB RAM)
- **Storage**: 1 TB EBS per broker (gp3)
- **Encryption**: TLS in transit, encryption at rest with AWS KMS
- **Authentication**: IAM authentication for producers/consumers

**Cross-Region Replication**:
- **Type**: Bidirectional (us-east-1 ↔ us-west-2)
- **Lag**: < 1 second (target)
- **Monitoring**: CloudWatch metrics for replication lag, throughput, errors
- **Failover**: Route53 DNS failover (< 10 min RTO)

**Topics**: 50+ Kafka topics organized by domain and carrier
- **Flight Domain**: 40+ topics (flight-event-*, soar-aa-flightplan-*)
- **Aircraft Domain**: 9 topics (aircraft-snapshot-*, aircraft-update-*)
- **Station Domain**: 3 topics (airport-event-*, airport-update-*)
- **Maintenance Domain**: 1 topic (internal-maintenanceevents-avro)
- **ADL Domain**: 1 topic (adl-data)

**Topic Retention Policies**:
- **1 day**: Aircraft snapshots and updates (operational data, high volume)
- **3 days**: Flight events, airport events (operational data, moderate volume)
- **72 hours**: Internal events from OpsHub On-Prem, SOAR flight plans, ADL data (compliance, audit trail)

**Partition Strategy**:
- **4 partitions**: Low-volume topics (init events, airport events)
- **8 partitions**: Medium-volume topics (aircraft events, maintenance events)
- **12 partitions**: High-volume topics (future flight events, ADL data)
- **16 partitions**: Very high-volume topics (flight events for AA carrier)
- **32 partitions**: Extremely high-volume topics (internal flight events from OpsHub)

**Route53 DNS Routing**:
- **DNS Name**: kafka.nxop.com
- **Routing Policy**: Health-based failover
- **Primary**: nxop-msk-nlb-east.internal (us-east-1)
- **Secondary**: nxop-msk-nlb-west.internal (us-west-2)
- **TTL**: 60 seconds (fast failover)

### 8.2 DocumentDB Global Clusters

**Purpose**: Operational data storage for 5 DocumentDB-dependent flows (20% of all flows)

**Architecture**:
- **Regions**: us-east-1 (primary), us-west-2 (secondary)
- **Instance Type**: r6g.2xlarge (8 vCPU, 64 GB RAM)
- **Instances per Region**: 3 (1 primary, 2 replicas across AZs)
- **Storage**: Encrypted at rest with AWS KMS
- **Backup**: Automated daily backups with 35-day retention
- **Replication Lag**: < 1 second between regions

**Collections**: 24 collections across 5 domains
- **Flight Domain**: 7 collections (FlightIdentity, FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning)
- **Aircraft Domain**: 5 collections (AircraftIdentity, AircraftConfiguration, AircraftLocation, AircraftPerformance, AircraftMEL)
- **Station Domain**: 4 collections (StationIdentity, StationGeo, StationAuthorization, StationMetadata)
- **Maintenance Domain**: 6 collections (MaintenanceRecord, MaintenanceDMI, MaintenanceEquipment, MaintenanceLandingData, MaintenanceOTS, MaintenanceEventHistory)
- **ADL Domain**: 2 collections (adlHeader, adlFlights)

**Access Patterns**:
- **Read-Heavy**: Reference data (aircraft configs, station data) - 80% reads, 20% writes
- **Write-Heavy**: Event data (flight events, position updates) - 30% reads, 70% writes
- **Mixed**: Operational data (flight times, aircraft location) - 50% reads, 50% writes

**Failover Strategy**:
- **Automatic Failover**: < 1 minute RTO for DocumentDB Global Cluster
- **Application Reconnect**: Automatic reconnection to new primary
- **Data Consistency**: Zero data loss (RPO = 0)

### 8.3 S3 + Apache Iceberg

**Purpose**: Analytics data storage with ACID transactions and time travel

**Architecture**:
- **Storage Class**: S3 Intelligent-Tiering (automatic cost optimization)
- **Lifecycle Policies**: Transition to Glacier after 90 days
- **Partitioning**: By date, carrier, flight number
- **Compression**: Parquet with Snappy compression
- **Encryption**: Server-side encryption with AWS KMS

**Iceberg Tables**:
- **Flight History**: Years of operational flight data
- **OTP Metrics**: On-time performance aggregations
- **Fuel Efficiency**: Fuel consumption analytics
- **Compliance Archives**: 7-year retention for FAA

**Access Patterns**:
- **Batch Reads**: Analytics workloads (Databricks, Orion)
- **Append-Only Writes**: From operational systems
- **Time-Series Queries**: Trend analysis and historical comparisons

### 8.4 Confluent Schema Registry

**Purpose**: Avro schema management for MSK topics

**Deployment**:
- **Regions**: us-east-1, us-west-2 with replication
- **Compatibility Mode**: Backward compatibility (default)
- **Schema Versioning**: Semantic versioning (major.minor.patch)
- **Total Subjects**: 100+ (50+ topics × 2 subjects per topic: key + value)

**Schema Evolution**:
- **Allowed Changes**: Add optional fields, remove optional fields, widen types
- **Forbidden Changes**: Remove required fields, change types incompatibly, rename fields
- **Breaking Changes**: Require new topic with version suffix

**CI/CD Integration**:
- **Validation**: Automated syntax and compatibility checks
- **Deployment**: Automated registration on merge to main
- **Documentation**: Auto-generated from schemas

### 8.5 Akamai Global Traffic Manager (GTM)

**Purpose**: Routes external API traffic to healthy region

**Features**:
- **Health-Based Routing**: Monitors endpoint availability
- **Geographic Routing**: Routes to nearest region
- **DDoS Protection**: Rate limiting and attack mitigation
- **Automatic Failover**: Between us-east-1 and us-west-2

**Configuration**:
- **Health Checks**: Every 30 seconds
- **Failover Threshold**: 3 consecutive failures
- **TTL**: 60 seconds for DNS records
- **Load Balancing**: Weighted round-robin

---

## 9. Security & Identity

### 9.1 Pod Identity Architecture

**Purpose**: Enable secure, credential-free authentication for EKS workloads to access NXOP resources

**Dual-Role Pattern**:

**Role 1: KPaaS Account Role (Intermediate)**
- Created by KPaaS Team
- Assumed directly by EKS pod via IRSA
- Trust Policy: EKS OIDC Provider
- Permissions: AssumeRole for NXOP account roles

**Role 2: NXOP Account Role (Target)**
- Created by NXOP Team
- Grants actual permissions to NXOP resources
- Trust Policy: KPaaS Account Root with conditions
- Permissions: Least-privilege access to specific resources

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
      },
      "StringLike": {
        "aws:RequestTag/eks-cluster-arn": "arn:aws:eks:*:285282426848:cluster/*"
      }
    }
  }]
}
```

**Security Benefits**:
- No static credentials stored in pods
- Automatic credential rotation (1-hour expiration)
- Full audit trail via CloudTrail
- Least-privilege access per pod
- Fine-grained access control with conditions

**Governance**:
- Role creation requires joint approval (NXOP + KPaaS security teams)
- Impact analysis for all 25 message flows
- Monitoring for authentication failures
- Quarterly access reviews

### 9.2 Encryption

**Data at Rest**:
- **DocumentDB**: Encrypted with AWS KMS customer-managed keys
- **MSK**: Encrypted with AWS KMS customer-managed keys
- **S3**: Server-side encryption with AWS KMS
- **EBS Volumes**: Encrypted with AWS KMS

**Data in Transit**:
- **MSK**: TLS 1.2+ for all producer/consumer connections
- **DocumentDB**: TLS 1.2+ for all client connections
- **HTTPS APIs**: TLS 1.2+ with strong cipher suites
- **AMQP**: TLS 1.2+ for Azure Event Hubs connections

**Key Management**:
- **KMS Keys**: Customer-managed keys with automatic rotation
- **Key Policies**: Least-privilege access
- **Audit**: CloudTrail logs all key usage
- **Backup**: Automated key backup and recovery

### 9.3 Network Security

**VPC Architecture**:
- **Private Subnets**: All NXOP resources in private subnets
- **Public Subnets**: Only load balancers and NAT gateways
- **Security Groups**: Least-privilege ingress/egress rules
- **NACLs**: Additional layer of network filtering

**Transit Gateway**:
- **Purpose**: Connects KPaaS VPC to NXOP VPC
- **Routing**: Centralized routing policies
- **Security**: VPC-to-VPC isolation
- **Monitoring**: VPC Flow Logs for all traffic

**Firewall Rules**:
- **Ingress**: Only from trusted sources (KPaaS, Azure FXIP, On-Prem)
- **Egress**: Only to required destinations
- **Monitoring**: GuardDuty for threat detection
- **Alerting**: Security Hub for centralized alerts

---

## 10. Resilience & Disaster Recovery

### 10.1 Multi-Region Failover Strategy

**Objective**: < 10 minute RTO for regional failover with zero data loss (RPO = 0)

**Phase 0: Continuous Health Monitoring**
- **Monitoring**: CloudWatch, Prometheus, Akamai GTM health checks
- **Metrics**: API latency, MSK lag, DocumentDB replication lag, error rates
- **Alerting**: PagerDuty for critical failures
- **Frequency**: Every 30 seconds

**Phase 1: MSK and DocumentDB Failover (< 5 minutes)**
- **MSK**: Route53 DNS updates kafka.nxop.com → us-west-2 NLB
- **DocumentDB**: Automatic promotion of us-west-2 to primary
- **Validation**: Health checks confirm new primary operational
- **Rollback**: Automatic rollback if validation fails

**Phase 2: API and Application Failover (< 3 minutes)**
- **Akamai GTM**: Routes API traffic to us-west-2
- **AMQP Listeners**: Reconnect to Flightkeys from us-west-2
- **Kafka Connectors**: Reconnect to MSK in us-west-2
- **EKS Pods**: Auto-reconnect to new MSK/DocumentDB endpoints

**Phase 3: Validation (< 2 minutes)**
- **Flow Validation**: Verify all 25 flows operational in us-west-2
- **Data Consistency**: Validate no data loss during failover
- **Performance**: Confirm latency and throughput within SLAs
- **Notification**: Alert stakeholders of successful failover

**Failover Testing**:
- **Frequency**: Quarterly chaos engineering exercises
- **Scope**: Full regional failover simulation
- **Validation**: All 25 flows must pass validation
- **Documentation**: Runbooks updated after each test

### 10.2 Backup and Recovery

**DocumentDB Backups**:
- **Automated Backups**: Daily snapshots with 35-day retention
- **Point-in-Time Recovery**: Up to 35 days
- **Cross-Region Backup**: Snapshots replicated to us-west-2
- **Recovery Testing**: Monthly recovery drills

**S3 Backups**:
- **Versioning**: Enabled for all buckets
- **Cross-Region Replication**: To us-west-2
- **Lifecycle Policies**: Transition to Glacier after 90 days
- **Compliance**: 7-year retention for FAA requirements

**MSK Backups**:
- **Topic Retention**: 1-3 days for operational topics
- **Long-Term Archival**: S3 for compliance topics
- **Replay Capability**: Event replay from S3 archives

### 10.3 High Availability

**MSK High Availability**:
- **Broker Failures**: Automatic replacement by MSK
- **AZ Failures**: Replicas in other AZs take over
- **Regional Failures**: Route53 DNS failover to us-west-2

**DocumentDB High Availability**:
- **Instance Failures**: Automatic promotion of replica
- **AZ Failures**: Replicas in other AZs available
- **Regional Failures**: Global Cluster promotes us-west-2

**EKS High Availability**:
- **Pod Failures**: Kubernetes restarts failed pods
- **Node Failures**: Pods rescheduled to healthy nodes
- **AZ Failures**: Pods distributed across multiple AZs

---

## 11. Monitoring & Observability

### 11.1 CloudWatch

**Metrics**:
- **Custom Metrics**: All services emit custom metrics (latency, throughput, errors)
- **Infrastructure Metrics**: MSK, DocumentDB, EKS, S3
- **Application Metrics**: Per-service metrics (request count, error rate, latency percentiles)

**Logs**:
- **Centralized Logging**: All services log to CloudWatch Logs
- **Log Groups**: Per service with retention policies
- **Log Insights**: Query and analyze logs
- **Alerting**: Metric filters trigger alarms

**Dashboards**:
- **Operational Dashboard**: Real-time view of all 25 flows
- **Domain Dashboards**: Per-domain metrics (Flight, Aircraft, Station, Maintenance, ADL)
- **Infrastructure Dashboard**: MSK, DocumentDB, EKS health
- **Executive Dashboard**: High-level KPIs and SLAs

### 11.2 Prometheus + Grafana

**Prometheus**:
- **Metrics Collection**: Scrapes metrics from EKS pods
- **Retention**: 30 days in Prometheus
- **Long-Term Storage**: CloudWatch for historical analysis
- **Alerting**: Alert Manager for complex rules

**Grafana**:
- **Visualization**: Detailed dashboards for each service
- **Alerting**: Integration with PagerDuty
- **Annotations**: Mark deployments and incidents
- **Templating**: Reusable dashboard templates

### 11.3 Distributed Tracing

**X-Ray**:
- **End-to-End Tracing**: Trace requests across all services
- **Service Map**: Visual representation of dependencies
- **Performance Analysis**: Identify bottlenecks and latency
- **Error Analysis**: Root cause analysis for failures

**Trace Sampling**:
- **Production**: 1% sampling for normal traffic, 100% for errors
- **Non-Production**: 10% sampling
- **Critical Flows**: 100% sampling for vital flows

---

## 12. Migration Strategy

### 12.1 Phased Approach

**Phase 1: Foundation (Months 1-9)**
- Establish NXOP platform infrastructure
- Onboard foundation FOS vendors (DECS, Load Planning)
- Implement core message flows (Flows 1-10)
- Parallel operation with legacy systems

**Phase 2: Expansion (Months 10-15)**
- Onboard extended FOS vendors (Takeoff Performance, Crew Management)
- Implement additional message flows (Flows 11-20)
- Gradual consumer migration from legacy to NXOP
- Performance optimization and tuning

**Phase 3: Completion (Months 16-18+)**
- Onboard remaining FOS vendors
- Implement final message flows (Flows 21-25)
- Complete consumer migration
- Legacy system sunset

### 12.2 Parallel Operation

**Dual-Write Strategy**:
- Write to both legacy and NXOP systems
- Validate data consistency
- Gradual consumer migration
- Rollback capability maintained

**Data Consistency Validation**:
- Automated comparison of legacy vs. NXOP data
- Alerting on discrepancies
- Manual reconciliation for critical differences
- Continuous monitoring during transition

---

## 13. Operational Procedures

### 13.1 Schema Change Process

**Step 1: Proposal**
- Developer proposes schema change in Git
- Impact analysis identifies affected flows
- Data Steward reviews business impact

**Step 2: Validation**
- CI/CD pipeline validates syntax and compatibility
- Automated tests verify backward compatibility
- Impact analysis across all 25 flows

**Step 3: Approval**
- Data Steward approves business impact
- NXOP Platform Team approves technical implementation
- Governance Council approves if cross-domain or high-impact

**Step 4: Deployment**
- Schema registered in Confluent Schema Registry
- Schema replicated to us-west-2
- Documentation updated in Data Catalog
- Consumers notified of new schema version

### 13.2 Vendor Onboarding

**Step 1: Requirements Gathering**
- Vendor provides integration requirements
- NXOP team identifies applicable integration pattern
- Data mapping documented

**Step 2: Development**
- Adapter developed following integration pattern
- Schema defined and registered
- Automated tests implemented

**Step 3: Testing**
- Non-prod testing with sample data
- Performance testing under load
- Failover testing

**Step 4: Production Deployment**
- Gradual rollout with monitoring
- Validation of all affected flows
- Rollback plan ready

**Target**: < 6 months from requirements to production

### 13.3 Incident Response

**Severity Levels**:
- **P1 (Critical)**: Vital flows down, immediate response required
- **P2 (High)**: Critical flows degraded, response within 1 hour
- **P3 (Medium)**: Discretionary flows affected, response within 4 hours
- **P4 (Low)**: Minor issues, response within 24 hours

**Response Process**:
1. Detection: Automated monitoring alerts on-call engineer
2. Triage: Assess severity and impact
3. Mitigation: Implement immediate fix or workaround
4. Communication: Notify stakeholders
5. Resolution: Implement permanent fix
6. Post-Mortem: Document lessons learned

---

## 14. Data Governance Framework

### 14.1 Three-Tier Governance Model

**Tier 1: Enterprise Data Governance**
- **Owner**: Chief Data Officer (Todd Waller)
- **Scope**: Enterprise-wide data strategy and canonical models
- **Responsibilities**:
  - Define enterprise data standards
  - Maintain canonical data models
  - Resolve cross-domain conflicts
  - Align NXOP with enterprise strategy

**Tier 2: NXOP Domain Governance**
- **Owner**: NXOP Platform Lead (Kevin - Co-Chair)
- **Scope**: NXOP-specific data domains and operational models
- **Responsibilities**:
  - Define NXOP data domains (Flight, Aircraft, Station, Maintenance, ADL)
  - Manage domain data models and schemas
  - Coordinate with Data Stewards
  - Enforce data quality standards

**Tier 3: Vendor Integration Governance**
- **Owner**: FOS Integration Team
- **Scope**: Vendor-specific integrations and transformations
- **Responsibilities**:
  - Onboard FOS vendors
  - Define transformation rules
  - Maintain vendor-specific metadata
  - Ensure vendor compliance with standards

### 14.2 Governance Bodies

**Joint Governance Council**
- **Chair**: Todd Waller (Enterprise Data Strategy)
- **Co-Chair**: Kevin (Operations Data Strategy)
- **Members**: NXOP Platform Lead, Scott (Architecture), Prem (Physical Design), Data Stewards (5), Business Stakeholders
- **Meeting Cadence**: Weekly (Months 1-3), Bi-weekly (Months 4-12), Monthly (Months 13+)
- **Responsibilities**:
  - Approve data governance policies
  - Resolve cross-domain conflicts
  - Approve major schema changes
  - Review and approve tool selections
  - Quarterly scope and priority reviews

**Platform Architecture Board**
- **Chair**: Scott (Architecture)
- **Members**: NXOP Platform Team, KPaaS Team, Security Team
- **Meeting Cadence**: Bi-weekly
- **Responsibilities**:
  - Review technical architecture decisions
  - Approve infrastructure changes
  - Evaluate new technologies
  - Ensure architectural consistency

**Vendor Integration Working Group**
- **Chair**: FOS Integration Team Lead
- **Members**: Vendor representatives, NXOP integration engineers
- **Meeting Cadence**: Weekly during vendor onboarding, monthly during steady-state
- **Responsibilities**:
  - Coordinate vendor onboarding
  - Resolve integration issues
  - Share best practices
  - Track vendor compliance

**Domain Data Steward Meetings**
- **Participants**: Data Stewards for each domain
- **Meeting Cadence**: Monthly
- **Responsibilities**:
  - Review domain-specific data quality
  - Coordinate cross-domain dependencies
  - Share lessons learned
  - Escalate issues to Governance Council

### 14.3 Roles and Responsibilities

**Enterprise Data Strategist (Todd Waller)**
- Define enterprise data strategy
- Maintain canonical data models
- Chair Governance Council
- Resolve strategic conflicts

**Operations Data Strategist (Kevin)**
- Define NXOP operational data strategy
- Co-chair Governance Council
- Coordinate with Data Stewards
- Align NXOP with operational needs

**NXOP Platform Lead**
- Overall platform accountability
- Resource allocation
- Stakeholder management
- Escalation point for critical issues

**Data Architect (Scott)**
- Define logical data models
- Chair Platform Architecture Board
- Ensure architectural consistency
- Review schema changes

**Physical Design Lead (Prem)**
- Implement physical data models
- Optimize database performance
- Manage infrastructure capacity
- Implement backup and recovery

**Data Stewards (5 - one per domain)**
- **Flight Domain Steward**: Flight Operations team member
- **Aircraft Domain Steward**: Fleet Management team member
- **Station Domain Steward**: Network Planning team member
- **Maintenance Domain Steward**: Maintenance Operations team member
- **ADL Domain Steward**: FOS Integration team member

**Responsibilities**:
- Define domain business rules
- Approve domain schema changes
- Monitor domain data quality
- Coordinate with consumers

**NXOP Platform Team (15-20 engineers)**
- Develop and operate NXOP platform
- Implement data adapters and services
- Monitor and troubleshoot issues
- Implement schema changes

**KPaaS Team**
- Manage EKS infrastructure
- Approve Pod Identity roles
- Monitor cluster health
- Coordinate with NXOP team

### 14.4 Decision Matrices

**Schema Change Approval Matrix**:

| Change Type | Data Steward | NXOP Platform | Governance Council |
|-------------|--------------|---------------|-------------------|
| Add optional field | Approve | Implement | Inform |
| Remove optional field | Approve | Implement | Inform |
| Add required field | Approve | Implement | Approve (if cross-domain) |
| Remove required field | Approve | Implement | Approve |
| Change field type | Approve | Implement | Approve |
| Rename field | Approve | Implement | Approve |
| New entity | Approve | Implement | Approve (if cross-domain) |
| Delete entity | Approve | Implement | Approve |

**Infrastructure Change Approval Matrix**:

| Change Type | NXOP Platform | KPaaS Team | Security Team | Governance Council |
|-------------|---------------|------------|---------------|-------------------|
| Add MSK topic | Approve | Inform | Inform | Inform |
| Add DocumentDB collection | Approve | Inform | Inform | Inform |
| Change retention policy | Approve | Inform | Inform | Approve (if compliance impact) |
| Add Pod Identity role | Request | Approve | Approve | Inform |
| Modify Pod Identity role | Request | Approve | Approve | Inform |
| Regional failover test | Approve | Coordinate | Inform | Inform |
| Production deployment | Approve | Coordinate | Review | Inform |

**Vendor Onboarding Approval Matrix**:

| Phase | FOS Integration | NXOP Platform | Data Steward | Governance Council |
|-------|-----------------|---------------|--------------|-------------------|
| Requirements | Lead | Review | Review | Inform |
| Design | Lead | Approve | Approve | Approve (if new pattern) |
| Development | Lead | Support | Review | Inform |
| Testing | Lead | Support | Validate | Inform |
| Production | Lead | Approve | Approve | Inform |

### 14.5 Change Request Process

**Step 1: Submission**
- Requester submits change request via Jira
- Includes: Description, justification, impact analysis, timeline

**Step 2: Triage**
- NXOP Platform Team triages within 24 hours
- Assigns to appropriate Data Steward or team
- Determines approval path based on decision matrix

**Step 3: Impact Analysis**
- Automated analysis identifies affected flows (out of 25)
- Manual analysis for cross-domain impacts
- Risk assessment (low, medium, high)

**Step 4: Approval**
- Routed to appropriate approvers per decision matrix
- Approvers have 3 business days to respond
- Escalation to Governance Council if no response

**Step 5: Implementation**
- Assigned to NXOP Platform Team
- Implemented following standard procedures
- Tested in non-prod before production

**Step 6: Validation**
- Automated tests validate change
- Data Steward validates business impact
- Production monitoring for 48 hours

**Step 7: Closure**
- Change documented in Data Catalog
- Stakeholders notified
- Lessons learned captured

**Target Timelines**:
- **Operational Changes**: < 2 weeks (non-breaking)
- **Breaking Changes**: < 4 weeks
- **New Entities/Domains**: < 8 weeks

### 14.6 Data Quality Framework

**Data Quality Dimensions**:
- **Completeness**: All required fields populated
- **Accuracy**: Data matches source of truth
- **Consistency**: Data consistent across systems
- **Timeliness**: Data available within SLA
- **Validity**: Data conforms to business rules
- **Uniqueness**: No duplicate records

**Data Quality Metrics**:
- **Completeness Score**: % of required fields populated
- **Accuracy Score**: % of records matching source of truth
- **Consistency Score**: % of records consistent across systems
- **Timeliness Score**: % of records delivered within SLA
- **Validity Score**: % of records passing validation rules
- **Uniqueness Score**: % of records without duplicates

**Target Scores**:
- **Completeness**: > 99.5%
- **Accuracy**: > 99.5%
- **Consistency**: > 99%
- **Timeliness**: > 99.9%
- **Validity**: > 99.9%
- **Uniqueness**: > 99.9%

**Data Quality Monitoring**:
- **Real-Time**: Validation at ingestion point
- **Batch**: Daily data quality reports
- **Alerting**: Immediate alerts for critical failures
- **Dashboard**: Real-time data quality dashboard

**Data Quality Remediation**:
- **Automated**: Automatic correction for known issues
- **Manual**: Data Steward review for complex issues
- **Root Cause Analysis**: Identify and fix source of issues
- **Continuous Improvement**: Regular review and optimization

### 14.7 Compliance and Audit

**Regulatory Requirements**:
- **FAA**: 7-year data retention, audit trails, data accuracy
- **EASA**: Similar to FAA for international operations
- **SOX**: Financial data accuracy and controls
- **GDPR**: Data privacy for EU operations

**Audit Trail Requirements**:
- **All Data Changes**: Logged with timestamp, user, before/after values
- **Schema Changes**: Version controlled in Git
- **Access Logs**: CloudTrail logs all resource access
- **Retention**: 7 years for compliance

**Compliance Monitoring**:
- **Automated Checks**: Daily compliance validation
- **Manual Reviews**: Quarterly compliance audits
- **Reporting**: Monthly compliance reports to stakeholders
- **Remediation**: Immediate action on compliance violations

---

## 15. Implementation Roadmap

### 15.1 18-Month Implementation Plan

**Months 1-3: Foundation Setup**
- Establish Governance Council and working groups
- Define data governance policies and standards
- Set up infrastructure (MSK, DocumentDB, S3, EKS)
- Implement Pod Identity for cross-account access
- Deploy Confluent Schema Registry
- Onboard first FOS vendor (DECS)
- Implement Flows 1-5

**Months 4-6: Core Operations**
- Onboard Load Planning vendor
- Implement Flows 6-10
- Establish data quality monitoring
- Deploy CloudWatch dashboards
- Implement automated schema validation
- Begin parallel operation with legacy systems

**Months 7-9: Expansion Phase 1**
- Onboard Takeoff Performance vendor
- Implement Flows 11-15
- Optimize MSK and DocumentDB performance
- Implement distributed tracing with X-Ray
- Conduct first regional failover test
- Migrate 30% of consumers to NXOP

**Months 10-12: Expansion Phase 2**
- Onboard Crew Management vendor
- Implement Flows 16-20
- Implement S3 + Iceberg for analytics
- Deploy Prometheus + Grafana
- Conduct second regional failover test
- Migrate 60% of consumers to NXOP

**Months 13-15: Completion Phase**
- Onboard remaining FOS vendors
- Implement Flows 21-25
- Complete consumer migration (90%)
- Optimize end-to-end latency
- Conduct third regional failover test
- Prepare for legacy system sunset

**Months 16-18: Steady State**
- Complete consumer migration (100%)
- Sunset legacy systems
- Transition to steady-state operations
- Governance Council moves to monthly cadence
- Focus on continuous improvement
- Achieve Level 4 governance maturity

### 15.2 Key Milestones

**Month 3**: Foundation complete, first vendor onboarded
**Month 6**: Core operations established, 5 flows operational
**Month 9**: 15 flows operational, 30% consumer migration
**Month 12**: 20 flows operational, 60% consumer migration
**Month 15**: 25 flows operational, 90% consumer migration
**Month 18**: 100% consumer migration, legacy sunset

### 15.3 Success Criteria

**Operational Excellence**:
- ✓ > 99.9% platform uptime
- ✓ < 10 minutes RTO for regional failover
- ✓ < 5 seconds end-to-end latency for critical flows
- ✓ All 25 flows operational

**Data Quality**:
- ✓ > 99.5% data quality score across all domains
- ✓ > 99.9% schema validation pass rate
- ✓ < 0.1% duplicate record rate
- ✓ > 99% referential integrity compliance

**Integration Efficiency**:
- ✓ < 6 months average vendor onboarding time
- ✓ 100% vendor compliance with integration standards
- ✓ > 70% integration pattern reuse
- ✓ < 24 hours for vendor integration issue resolution

**Governance Maturity**:
- ✓ Level 4 (Quantitatively Managed) achieved
- ✓ 100% semantic mappings documented
- ✓ < 2 weeks for operational data model change approvals
- ✓ 95% governance compliance across all teams

---

## 16. Conclusion

### 16.1 Summary

The NXOP Project represents American Airlines' strategic transformation of flight operations infrastructure from legacy systems to a modern, cloud-native, event-driven architecture. This comprehensive overview has documented:

- **5 Data Domains** with 24 core entities providing operational truth
- **7 Integration Patterns** standardizing data exchange across systems
- **25 Message Flows** representing critical business processes
- **Multi-Cloud Architecture** spanning AWS, Azure, and On-Premises
- **Comprehensive Governance Framework** ensuring data quality and compliance
- **18-Month Implementation Roadmap** with clear milestones and success criteria

### 16.2 Strategic Value

**Operational Excellence**: Real-time data enables better decision-making, improved safety, and enhanced operational efficiency.

**Business Agility**: Standardized integration patterns reduce vendor onboarding time from 9-12 months to < 6 months.

**Cost Optimization**: Cloud-native architecture and operational efficiency gains deliver measurable cost savings.

**Regulatory Compliance**: Comprehensive audit trails and data governance meet FAA, EASA, and other regulatory requirements.

**Resilience**: Multi-region active-active architecture ensures < 10 minute RTO for business continuity.

### 16.3 Next Steps

**Immediate Actions** (Next 30 Days):
1. Finalize Governance Council membership and charter
2. Complete infrastructure setup (MSK, DocumentDB, S3)
3. Begin first FOS vendor onboarding (DECS)
4. Establish monitoring and alerting
5. Deploy first 5 message flows

**Short-Term Goals** (Months 1-6):
1. Onboard 2 FOS vendors
2. Implement 10 message flows
3. Establish data quality monitoring
4. Begin parallel operation with legacy systems
5. Conduct first regional failover test

**Long-Term Vision** (Months 6-18):
1. Complete all 25 message flows
2. Onboard all FOS vendors
3. Migrate 100% of consumers
4. Sunset legacy systems
5. Achieve Level 4 governance maturity

### 16.4 Contact Information

**Governance Council**:
- **Chair**: Todd Waller (Enterprise Data Strategy) - todd.waller@aa.com
- **Co-Chair**: Kevin (Operations Data Strategy) - kevin@aa.com

**NXOP Platform Team**:
- **Platform Lead**: [Name] - [email]
- **Architecture Lead**: Scott - scott@aa.com
- **Physical Design Lead**: Prem - prem@aa.com

**Data Stewards**:
- **Flight Domain**: [Name] - [email]
- **Aircraft Domain**: [Name] - [email]
- **Station Domain**: [Name] - [email]
- **Maintenance Domain**: [Name] - [email]
- **ADL Domain**: [Name] - [email]

**Support**:
- **Email**: nxop-support@aa.com
- **Slack**: #nxop-platform
- **On-Call**: PagerDuty escalation policy

---

**Document End**
