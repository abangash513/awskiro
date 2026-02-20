# Requirements Document: AA NXOP Data Model Governance

## Introduction

The American Airlines Next Generation Operations Platform (NXOP) is a multi-region, event-driven architecture serving as the foundation for real-time airline operations decision-making. This requirements document defines the comprehensive data model governance framework needed to support NXOP's strategic evolution, vendor solution integrations (FOS - Future of Operations Solutions), and enterprise data alignment.

NXOP operates across a complex multi-cloud architecture spanning AWS (us-east-1, us-west-2), Azure (FXIP platform), and On-Premises (FOS systems). The platform processes 25 distinct message flows across 7 integration patterns, leveraging AWS services including DocumentDB Global Clusters, MSK (Managed Streaming for Kafka), S3, Apache Iceberg, and EKS clusters running in KPaaS (Kubernetes Platform as a Service).

The platform manages 5 core data domains (Flight, Aircraft, Station, Maintenance, ADL) with complex entity relationships, supporting real-time operations, historical analytics, and solver applications. Data governance must enable seamless integration with Flightkeys (AWS), CyberJet FMS (AWS), FXIP (Azure), OpsHub (Azure/On-Prem), and FOS (On-Prem) while maintaining operational continuity during model transitions.

## Scope and Boundaries

### NXOP Architecture Context

**Multi-Cloud Architecture**:
- **AWS NXOP Platform**: Primary operational platform (us-east-1, us-west-2)
  - EKS clusters in KPaaS for application workloads
  - MSK clusters for event streaming with cross-region replication
  - DocumentDB Global Clusters for operational data storage
  - S3 for document storage and Apache Iceberg tables
  - Akamai GTM for API traffic management
  - Route53 DNS for MSK bootstrap routing

- **Azure FXIP Platform**: Flight planning and crew integration
  - Flightkeys Event Processors
  - ConsulDB for reference data
  - OpsHub Event Hubs for event distribution

- **On-Premises Systems**: Legacy FOS integration
  - FOS (DECS, Load Planning, Takeoff Performance, Crew Management)
  - OpsHub On-Prem integration hub
  - AIRCOM Server for ACARS communication
  - MQ-Kafka adapters for protocol translation

**Cross-Account Access Pattern**:
- KPaaS EKS clusters run in separate AWS account (NonProd: 285282426848, Prod: 045755618773)
- Pod Identities enable secure cross-account access to NXOP resources
- Dual-role pattern: KPaaS account role → NXOP account role
- Transit Gateway (TGW) enables VPC-to-VPC communication

### Data Domains


**In-Scope for NXOP Governance** (Fully managed by NXOP):

1. **Flight Domain** (7 entities): Core operational truth of flight lifecycle
   - FlightIdentity (parent): Unique flight identification (flightKey composite ID)
   - FlightTimes: Scheduled, estimated, actual, latest times
   - FlightLeg: Routing, gate/terminal, equipment, status
   - FlightEvent: Current and last known event state with computed values
   - FlightMetrics: KPI-level performance and operational metrics
   - FlightPosition: Aircraft movement and telemetry (ACARS/ADS-B/ATC)
   - FlightLoadPlanning: Load plan for passengers, freight, bags, compartments

2. **Aircraft Domain** (5 entities): Authoritative master record of fleet
   - AircraftIdentity (parent): Core aircraft identifiers (carrierCode, noseNumber, registration)
   - AircraftConfiguration: Static structural configuration (cabin layout, SELCAL)
   - AircraftLocation: Current operational state (last flight, next flight, overnight planning)
   - AircraftPerformance: Weight limits, operational performance values
   - AircraftMEL: Active Minimum Equipment List items

3. **Station Domain** (4 entities): Airports and airline stations
   - StationIdentity (parent): Unique station identification (ICAO + IATA)
   - StationGeo: Geographical and physical characteristics
   - StationAuthorization: Landing authorization configurations
   - StationMetadata: Operational metadata

4. **Maintenance Domain** (6 entities): Aircraft maintenance operations
   - MaintenanceRecord (parent): Top-level maintenance event snapshot
   - MaintenanceDMI: Deferred defects list
   - MaintenanceEquipment: Equipment configuration at event time
   - MaintenanceLandingData: Lifetime operational metrics
   - MaintenanceOTS: Out-of-service status
   - MaintenanceEventHistory: Complete maintenance event lifecycle

5. **ADL Domain** (2 entities): FOS-derived flight metadata snapshots
   - adlHeader: Snapshot metadata (timestamp, ADL record ID, operational flags)
   - adlFlights: Arrival/departure metadata from ADL feed

**Shared Scope** (Joint governance with Enterprise):
- **Crew Domain**: Crew operational assignments (NXOP), crew planning/scheduling (Enterprise)
- **Network Domain**: Operational route execution (NXOP), strategic network planning (Enterprise)

**Out-of-Scope for NXOP Governance** (Enterprise-owned):
- **Customer Domain**: Passenger bookings, loyalty, customer profiles
- **Resource Domain**: Long-term resource planning, facilities management
- **Financial Domain**: Revenue management, accounting, financial reporting


### Message Flow Scope

**25 Message Flows Across 7 Integration Patterns**:

1. **Inbound Data Ingestion** (10 flows): External sources → NXOP → On-Prem
   - Flow 2: Receive and publish flight plans from Flightkeys
   - Flow 3: Update FOS with Flightkeys events
   - Flow 4: Update FOS with flightplan data
   - Flow 5: Receive audit logs, weather, FK OFP data
   - Flow 6: Send summary flight plans to dispatchers
   - Flow 12: Publish flight plans/weather to CyberJet
   - Flow 16: Ops engineering fleet/reference data maintenance
   - Flow 17-19: Additional inbound flows

2. **Outbound Data Publishing** (2 flows): On-Prem → NXOP → External systems
   - Flow 1: Publish FOS event data to Flightkeys
   - Flow 11: Publish flight event data to CyberJet

3. **Bidirectional Sync** (7 flows): Two-way data synchronization
   - Flow 13: Aircraft FMS initialization and enroute ACARS requests
   - Flow 15: Flight progress reports initiated by dispatchers
   - Flow 20-24: Additional bidirectional flows
   - **Flow 26: Azure Blob Storage ↔ AWS S3 migration sync (FXIP cutover)**

4. **Notification/Alert** (3 flows): Event-driven notifications
   - Flow 7: Send flight release update notifications to ACARS and CCI
   - Flow 14: Flightkeys ACARS free text messaging
   - Flow 25: Additional notification flow

5. **Document Assembly** (1 flow): Multi-service document generation
   - Flow 8: Retrieve pilot briefing package

6. **Authorization** (2 flows): Electronic signature workflows
   - Flow 9: Pilot eSignature for flight release - CCI
   - Flow 10: Pilot eSignature for flight release - ACARS

7. **Data Maintenance** (1 flow): Reference data management
   - Flow 16: Ops engineering fleet/reference data maintenance

**Critical Infrastructure Dependencies**:
- **MSK Cluster**: 6 flows (23%) - Flows 1, 2, 5, 10, 18, 19
- **DocumentDB Global Cluster**: 6 flows (23%) - Flows 1, 8, 10, 18, 19, 26
- **Cross-Account IAM (Pod Identity)**: ALL 26 flows (100%) - CRITICAL single point of failure
- **Akamai GTM**: API-dependent flows for external traffic routing
- **Route53 DNS**: MSK-dependent flows for bootstrap routing
- **Azure Blob Storage**: 1 flow (4%) - Flow 26 (FXIP cutover migration)
- **AWS DataSync**: 1 flow (4%) - Flow 26 (Azure ↔ AWS object synchronization)


### FOS Vendor Integration Scope

**Phase 1 (Months 1-9)**: Foundation and Core Integrations
- FOS Vendor TBD: Flight operations optimization
- FOS Vendor TBD: Crew scheduling integration
- Focus: Establish integration patterns and governance framework

**Phase 2 (Months 10-15)**: Extended Integrations
- FOS Vendor TBD: Aircraft maintenance prediction
- FOS Vendor TBD: Network optimization
- Focus: Scale integration patterns and refine governance

**Phase 3 (Months 16-18+)**: Future Integrations
- Additional FOS vendors as identified
- Focus: Continuous improvement and expansion

**Note**: Specific FOS vendor names to be identified during stakeholder workshops in Quarter 1.

### Enterprise Integration Boundaries

**NXOP Owns**:
- Real-time operational data models and schemas for 5 domains
- Event stream definitions for 25 message flows
- Operational data quality rules
- Real-time data lineage within NXOP
- MSK topic schemas (Avro) and DocumentDB collection schemas
- GraphQL schema design (Apollo Federation patterns)

**Enterprise Owns** (Todd Waller's Domain):
- Enterprise canonical data models
- Master data management for reference data
- Cross-enterprise data governance policies
- Enterprise-wide data catalog and lineage

**Joint Ownership**:
- Logical data models for shared domains (Crew, Network)
- Data convergence patterns and integration points
- Semantic mappings between NXOP and Enterprise models
- Data quality standards for shared data

## Glossary

- **NXOP**: Next Generation Operations Platform - event-driven operations platform at American Airlines
- **FOS**: Future of Operations Solutions - vendor solution integrations and legacy on-premises flight operations system
- **FXIP**: Flight planning and crew integration platform running on Azure
- **KPaaS**: Kubernetes Platform as a Service - AA's internal managed Kubernetes platform
- **Pod Identity**: Secure cross-account IAM authentication for EKS workloads accessing NXOP resources
- **MSK**: AWS Managed Streaming for Kafka - event streaming backbone with cross-region replication
- **DocumentDB**: AWS DocumentDB Global Cluster - operational data storage with multi-region failover
- **Akamai GTM**: Global Traffic Manager - routes external API traffic to NXOP endpoints
- **Route53**: AWS DNS service - routes internal MSK traffic for bootstrap connections
- **Message_Flow**: Specific data exchange pathway between systems (25 flows identified)
- **Integration_Pattern**: Standardized approach for data exchange (7 patterns: Inbound, Outbound, Bidirectional, Notification, Document Assembly, Authorization, Data Maintenance)
- **Data_Domain**: Bounded context of related data (Flight, Aircraft, Station, Maintenance, ADL)
- **flightKey**: Composite ID for flight identification (carrier + flight number + flight date + departure station + dupDepCode)
- **AMQP**: Advanced Message Queuing Protocol - used by Flightkeys for event publishing
- **ACARS**: Aircraft Communications Addressing and Reporting System - aircraft-to-ground communication
- **CCI**: Crew Check In - Azure FXIP component for crew operations
- **OpsHub**: Integration hub (Azure Event Hubs + On-Prem) for event distribution
- **AIRCOM**: On-premises gateway to aircraft ACARS systems
- **Data_Governance_Framework**: System of policies, standards, roles, and processes ensuring data quality, consistency, and compliance
- **Logical_Data_Model**: Technology-agnostic representation of data structures jointly owned by Operations and IT
- **Physical_Data_Model**: Technology-specific implementation (DocumentDB collections, MSK topics, Iceberg tables)
- **Schema_Registry**: System managing and versioning data schemas (Confluent Schema Registry for Kafka, custom for DocumentDB/GraphQL)
- **Data_Catalog**: Centralized metadata repository documenting all data assets, lineage, and relationships
- **Transition_Period**: Timeframe during which legacy and new data models operate in parallel
- **Data_Steward**: Role responsible for data quality, definitions, and business rules within a data domain
- **Schema_Version**: Specific iteration of a schema with backward/forward compatibility rules
- **Cross-Region_Replication**: MSK and DocumentDB data replication between us-east-1 and us-west-2
- **Transit_Gateway**: AWS TGW enabling VPC-to-VPC communication between KPaaS and NXOP
- **Azure_Blob_Storage**: Azure object storage service used by FXIP for flight event data and metadata
- **Azure_Tables**: Azure NoSQL key-value storage used by FXIP for flight event metadata
- **DataSync**: AWS service for automated data transfer between Azure Blob Storage and AWS S3 with built-in validation
- **Partition_Key**: Key component in Azure Tables used for data organization and query optimization, parsed from object names
- **SAS_Token**: Shared Access Signature token providing secure delegated access to Azure Blob Storage resources
- **Bidirectional_Sync**: Integration pattern for two-way data synchronization between systems (Pattern 3 of 7)
- **DLQ**: Dead Letter Queue for capturing failed message processing attempts requiring manual intervention
- **Circuit_Breaker**: Design pattern preventing cascading failures by stopping operations when error thresholds are exceeded


## Requirements

### Requirement 1: Multi-Cloud Data Governance Framework

**User Story:** As an enterprise data strategist, I want a comprehensive data governance framework spanning AWS, Azure, and On-Premises environments, so that data quality, consistency, and compliance are maintained across NXOP's multi-cloud architecture and aligned with enterprise standards.

#### Acceptance Criteria

1. WHEN establishing governance policies, THE Data_Governance_Framework SHALL define policies for data quality, security, privacy, and compliance across AWS NXOP, Azure FXIP, and On-Premises FOS
2. THE Data_Governance_Framework SHALL establish decision rights using RACI matrix for all 25 message flows and 7 integration patterns
3. THE Data_Governance_Framework SHALL define roles including Data_Steward for each of the 5 data domains (Flight, Aircraft, Station, Maintenance, ADL)
4. WHEN governance policies are established, THE Data_Governance_Framework SHALL document approval workflows and escalation paths for cross-cloud decisions
5. THE Data_Governance_Framework SHALL define metrics and KPIs for measuring governance effectiveness across MSK, DocumentDB, and S3/Iceberg data stores
6. THE Data_Governance_Framework SHALL establish a governance council with representation from NXOP Platform Team, Application Teams, Operations, IT, and business stakeholders
7. WHEN cross-account IAM policies are modified, THE Data_Governance_Framework SHALL require approval from both KPaaS and NXOP security teams
8. THE Data_Governance_Framework SHALL define data residency and sovereignty rules for multi-region architecture (us-east-1, us-west-2)

### Requirement 2: Message Flow and Integration Pattern Governance

**User Story:** As an integration architect, I want clearly defined governance for all 25 message flows and 7 integration patterns, so that data exchange is consistent, traceable, and resilient across NXOP's complex integration landscape.

#### Acceptance Criteria

1. THE System SHALL document governance policies for each of the 7 integration patterns (Inbound Data Ingestion, Outbound Data Publishing, Bidirectional Sync, Notification/Alert, Document Assembly, Authorization, Data Maintenance)
2. WHEN new message flows are added, THE System SHALL classify them into one of the 7 integration patterns and apply pattern-specific governance rules
3. THE System SHALL maintain a registry of all 25 message flows with their source systems, NXOP components, destination systems, and communication protocols
4. WHEN message flows use MSK, THE System SHALL enforce Avro schema registration and compatibility rules in Confluent Schema Registry
5. WHEN message flows use AMQP, THE System SHALL document message formats, routing keys, and exchange configurations
6. THE System SHALL define data quality validation rules at ingestion points for each integration pattern
7. WHEN message flows span multiple clouds (AWS → Azure, AWS → On-Prem), THE System SHALL document protocol translation requirements (e.g., Kafka → Event Hubs, Kafka → MQ)
8. THE System SHALL establish SLA requirements for each message flow based on criticality (Vital, Critical, Discretionary per NXOP charter)
9. WHEN integration patterns involve ACARS communication, THE System SHALL document AIRCOM Server dependencies and failover procedures
10. THE System SHALL define monitoring and alerting requirements for each message flow including latency, throughput, and error rate thresholds


### Requirement 3: Data Domain Model Governance

**User Story:** As a data architect, I want comprehensive governance for the 5 NXOP data domains (Flight, Aircraft, Station, Maintenance, ADL), so that domain models are consistent, well-documented, and support both operational and analytical use cases.

#### Acceptance Criteria

1. THE System SHALL maintain logical data models for each of the 5 domains with entity definitions, attributes, and relationships
2. WHEN Flight Domain entities are modified, THE System SHALL validate that the flightKey composite ID (carrier + flight number + flight date + departure station + dupDepCode) remains consistent across all 7 Flight entities
3. THE System SHALL enforce 1-to-1 relationships between FlightIdentity (parent) and its child entities (FlightTimes, FlightLeg, FlightEvent, FlightMetrics, FlightPosition, FlightLoadPlanning)
4. WHEN Aircraft Domain entities are modified, THE System SHALL validate that AircraftIdentity (parent) maintains referential integrity with its 4 child entities (AircraftConfiguration, AircraftLocation, AircraftPerformance, AircraftMEL)
5. THE System SHALL document the Domain-Driven Design (DDD) rationale for each domain including why it exists separately (e.g., Station Domain provides single source of truth for airport data reused across multiple domains)
6. WHEN ADL Domain entities are updated, THE System SHALL preserve FOS-derived snapshot metadata including snapshot timestamps, ADL record IDs, and FOS indicators
7. THE System SHALL define data ownership for each domain: Operations team owns business semantics and logical models, IT team owns physical implementations
8. WHEN Maintenance Domain entities are modified, THE System SHALL maintain event-driven data characteristics including trackingID per event and complex nested structures (DMI, OTS, LandingData)
9. THE System SHALL document entity cardinality and relationship types for all domain entities
10. THE System SHALL establish naming conventions for entities, attributes, and relationships consistent across all 5 domains

### Requirement 4: Cross-Account IAM and Pod Identity Governance

**User Story:** As a security architect, I want robust governance for cross-account IAM and Pod Identity configurations, so that EKS workloads in KPaaS can securely access NXOP resources without static credentials while maintaining least-privilege access.

#### Acceptance Criteria

1. THE System SHALL document the dual-role pattern for Pod Identity: KPaaS account role (intermediate) → NXOP account role (target)
2. WHEN creating NXOP account roles, THE System SHALL enforce trust policies allowing assumption only from KPaaS account IDs (NonProd: 285282426848, Prod: 045755618773)
3. THE System SHALL require trust policy conditions including kubernetes-namespace and eks-cluster-arn to restrict role assumption
4. WHEN configuring Pod Identity, THE System SHALL document the runway.aa.com/pod-identity annotation format (<AWS_Account_ID>/<Target_IAM_Role_Name>)
5. THE System SHALL establish a review process for Pod Identity role permissions ensuring least-privilege access to NXOP resources (DocumentDB, MSK, S3)
6. WHEN Pod Identity roles are modified, THE System SHALL perform impact analysis across all affected message flows (all 25 flows depend on cross-account IAM)
7. THE System SHALL define monitoring and alerting for Pod Identity authentication failures including AssumeRole denials and permission errors
8. THE System SHALL document the relationship between Pod Identity and Transit Gateway (TGW) network connectivity requirements
9. WHEN Pod Identity trust policies are updated, THE System SHALL require approval from both KPaaS and NXOP security teams
10. THE System SHALL maintain an inventory of all Pod Identity roles with their associated EKS namespaces, service accounts, and NXOP resource permissions


### Requirement 5: MSK and Event Streaming Governance

**User Story:** As a platform engineer, I want comprehensive governance for MSK clusters and event streaming, so that the 6 MSK-dependent message flows (24% of all flows) have reliable, performant, and well-governed event streaming infrastructure.

#### Acceptance Criteria

1. THE System SHALL document MSK cluster architecture including cross-region replication between us-east-1 and us-west-2
2. WHEN MSK topics are created, THE System SHALL enforce Avro schema registration in Confluent Schema Registry with compatibility rules (backward, forward, or full)
3. THE System SHALL maintain topic definitions for all Kafka topics including retention periods, partition counts, producers, and consumers (reference: topic-definitions.md with 50+ topics)
4. WHEN MSK-dependent flows are deployed, THE System SHALL document Route53 DNS bootstrap routing (kafka.nxop.com → NLB → MSK brokers)
5. THE System SHALL define producer and consumer configurations for each MSK-dependent flow (Flows 1, 2, 5, 10, 18, 19)
6. WHEN MSK topics are modified, THE System SHALL perform impact analysis on all dependent flows including MQ-Kafka adapters, Flight/Aircraft Data Adapters, and Kafka Connectors
7. THE System SHALL establish monitoring requirements for MSK including broker health, consumer lag, replication lag, and throughput metrics
8. WHEN cross-region replication is configured, THE System SHALL document failover procedures and RTO/RPO targets (< 10 min RTO per resilience analysis)
9. THE System SHALL define data retention policies for MSK topics based on compliance requirements (e.g., 7 days for audit logs in Flow 5)
10. THE System SHALL document protocol translation requirements for MSK including Kafka → MQ (On-Prem FOS), Kafka → Event Hubs (Azure OpsHub)
11. WHEN MSK consumer groups are created, THE System SHALL enforce naming conventions and document consumer group ownership
12. THE System SHALL establish capacity planning guidelines for MSK including partition sizing, throughput requirements, and scaling triggers

### Requirement 6: DocumentDB and Operational Data Governance

**User Story:** As a database architect, I want comprehensive governance for DocumentDB Global Clusters, so that the 5 DocumentDB-dependent message flows (20% of all flows) have reliable, performant, and well-governed operational data storage.

#### Acceptance Criteria

1. THE System SHALL document DocumentDB Global Cluster architecture including primary region (us-east-1) and secondary region (us-west-2)
2. WHEN DocumentDB collections are created, THE System SHALL map them to one of the 5 data domains (Flight, Aircraft, Station, Maintenance, ADL)
3. THE System SHALL define collection schemas for all DocumentDB collections including document structure, indexes, and validation rules
4. WHEN DocumentDB-dependent flows are deployed, THE System SHALL document access patterns (read-heavy vs. write-heavy) and query patterns
5. THE System SHALL establish monitoring requirements for DocumentDB including connection pool metrics, query performance, replication lag, and failover status
6. WHEN DocumentDB collections are modified, THE System SHALL perform impact analysis on all dependent flows (Flows 1, 8, 10, 18, 19)
7. THE System SHALL define failover procedures for DocumentDB Global Cluster with automatic failover to secondary region (< 1 minute per architecture)
8. WHEN reference data is stored in DocumentDB, THE System SHALL document data refresh procedures and staleness tolerance
9. THE System SHALL establish capacity planning guidelines for DocumentDB including collection sizing, index optimization, and scaling triggers
10. THE System SHALL define backup and recovery procedures for DocumentDB including point-in-time recovery requirements
11. WHEN DocumentDB is used for enrichment (e.g., Flow 1 aircraft configurations), THE System SHALL document degraded functionality behavior when DocumentDB is unavailable
12. THE System SHALL establish data quality validation rules for DocumentDB collections including required fields, data types, and business rule constraints


### Requirement 7: Schema Management and Versioning Across Technologies

**User Story:** As a platform developer, I want robust schema management and versioning across Avro (MSK), DocumentDB, and GraphQL schemas, so that schema changes are controlled, backward-compatible, and traceable across all 25 message flows.

#### Acceptance Criteria

1. THE Schema_Registry SHALL store and version Avro schemas for all MSK topics using Confluent Schema Registry
2. WHEN Avro schemas are updated, THE Schema_Registry SHALL enforce compatibility rules (backward, forward, or full compatibility) based on message flow criticality
3. THE System SHALL maintain schema lineage showing evolution history for each of the 25 message flows
4. WHEN DocumentDB collection schemas are modified, THE System SHALL document schema changes in version-controlled format with migration scripts
5. THE System SHALL provide schema documentation generation for GraphQL schemas aligned with Apollo Federation patterns
6. WHEN breaking schema changes are required, THE System SHALL enforce versioning strategy with parallel schema support during transition period
7. THE System SHALL integrate schema validation with CI/CD pipelines to validate schema changes before deployment
8. WHEN schema changes are proposed, THE System SHALL perform impact analysis across all dependent consumers and producers for affected message flows
9. THE System SHALL maintain a unified schema catalog documenting Avro, DocumentDB, and GraphQL schemas with cross-references
10. WHEN AMQP message formats are modified (Flightkeys integration), THE System SHALL document message structure changes and notify affected consumers
11. THE System SHALL define schema governance policies for each technology (Avro, DocumentDB, GraphQL, AMQP) including approval workflows
12. WHEN schemas are versioned, THE System SHALL maintain backward compatibility for at least 2 major versions to support gradual consumer migration

### Requirement 8: FOS and NXOP Data Structure Alignment

**User Story:** As an integration architect, I want clear alignment between FOS vendor solutions and NXOP data structures, so that vendor integrations are seamless, maintainable, and support the 18+ month strategic evolution.

#### Acceptance Criteria

1. WHEN FOS vendor data models are received, THE System SHALL document mapping between FOS structures and NXOP Logical_Data_Models for all 5 domains
2. THE System SHALL identify and document semantic differences between FOS and NXOP data definitions including field naming, data types, and business rules
3. WHEN conflicts exist between FOS and NXOP models, THE System SHALL provide transformation rules and business logic for data conversion
4. THE System SHALL maintain a registry of all FOS integration points with their corresponding NXOP data structures and message flows
5. WHEN FOS vendor models change, THE System SHALL trigger impact analysis on affected NXOP structures and message flows
6. THE System SHALL document ADL Domain as the FOS-derived snapshot layer preserving FOS indicators and metadata
7. WHEN FOS integration patterns are established, THE System SHALL classify them into one of the 7 integration patterns and apply pattern-specific governance
8. THE System SHALL define data quality validation rules for FOS-sourced data including completeness, accuracy, and timeliness checks
9. WHEN FOS vendors are onboarded (Phase 1, 2, 3), THE System SHALL provide integration templates and governance checklists
10. THE System SHALL establish SLA requirements for FOS integrations based on operational criticality and business impact


### Requirement 9: Enterprise Data Structure Alignment

**User Story:** As an enterprise data architect, I want NXOP data structures aligned with enterprise data models, so that operations data is consistent across systems outside NXOP scope and supports enterprise-wide analytics and reporting.

#### Acceptance Criteria

1. THE System SHALL document relationships between NXOP data structures and Enterprise_Data_Structures for shared domains (Crew, Network)
2. WHEN enterprise data standards are updated by Todd Waller's team, THE System SHALL assess impact on NXOP models and Message_Flows
3. THE System SHALL establish canonical data definitions for shared operational concepts (crew, aircraft, flights, stations) jointly owned by NXOP and Enterprise
4. WHEN data convergence is required (e.g., crew planning + crew ops), THE System SHALL provide integration patterns and data lineage documentation
5. THE System SHALL maintain a master data management strategy for reference data shared across enterprise systems (aircraft configurations, station data)
6. THE System SHALL define boundaries between NXOP-owned domains (Flight, Aircraft, Station, Maintenance, ADL) and Enterprise-owned domains (Customer, Resource, Financial)
7. WHEN NXOP data is consumed by enterprise analytics platforms (Databricks, Orion), THE System SHALL document data export patterns and quality requirements
8. THE System SHALL establish governance council representation including Todd Waller (Enterprise Data Strategy) and Kevin (Ops Data Strategy)
9. WHEN semantic mappings are created between NXOP and Enterprise models, THE System SHALL document transformation logic and business rules
10. THE System SHALL define data quality standards for shared data including accuracy, completeness, consistency, and timeliness metrics

### Requirement 10: Parallel Data Structure Management During Transitions

**User Story:** As a platform engineer, I want to manage parallel data structures during transitions, so that existing processes continue while new models are adopted without impeding future objectives and operational continuity is maintained.

#### Acceptance Criteria

1. WHEN new data models are introduced, THE System SHALL support parallel operation of legacy and new structures during Transition_Period with defined sunset timelines
2. THE System SHALL provide data synchronization mechanisms between legacy and new data structures ensuring consistency
3. WHEN applications consume data, THE System SHALL route requests to appropriate model versions based on consumer capabilities and migration status
4. THE System SHALL define sunset timelines and migration paths for legacy data structures with phased approach (Months 1-9, 10-15, 16-18+)
5. THE System SHALL monitor usage metrics for legacy structures to inform decommissioning decisions including consumer counts and request volumes
6. WHEN parallel structures exist, THE System SHALL maintain data consistency rules and validation across both versions
7. THE System SHALL provide migration runbooks for each integration pattern type with rollback procedures
8. WHEN migrations occur, THE System SHALL maintain operational continuity through gradual cutover with validation checkpoints
9. THE System SHALL document dependencies between data structures and downstream consumers to sequence migrations appropriately
10. THE System SHALL establish success criteria for each migration phase including data quality metrics, consumer adoption rates, and operational stability


### Requirement 10A: Azure Blob Storage to AWS S3 Migration (FXIP Cutover)

**User Story:** As a platform architect, I want a robust and reversible migration strategy for FXIP flight events and metadata from Azure Blob Storage to AWS S3, so that the Azure-to-AWS cutover maintains operational continuity with rollback capability while supporting bidirectional synchronization during the transition period.

#### Acceptance Criteria

**Pre-Cutover Data Synchronization (Azure → AWS)**:

1. THE System SHALL leverage AWS DataSync in enhanced mode to copy objects from Azure Blob Storage to AWS S3 with parallel task execution, built-in error handling, and object validation
2. WHEN objects are copied to AWS S3, THE System SHALL trigger Lambda functions to parse Partition Keys from object names and query Azure Tables for corresponding metadata
3. THE Lambda functions SHALL be deployed in NXOP VPC with Pod Identity cross-account IAM access to DocumentDB clusters, MSK topics, and S3 buckets
4. WHEN Lambda functions query Azure Tables, THE System SHALL handle pagination for queries exceeding 100 entities or 4 MiB payload limits
5. THE System SHALL configure Lambda timeout to minimum 30 seconds to account for network latency and Azure Table query processing
6. WHEN metadata is retrieved from Azure Tables, THE Lambda functions SHALL insert metadata into AWS DocumentDB collections with exception handling and error logging
7. THE System SHALL implement CloudWatch Dashboards displaying Lambda execution metrics including invocation count, error rate, duration, and throttling events
8. THE System SHALL configure CloudWatch Alarms for multiple consecutive Lambda failures (threshold: 5 consecutive failures) and eclipsed failure percentage (threshold: 10% failure rate over 5 minutes)
9. THE System SHALL implement periodic validation processes to ensure objects in AWS S3 have corresponding metadata in AWS DocumentDB
10. WHEN validation detects missing metadata, THE System SHALL query Azure Tables using parsed Partition Keys and insert missing metadata into DocumentDB
11. THE System SHALL ensure validation failures for specific objects are non-blocking so other objects can continue processing
12. THE System SHALL monitor Lambda concurrent execution limits (default 1000 per region) and request limit increases before cutover if projected load exceeds 70% of limit
13. THE System SHALL monitor VPC ENI consumption for Lambda functions and ensure ENI quota (default 500 per VPC) is not exceeded considering existing KPaaS EKS workload consumption

**Post-Cutover Reverse Synchronization (AWS → Azure)**:

14. WHEN objects are uploaded to AWS S3 post-cutover, THE System SHALL trigger AWS DataSync to copy objects to Azure Blob Storage
15. THE System SHALL implement Azure Functions to parse object names, query AWS DocumentDB using Partition Keys, and insert metadata into Azure Tables
16. THE Azure Functions SHALL be granted network access to AWS DocumentDB requiring security group rules allowing inbound connections from Azure Function IP ranges
17. THE System SHALL implement secure AWS credentials management in Azure using Azure Key Vault with automatic credential rotation
18. THE System SHALL configure network routing and firewall rules between Azure and AWS environments including Transit Gateway routing and VPC security groups
19. THE System SHALL implement TLS/SSL certificate validation for encrypted connections from Azure Functions to AWS DocumentDB
20. THE Azure Functions SHALL implement exception handling and error logging with Azure Application Insights monitoring
21. THE System SHALL configure Azure Monitoring dashboards displaying Azure Function execution metrics similar to CloudWatch dashboards (invocation count, error rate, duration)
22. THE System SHALL configure Azure Alerts for multiple consecutive failures (threshold: 5 consecutive failures) and eclipsed failure percentage (threshold: 10% failure rate over 5 minutes)
23. THE System SHALL implement periodic validation processes in Azure to ensure objects in Azure Blob Storage have corresponding metadata in Azure Tables
24. WHEN Azure validation detects missing metadata, THE System SHALL query AWS DocumentDB and insert missing metadata into Azure Tables

**Rollback and Resilience**:

25. THE System SHALL document detailed rollback procedures with step-by-step instructions for reverting to Azure-primary operations
26. THE System SHALL define rollback triggers including data consistency violations exceeding 5%, Lambda/Azure Function failure rates exceeding 15%, or DocumentDB connection failures exceeding 10%
27. WHEN rollback is triggered, THE System SHALL execute rollback within < 10 min RTO aligned with NXOP multi-region resilience requirements
28. THE System SHALL test rollback procedures in non-production environments before production cutover
29. THE System SHALL implement circuit breaker patterns to prevent cascading failures when Azure or AWS services are degraded
30. THE System SHALL monitor cross-cloud network bandwidth and latency with alerts for degradation exceeding 20% of baseline

**Data Governance and Quality**:

31. THE System SHALL classify Azure Blob migration as Integration Pattern 3 (Bidirectional Sync) and document as Message Flow 26
32. THE System SHALL assign Data Steward from ADL Domain (FOS-derived data) with responsibility for migration data quality
33. THE System SHALL enforce object naming conventions ensuring Partition Keys are consistently parsable from object names
34. THE System SHALL validate object naming conventions before migration with rejection of non-compliant objects
35. WHEN object naming conventions are violated, THE System SHALL log violations with object name, expected format, and remediation guidance
36. THE System SHALL define data quality metrics for migration including metadata completeness (target: 99.9%), synchronization latency (target: < 5 minutes), and consistency validation pass rate (target: 99.5%)
37. THE System SHALL integrate migration monitoring with existing NXOP Data Catalog documenting Azure Blob → S3 lineage
38. THE System SHALL document migration in Schema Registry including object metadata schemas for Azure Tables and DocumentDB collections

**Performance and Scalability**:

39. THE System SHALL document expected data volume, object count, and throughput requirements for DataSync capacity planning
40. THE System SHALL conduct load testing of Lambda functions, Azure Functions, and DataSync tasks before production cutover
41. WHEN Lambda concurrent execution approaches 70% of limit, THE System SHALL implement exponential backoff and retry logic to prevent throttling
42. THE System SHALL implement DLQ (Dead Letter Queue) for failed Lambda invocations with manual review and reprocessing procedures
43. THE System SHALL define maximum acceptable synchronization lag between Azure and AWS (target: < 5 minutes for pre-cutover, < 2 minutes for post-cutover)
44. THE System SHALL monitor DocumentDB connection pool metrics and query performance during migration with alerts for degradation

**Security and Compliance**:

45. THE System SHALL implement least-privilege IAM policies for Lambda functions accessing DocumentDB, S3, and Azure Tables
46. THE System SHALL require dual approval (KPaaS security team + NXOP security team) for Pod Identity role modifications supporting migration
47. THE System SHALL encrypt data in transit using TLS 1.2+ for all cross-cloud communication (Azure ↔ AWS)
48. THE System SHALL encrypt data at rest in S3 using AWS KMS with customer-managed keys
49. THE System SHALL implement audit logging for all data access including CloudTrail logs for AWS resources and Azure Activity Logs for Azure resources
50. THE System SHALL document data residency requirements and ensure compliance with multi-region data sovereignty rules (us-east-1, us-west-2)


### Requirement 11: Multi-Region Resilience and DR Governance

**User Story:** As a platform SRE, I want comprehensive governance for multi-region resilience and disaster recovery, so that NXOP can withstand regional failures with < 10 min RTO and maintain operational continuity across all 25 message flows.

#### Acceptance Criteria

1. THE System SHALL document resilience strategies for each of the 7 integration patterns including HA automated recovery, regional switchover, and manual intervention procedures
2. WHEN MSK clusters fail, THE System SHALL execute cross-region failover using Route53 DNS routing with automatic consumer group rebalancing
3. WHEN DocumentDB Global Cluster fails, THE System SHALL execute automatic failover to secondary region (< 1 minute) with application reconnection
4. THE System SHALL define recovery characteristics for each message flow: 19 flows (76%) HA automated, 4 flows (16%) regional switchover, 2 flows (8%) manual intervention
5. WHEN Akamai GTM detects regional failure, THE System SHALL route API traffic to healthy region with health check validation
6. THE System SHALL establish continuous pre-failover validation (Phase 0) eliminating pre-flight checks and enabling rapid failover
7. WHEN regional failover is triggered, THE System SHALL execute concurrent infrastructure isolation (Phase 1: MSK + DocumentDB) and application failover (Phase 2: Akamai GTM + AMQP listeners)
8. THE System SHALL define L1-L4 health check hierarchy for region readiness assessment requiring 90%+ score for safe failover
9. WHEN AMQP listeners reconnect after failover, THE System SHALL document auto-reconnection behavior and message replay requirements
10. THE System SHALL establish monitoring and alerting for cross-region replication lag including MSK replication and DocumentDB replication metrics
11. WHEN cascading failures occur, THE System SHALL document failure propagation patterns and circuit breaker implementations
12. THE System SHALL define rollback procedures for failed regional switchovers with automated rollback triggers

### Requirement 12: Data Quality and Validation Across Message Flows

**User Story:** As a data steward, I want comprehensive data quality and validation capabilities across all 25 message flows, so that data flowing through NXOP meets defined quality standards and business rules.

#### Acceptance Criteria

1. THE System SHALL define data quality dimensions (accuracy, completeness, consistency, timeliness, validity) for each of the 5 data domains
2. WHEN data enters NXOP via any of the 10 inbound data ingestion flows, THE System SHALL validate against defined business rules and schema constraints
3. THE System SHALL implement data quality checks at ingestion, transformation, and consumption points for each integration pattern
4. WHEN data quality issues are detected, THE System SHALL log violations with message flow context and trigger alerting workflows
5. THE System SHALL provide data quality dashboards showing metrics by Data_Domain, Message_Flow, and Integration_Pattern
6. THE System SHALL support data quality rules defined in a declarative, version-controlled format with CI/CD integration
7. WHEN data fails validation, THE System SHALL provide clear error messages with remediation guidance and dead-letter queue handling
8. THE System SHALL establish data quality SLAs for each message flow based on criticality (Vital, Critical, Discretionary)
9. WHEN AMQP messages are received from Flightkeys, THE System SHALL validate message structure, required fields, and business rule compliance
10. THE System SHALL define data quality validation rules for cross-cloud data flows (AWS → Azure, AWS → On-Prem) including protocol translation validation
11. WHEN DocumentDB documents are written, THE System SHALL enforce schema validation rules and business constraints
12. THE System SHALL monitor data quality trends over time and trigger alerts when quality degrades below defined thresholds


### Requirement 13: Metadata Management and Data Catalog

**User Story:** As a data analyst, I want a comprehensive data catalog spanning AWS, Azure, and On-Premises systems, so that I can discover, understand, and access NXOP data assets with clear lineage and business context across all 25 message flows.

#### Acceptance Criteria

1. THE Data_Catalog SHALL document all data assets including DocumentDB collections, MSK topics (50+ topics), Iceberg tables, GraphQL types, and AMQP exchanges
2. THE Data_Catalog SHALL capture business metadata including definitions, ownership, stewardship, and classification for all 5 data domains
3. THE Data_Catalog SHALL provide data lineage showing source-to-target flows across all 25 Message_Flows with integration pattern classification
4. WHEN users search the Data_Catalog, THE System SHALL support search by business term, technical name, data domain, message flow, and integration pattern
5. THE Data_Catalog SHALL integrate with Confluent Schema Registry to display current and historical Avro schema versions
6. THE Data_Catalog SHALL document data sensitivity classifications and access control requirements including Pod Identity role mappings
7. THE System SHALL automatically discover and catalog new data assets deployed to NXOP infrastructure (MSK topics, DocumentDB collections, S3 buckets)
8. WHEN message flows span multiple clouds, THE Data_Catalog SHALL document cross-cloud lineage (AWS → Azure, AWS → On-Prem)
9. THE Data_Catalog SHALL provide impact analysis capabilities showing downstream consumers affected by data asset changes
10. THE System SHALL document data asset dependencies on infrastructure components (MSK clusters, DocumentDB clusters, Akamai GTM, Route53)
11. WHEN data assets are used by multiple message flows, THE Data_Catalog SHALL document all consuming flows and their criticality
12. THE Data_Catalog SHALL integrate with enterprise data catalog (Todd Waller's domain) for shared domain visibility

### Requirement 14: KPaaS Integration and Network Governance

**User Story:** As a platform architect, I want comprehensive governance for KPaaS integration and network connectivity, so that EKS workloads can reliably access NXOP infrastructure across VPCs and regions.

#### Acceptance Criteria

1. THE System SHALL document KPaaS VPC and NXOP VPC network architecture including Transit Gateway (TGW) routing
2. WHEN single-region traffic flows (e.g., us-east-1 KPaaS → us-east-1 NXOP), THE System SHALL document security group requirements without firewall inspection
3. WHEN cross-region traffic flows (e.g., us-east-1 → us-west-2), THE System SHALL document firewall rules and inspection requirements
4. THE System SHALL maintain an inventory of all EKS applications in KPaaS with their NXOP resource dependencies (DocumentDB, MSK, S3)
5. WHEN EKS applications are deployed, THE System SHALL validate network connectivity to required NXOP resources before production deployment
6. THE System SHALL document Route53 DNS routing for MSK bootstrap connections (kafka.nxop.com → NLB → MSK brokers)
7. WHEN Akamai GTM routes traffic to EKS applications, THE System SHALL document inbound API endpoint configurations and health checks
8. THE System SHALL establish monitoring requirements for network connectivity including latency, packet loss, and connection failures
9. WHEN Transit Gateway routes are modified, THE System SHALL perform impact analysis on all affected message flows
10. THE System SHALL define network capacity planning guidelines including bandwidth requirements and scaling triggers
11. WHEN EKS applications make outbound calls to external systems (FOS, CCI, AIRCOM), THE System SHALL document direct routing (not through Akamai)
12. THE System SHALL establish network security policies including VPC security groups, NACLs, and firewall rules for KPaaS-NXOP connectivity


### Requirement 15: Tool Selection and Evaluation

**User Story:** As a platform architect, I want clear criteria for tool selection, so that governance, cataloging, and schema management tools align with NXOP's multi-cloud architecture and AWS/Azure/On-Prem requirements.

#### Acceptance Criteria

1. THE System SHALL define evaluation criteria for data governance tools including AWS compatibility, Azure integration, multi-cloud support, and scalability
2. THE System SHALL assess tools for schema registry (Confluent Schema Registry for Kafka, custom for DocumentDB/GraphQL), data catalog, and data quality
3. WHEN evaluating tools, THE System SHALL consider integration with existing NXOP components (DocumentDB, MSK, Iceberg, Apollo Federation, KPaaS)
4. THE System SHALL define requirements for metadata management tools supporting multi-region active-active architecture (us-east-1, us-west-2)
5. THE System SHALL evaluate build vs. buy decisions for each governance capability with total cost of ownership analysis
6. THE System SHALL document total cost of ownership including licensing, implementation, operational costs, and multi-cloud data transfer costs
7. WHEN tools are selected, THE System SHALL provide implementation roadmap and integration architecture spanning AWS, Azure, and On-Prem
8. THE System SHALL evaluate tools for cross-cloud lineage tracking capabilities (AWS → Azure, AWS → On-Prem)
9. WHEN evaluating data catalog tools, THE System SHALL assess AWS Glue Data Catalog, commercial tools (Collibra, Alation), and custom solutions
10. THE System SHALL define requirements for schema registry tools supporting Avro, JSON Schema, GraphQL, and AMQP message formats

### Requirement 16: Migration and Transition Strategies

**User Story:** As a program manager, I want clear migration and transition strategies, so that the 18+ month initiative has phased delivery with measurable milestones and minimal operational disruption across all 25 message flows.

#### Acceptance Criteria

1. THE System SHALL define migration waves prioritizing high-value Data_Domains and critical Message_Flows based on business impact
2. WHEN planning migrations, THE System SHALL assess dependencies between data structures, message flows, and downstream consumers
3. THE System SHALL provide runbooks for migrating each Integration_Pattern type (7 patterns) with pattern-specific procedures
4. THE System SHALL define rollback procedures for failed migrations with automated rollback triggers and validation checkpoints
5. WHEN migrations occur, THE System SHALL maintain operational continuity through parallel running and gradual cutover
6. THE System SHALL define success criteria and validation checkpoints for each migration phase including data quality metrics and consumer adoption
7. THE System SHALL document lessons learned and update migration playbooks after each wave
8. WHEN migrating MSK-dependent flows, THE System SHALL document consumer group migration and offset management procedures
9. WHEN migrating DocumentDB collections, THE System SHALL document data migration procedures, index creation, and validation queries
10. THE System SHALL establish communication plans for each migration wave including stakeholder notifications and training materials
11. WHEN migrating cross-cloud flows (AWS → Azure, AWS → On-Prem), THE System SHALL document protocol translation migration and testing procedures
12. THE System SHALL define phased approach: Phase 1 (Months 1-9) foundation, Phase 2 (Months 10-15) extended integrations, Phase 3 (Months 16-18+) future integrations


### Requirement 17: Roles, Responsibilities, and Decision Rights

**User Story:** As an organizational leader, I want clearly defined roles and decision rights spanning NXOP Platform Team, Application Teams, KPaaS Team, and Enterprise stakeholders, so that accountability is clear and decisions are made efficiently.

#### Acceptance Criteria

1. THE System SHALL document RACI matrix for all governance activities including model design, schema approval, policy enforcement, and cross-account IAM management
2. THE System SHALL define joint ownership model for Logical_Data_Models between Operations team (business semantics) and IT team (technical implementation)
3. THE System SHALL establish Operations team ownership of Data_Domains (Flight, Aircraft, Station, Maintenance, ADL) and business semantics
4. THE System SHALL establish IT team ownership of Physical_Data_Models (DocumentDB collections, MSK topics, Iceberg tables) and technical implementation
5. WHEN decisions require escalation, THE System SHALL define escalation paths and decision-making authority including NXOP Platform Lead, KPaaS Team, and Enterprise Data Strategy
6. THE System SHALL define Data_Steward responsibilities for each Data_Domain with named individuals and accountability
7. THE System SHALL establish governance council charter with meeting cadence, membership (NXOP, KPaaS, Enterprise, Operations), and decision-making processes
8. WHEN cross-account IAM decisions are required, THE System SHALL define joint approval process between KPaaS security team and NXOP security team
9. THE System SHALL document collaboration model between NXOP team, Todd Waller (Enterprise Data Strategy), Kevin (Ops Data Strategy), Scott (Strategic Partner), and Prem (Physical Design)
10. THE System SHALL define decision rights for message flow modifications including impact analysis requirements and approval workflows

### Requirement 18: Change Management and Communication

**User Story:** As a change manager, I want comprehensive change management and communication plans spanning NXOP Platform Team, Application Teams, KPaaS Team, and Enterprise stakeholders, so that stakeholders are informed, trained, and prepared for governance changes.

#### Acceptance Criteria

1. THE System SHALL define communication plan for governance rollout including stakeholder identification (NXOP, KPaaS, Application Teams, Enterprise) and messaging
2. WHEN governance policies are updated, THE System SHALL notify affected teams through defined communication channels (Slack, Email, Developer Portal)
3. THE System SHALL provide training materials for Data_Stewards, developers, and data consumers including KPaaS-specific training
4. THE System SHALL establish feedback mechanisms for continuous improvement of governance processes
5. WHEN new data models are introduced, THE System SHALL provide migration guides and developer documentation
6. THE System SHALL conduct workshops with key stakeholders (Todd Waller, Kevin, Scott, Prem, KPaaS Team, business stakeholders)
7. THE System SHALL measure adoption metrics and adjust communication strategies based on feedback
8. WHEN schema changes affect message flows, THE System SHALL use schema change notification template with impact analysis and timeline
9. WHEN migration waves are announced, THE System SHALL use migration wave announcement template with impacted teams and support resources
10. THE System SHALL establish communication channels including Slack (#nxop-data-governance, #nxop-schema-changes), Email, Developer Portal, and Dashboard
11. WHEN incidents occur affecting message flows, THE System SHALL use incident communication template with status, impact, and ETA
12. THE System SHALL define meeting cadence: Governance Council (bi-weekly), Data Steward Sync (weekly), Application Team Office Hours (weekly), Executive Steering (monthly)


### Requirement 19: Resource Planning and Allocation

**User Story:** As a resource manager, I want clear resource requirements and allocation plans, so that the initiative is properly staffed with appropriate skill levels for NXOP's multi-cloud architecture.

#### Acceptance Criteria

1. THE System SHALL define resource requirements including 1 L5 Data Governance Architect and 2 L4 Engineers (Schema Registry Engineer, Data Catalog Engineer)
2. THE System SHALL identify which resources require dedicated NXOP allocation (100% for all 3 roles) vs. shared enterprise allocation
3. THE System SHALL document skill requirements for data governance, data architecture, and data modeling roles including multi-cloud expertise (AWS, Azure, On-Prem)
4. WHEN resource gaps exist, THE System SHALL provide skill gap analysis and onboarding plans
5. THE System SHALL define collaboration model between NXOP team, enterprise data strategy (Todd Waller), ops data strategy (Kevin), physical design team (Prem), and KPaaS team
6. THE System SHALL allocate responsibilities across Platform Team and Application Team governance models
7. THE L5 Data Governance Architect SHALL have 7+ years experience with event-driven architecture, MSK/Kafka, DocumentDB/MongoDB, and multi-region distributed systems
8. THE L4 Schema Registry Engineer SHALL have 5+ years experience with Confluent Schema Registry, Avro, API design, and CI/CD integration
9. THE L4 Data Catalog Engineer SHALL have 5+ years experience with AWS Glue Data Catalog, metadata management, data lineage, and search technologies
10. THE System SHALL define phase responsibilities: Phase 1 (Months 1-3) architecture and tool selection, Phase 2 (Months 4-9) implementation, Phase 3 (Months 10-15) FOS integration, Phase 4 (Months 16-18+) migration execution

### Requirement 20: Scope Definition and Boundaries

**User Story:** As a program sponsor, I want clear scope definition and boundaries, so that the initiative focuses on high-value outcomes and manages scope creep across NXOP's complex multi-cloud architecture.

#### Acceptance Criteria

1. THE System SHALL define which Data_Domains are within NXOP scope (Flight, Aircraft, Station, Maintenance, ADL) vs. enterprise scope (Customer, Resource, Financial)
2. THE System SHALL document boundaries between NXOP governance and enterprise data governance (Todd Waller's domain)
3. WHEN new data requirements emerge, THE System SHALL provide intake process for scope evaluation with governance council review
4. THE System SHALL prioritize governance capabilities based on business value, technical dependencies, and message flow criticality
5. THE System SHALL define out-of-scope items to manage stakeholder expectations including enterprise MDM platform, cross-enterprise data warehouse, and non-operational analytics
6. THE System SHALL establish quarterly scope review process with governance council
7. THE System SHALL define in-scope criteria: data produced/consumed by NXOP, supports real-time operations, flows through 25 message flows, impacts 2+ application teams
8. THE System SHALL define shared-scope criteria: jointly owned by NXOP and Enterprise, requires data convergence, has both operational and strategic use cases
9. THE System SHALL define out-of-scope criteria: exclusively owned by Enterprise, no real-time requirements, does not flow through NXOP infrastructure
10. THE System SHALL establish intake process: submission (requester), initial assessment (L5 Architect, 3 days), governance council review (next meeting), communication (L5 Architect, 2 days)


### Requirement 21: Immediate Deliverables (Current Quarter)

**User Story:** As an executive sponsor, I want immediate deliverables this quarter, so that the initiative has clear direction and stakeholder alignment before detailed implementation begins.

#### Acceptance Criteria

1. THE System SHALL document current situation including existing governance gaps, pain points, and multi-cloud complexity challenges
2. THE System SHALL define goals for the 18+ month initiative with measurable success criteria (OKR format)
3. THE System SHALL document approach including phases, milestones, dependencies, and multi-cloud integration points
4. THE System SHALL specify resource requirements with justification and allocation model (1 L5, 2 L4)
5. THE System SHALL document leading practices from industry and peer organizations (airlines, large enterprises)
6. THE System SHALL develop point-of-view (POV) on data scope covered within NXOP boundaries vs. enterprise boundaries
7. WHEN workshops are conducted, THE System SHALL capture decisions, action items, and stakeholder commitments
8. THE System SHALL provide current situation analysis in SWOT format: Strengths (Confluent Schema Registry, Unity Catalog), Weaknesses (inconsistent schema management, missing lineage), Opportunities (FOS integration, data convergence), Threats (resource constraints, technical complexity)
9. THE System SHALL define goals in OKR format: Objective 1 (governance framework) with Key Results (100% message flows documented by Month 9, 100% data assets cataloged by Month 12, 80% quality violation reduction by Month 15)
10. THE System SHALL provide phased approach in Gantt chart format showing 4 phases over 18 months with resource allocation and risk mitigation

## Communication Plan

### Stakeholder Communication Matrix

| Stakeholder Group | Information Needs | Frequency | Channel | Owner | Format |
|-------------------|-------------------|-----------|---------|-------|--------|
| **Governance Council** | Strategic decisions, major milestones, risks, resource needs | Bi-weekly (Months 1-12), Monthly (Months 13-18+) | Meeting + Email Summary | L5 Architect | Executive Summary (1-2 pages) |
| **Data Stewards** | Schema changes, quality issues, policy updates, domain-specific guidance | Weekly | Slack Channel + Email Digest | L4 Engineers | Technical Update |
| **NXOP Platform Team** | Technical implementations, infrastructure changes, cross-account IAM updates | Daily (Slack), Weekly (Sync) | Slack + Meeting | L5 Architect | Technical Sync Notes |
| **KPaaS Team** | Pod Identity changes, network connectivity, EKS deployment impacts | As needed (changes), Bi-weekly (sync) | Slack + Meeting | L5 Architect | Integration Update |
| **Application Teams** | Breaking changes, migration schedules, new capabilities, best practices | As needed (changes), Monthly (updates) | Email + Slack + Developer Portal | Platform Team | Developer Update |
| **Executive Sponsors** | Progress against goals, risks, resource needs, business impact | Monthly | Executive Summary Email | L5 Architect | Executive Dashboard (metrics + narrative) |
| **Enterprise Data Strategy (Todd Waller)** | Enterprise alignment, canonical model changes, governance policy impacts | Monthly | Meeting + Email | L5 Architect | Strategic Alignment Report |
| **Ops Data Strategy (Kevin)** | Operational domain models, business rule changes, data steward activities | Bi-weekly | Meeting + Email | L5 Architect | Operational Update |
| **Physical Design Team (Prem)** | Schema implementations, performance impacts, infrastructure changes | Weekly | Meeting + Slack | L4 Engineers | Technical Sync Notes |
| **Business Stakeholders (Analytics, Solvers)** | Data availability, quality metrics, lineage, access procedures | Monthly | Email + Dashboard | Data Stewards | Business User Update |


### Communication Templates

**Schema Change Notification Template**:
```
Subject: [NXOP Governance] Schema Change Notification - [Schema Name]

Summary: [One-line description of change]
Impact: [Breaking/Non-breaking, Affected message flows, Affected services count]
Timeline: [Proposed date, Review period, Deployment date]
Action Required: [What recipients need to do, by when]
Details: [Link to schema registry, Impact analysis, Migration guide]
Message Flows Affected: [List of affected flows from 25 total]
Integration Pattern: [Which of 7 patterns affected]
Contact: [Owner name, Slack channel, Email]
```

**Migration Wave Announcement Template**:
```
Subject: [NXOP Governance] Migration Wave [N] - [Domain Name]

Overview: [What is being migrated, Why, Expected benefits]
Timeline: [Preparation start, Parallel operation period, Cutover date, Decommission date]
Impacted Teams: [List of application teams and their action items]
Impacted Message Flows: [List of affected flows from 25 total]
Multi-Cloud Considerations: [AWS, Azure, On-Prem impacts]
Support: [Migration runbook link, Office hours schedule, Slack channel]
Success Criteria: [How we'll measure success]
Rollback Plan: [Conditions for rollback, Rollback procedure]
Contact: [Migration lead, Support channel]
```

**Cross-Account IAM Change Notification Template**:
```
Subject: [NXOP Governance] Cross-Account IAM Change - [Role Name]

Summary: [What is changing in Pod Identity configuration]
Impact: [Affected EKS namespaces, Affected NXOP resources, Affected message flows]
KPaaS Account: [NonProd: 285282426848 or Prod: 045755618773]
NXOP Account: [Target account ID]
Timeline: [Review period, Approval deadline, Deployment date]
Security Review: [KPaaS security approval status, NXOP security approval status]
Action Required: [What teams need to do, Testing requirements]
Details: [Trust policy changes, Permission changes, Testing procedures]
Contact: [Security team, Platform team, Slack channel]
```

**Message Flow Impact Notification Template**:
```
Subject: [NXOP Governance] Message Flow Impact - [Flow Name/Number]

Flow Details: [Flow number, Integration pattern, Source → NXOP → Destination]
Change Summary: [What is changing]
Impact: [Criticality (Vital/Critical/Discretionary), Affected systems, Downtime expected]
Infrastructure Dependencies: [MSK, DocumentDB, Akamai GTM, Route53, Pod Identity]
Timeline: [Change window, Expected duration, Rollback window]
Multi-Cloud Impact: [AWS impact, Azure impact, On-Prem impact]
Action Required: [What teams need to do, Testing requirements]
Monitoring: [What metrics to watch, Alert thresholds]
Contact: [Flow owner, Support channel]
```

### Communication Channels

**Primary Channels**:
- **Slack**: 
  - `#nxop-data-governance` (general governance discussions)
  - `#nxop-schema-changes` (technical schema notifications)
  - `#nxop-governance-incidents` (urgent issues)
  - `#nxop-kpaas-aws-support` (KPaaS integration support)
- **Email**: Distribution lists by stakeholder group
- **Developer Portal**: Self-service documentation, schema browser, catalog search, KPaaS integration guides
- **Dashboard**: Real-time metrics (quality scores, catalog coverage, migration progress, message flow health)

**Meeting Cadence**:
- **Governance Council**: Bi-weekly (Months 1-12), Monthly (Months 13-18+)
- **Data Steward Sync**: Weekly
- **KPaaS Integration Sync**: Bi-weekly
- **Application Team Office Hours**: Weekly (open forum for questions)
- **Executive Steering**: Monthly
- **All-Hands Update**: Quarterly (major milestones and achievements)


### Training and Enablement

**Training Materials**:
- **Data Steward Training**: Role responsibilities, schema management (Avro, DocumentDB, GraphQL), quality rules, catalog usage, message flow understanding (4-hour workshop)
- **Developer Training**: Schema registry usage (Confluent), quality validation, catalog search, migration procedures, Pod Identity configuration, KPaaS integration (3-hour workshop)
- **Data Consumer Training**: Catalog search, lineage understanding, access requests, message flow discovery (1-hour workshop)
- **KPaaS Integration Training**: Pod Identity setup, cross-account IAM, network connectivity, Transit Gateway routing (2-hour workshop for KPaaS teams)
- **Multi-Cloud Architecture Training**: AWS NXOP, Azure FXIP, On-Prem FOS integration patterns, protocol translation (2-hour workshop)

**Documentation**:
- **Governance Handbook**: Policies, standards, procedures, decision frameworks, multi-cloud considerations
- **Technical Guides**: 
  - Schema registry API (Confluent, DocumentDB, GraphQL)
  - Data catalog API
  - Quality rule DSL
  - Migration runbooks by integration pattern
  - Pod Identity configuration guide
  - KPaaS network integration guide
  - Message flow documentation (all 25 flows)
- **FAQs**: Common questions by stakeholder group (NXOP, KPaaS, Application Teams, Enterprise)
- **Video Tutorials**: Screen recordings for common tasks (schema registration, catalog search, Pod Identity setup)

### Feedback Mechanisms

**Continuous Feedback**:
- **Slack Channels**: Real-time questions and feedback (#nxop-data-governance, #nxop-kpaas-aws-support)
- **Office Hours**: Weekly open forum for discussion
- **Surveys**: Quarterly satisfaction surveys by stakeholder group
- **Retrospectives**: After each major milestone or migration wave

**Feedback Analysis**:
- Monthly review of feedback themes
- Quarterly adjustment of communication strategy
- Annual communication plan refresh

### Adoption Metrics

**Tracked Metrics**:
- Email open rates and click-through rates
- Slack channel engagement (messages, active users)
- Training attendance and completion rates
- Documentation page views and search queries
- Survey response rates and satisfaction scores
- Support ticket volume and resolution time
- Message flow health metrics (latency, throughput, error rate)
- Schema registry adoption (% of flows with registered schemas)
- Data catalog coverage (% of data assets cataloged)
- Pod Identity adoption (% of EKS apps using Pod Identity)

**Success Targets**:
- 90% email open rate for critical communications
- 80% training completion rate for required audiences
- 4.0+ satisfaction score (out of 5.0) on quarterly surveys
- <24 hour response time for support questions
- 100% of message flows documented by Month 9
- 100% of data assets cataloged by Month 12
- 90%+ Pod Identity adoption for EKS apps by Month 12

## Appendix: NXOP Charter Alignment

This data governance initiative aligns with the NXOP Charter principles:

- **Platform Design**: Supports real-time capabilities, composable architecture, and digital twin grounding through comprehensive data governance
- **Resiliency**: Ensures resilience through multi-region data replication, cross-region failover, and message flow monitoring
- **System Tiering**: Right-sizes governance based on message flow criticality (Vital, Critical, Discretionary)
- **Open Platform**: Enables enterprise data strategy integration and cross-system data access through data catalog and lineage
- **Safety & Compliance**: Maintains FAA and IATA compliance through data quality validation and audit trails
- **Evolvability**: Supports platform evolution through parallel data structure management and phased migrations
- **Unified Data Fabric**: Governs single source of truth for operational data across 5 domains
- **Security by Design**: Implements zero-trust through Pod Identity and cross-account IAM governance
- **Cost Optimization**: Balances performance with efficiency through tiered storage and retention policies
- **Developer Experience**: Provides self-service capabilities through data catalog, schema registry, and developer portal
- **Observability**: Ensures comprehensive monitoring through message flow metrics and data quality dashboards

