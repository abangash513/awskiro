# American Airlines NXOP Migration - Technical Phase Guide
## FXIP (Azure) → NXOP (AWS) Platform Migration

**Document Version**: 1.0  
**Date**: February 8, 2026  
**Purpose**: Technical breakdown of migration phases with service details

---

## Quick Reference: What's Moving When

### Current State (Before Migration)
- **Primary Platform**: FXIP on Azure
- **Backup (BCP)**: Old AWS system
- **21 NXOP Microservices**: Being built/tested
- **Status**: FXIP handles all production traffic

### End State (After Phase 4)
- **Primary Platform**: NXOP on AWS
- **Backup (BCP)**: None (FXIP decommissioned)
- **21 NXOP Microservices**: Handling all production traffic
- **Status**: NXOP is the only platform

---

## Timeline Overview

**Note**: Specific dates are not provided in the documentation. The phases are sequential with Go/No-Go decision gates between each phase.

```
Phase 0: 3-6 months (Testing & Validation)
Phase 1: 1-2 weeks (BCP Replacement)
Phase 2: 2-4 weeks (Low-Risk Services)
Phase 3: 1-2 weeks (Full Cut-over)
Phase 4: 1-3 months (Decommission)

Total Estimated Duration: 6-12 months
```

---

## Platform Components Overview

### FXIP Platform (Azure) - What's Being Replaced
**Location**: Azure Cloud  
**Components**:
- AKS (Azure Kubernetes Service) clusters
- Azure EventHub (Kafka-compatible messaging)
- MongoDB (Confluent Cloud)
- Azure Tables (NoSQL metadata storage)
- Azure Blob Storage (document storage)
- ConsulDB (reference data)
- OpsHub Event Hubs (integration layer)

### NXOP Platform (AWS) - The New System
**Location**: AWS Cloud (us-east-1 & us-west-2)  
**Components**:
- **EKS (Elastic Kubernetes Service)**: Managed by KPaaS team
- **MSK (Managed Streaming for Kafka)**: Event streaming (50+ topics)
- **DocumentDB Global Cluster**: MongoDB-compatible database (24 collections)
- **S3 with MRAP**: Object storage with Multi-Region Access Points
- **Route 53**: DNS management
- **AWS ARC**: Application Recovery Controller for failover
- **Direct Connect**: On-premises connectivity

---

## The 21 NXOP Microservices

### Category 1: Data Adapters (7 services)
**Purpose**: Transform and route data between systems

1. **Flight Data Adapter**
   - Processes flight events from MSK
   - Updates DocumentDB (FlightTimes, FlightLeg collections)
   - Sends data to Flightkeys via HTTPS

2. **Aircraft Data Adapter**
   - Processes aircraft events from MSK
   - Updates DocumentDB (AircraftLocation, AircraftPerformance)
   - Handles aircraft position and status updates

3. **Station Data Adapter**
   - Processes airport/station data
   - Updates DocumentDB (StationIdentity, StationGeo, StationAuthorization)
   - Integrates with external airport data providers

4. **Maintenance Data Adapter**
   - Processes maintenance events from on-prem FOS
   - Updates DocumentDB maintenance collections
   - Integrates with MQ-Kafka adapter

5. **Crew Data Adapter**
   - Processes crew assignment data from Azure FXIP
   - Updates DocumentDB crew collections
   - Forwards to FOS systems

6. **MSK → EventHub Adapter**
   - Sends NXOP data to FXIP Azure EventHub
   - Enables FXIP to consume NXOP events
   - Critical for coexistence period

7. **MSK → On-Prem MQ Adapter**
   - Sends NXOP data to on-premises OpsHub
   - Bridges cloud and on-prem systems
   - Uses IBM MQ protocol

### Category 2: Data Processors (5 services)
**Purpose**: Consume from external systems and publish to MSK

8. **Flightkeys Event Processor**
   - Consumes AMQP events from Flightkeys (Azure FXIP)
   - Publishes to MSK topics
   - Handles flight release workflows

9. **EventHub → MSK Connector**
   - Consumes from FXIP Azure EventHub
   - Publishes to NXOP MSK
   - Enables FXIP → NXOP data flow

10. **On-Prem MQ → MSK Adapter**
    - Consumes from on-premises OpsHub MQ
    - Publishes to NXOP MSK
    - Bridges on-prem → cloud

11. **Vendor RabbitMQ Processor (FlightKeys)**
    - Consumes from FlightKeys RabbitMQ queues
    - Publishes to MSK
    - Handles flight planning data

12. **Vendor RabbitMQ Processor (CyberJet FMS)**
    - Consumes from CyberJet FMS RabbitMQ queues
    - Publishes to MSK
    - Handles flight management system data

### Category 3: Integration Services (4 services)
**Purpose**: Orchestrate complex workflows and external integrations

13. **Flightkeys Integration Service**
    - Orchestrates pilot briefing package assembly
    - Handles eSignature capture and validation
    - Integrates with CCI (Crew Check-In) on Azure
    - Exposes HTTPS APIs via Akamai GTM

14. **LCA Flight Update Proxy**
    - Forwards signed flight releases to FOS
    - Handles flight authorization workflows
    - Bridges NXOP and legacy FOS systems

15. **Flight Plan Service**
    - Manages flight plan data and metadata
    - Queries DocumentDB for flight details
    - Provides APIs for flight plan retrieval

16. **Pilot Document Service**
    - Manages pilot-specific documents
    - Retrieves documents from S3
    - Assembles briefing packages

### Category 4: API Services (3 services)
**Purpose**: Expose HTTPS APIs for external consumers

17. **Nav Data Service**
    - Provides navigation data APIs
    - Serves on-prem Ops Engineering Client Apps
    - Exposes endpoints via Akamai GTM

18. **Fuel Data Service**
    - Provides fuel planning data APIs
    - Serves on-prem Ops Engineering Client Apps
    - Exposes endpoints via Akamai GTM

19. **Data Maintenance Service**
    - Handles special information messages
    - Sends messages to Flightkeys
    - Manages operational data updates

### Category 5: Specialized Services (2 services)
**Purpose**: Handle specific operational workflows

20. **Terminal Area Forecast UI**
    - Manages TAF (Terminal Area Forecast) data
    - Sends TAF deletions to Flightkeys
    - Provides web interface for forecasters

21. **Notification Service**
    - Sends operational alerts
    - Supports email, SMS, push notifications
    - Monitors critical events

### Admin Tools (6 tools)
**Purpose**: Operational management and monitoring

1. **NXOP Admin Web UI** - Platform administration
2. **Schema Registry UI** - Schema management
3. **Data Catalog UI** - Data discovery
4. **Monitoring Dashboard** - Operational metrics
5. **Reconciliation Tool** - Data validation
6. **Migration Control Panel** - Cut-over management

---

## External Systems & Integrations

### Vendor Systems (Stay External)
- **FlightKeys** (AWS) - Flight planning via RabbitMQ
- **CyberJet FMS** (AWS) - Flight management via RabbitMQ
- **IBM Fusion Flight Tracking** (AWS) - Flight tracking via HTTPS APIs
- **Vienna DR** - Disaster recovery endpoints

### Internal Systems (Stay On-Premises)
- **FOS (Future of Operations Solutions)** - Legacy systems
- **OpsHub** - Integration hub (Azure + On-Prem)
- **CCI (Crew Check-In)** - Azure FXIP
- **AIRCOM Server** - Aircraft communications
- **Ops Engineering Client Apps** - On-premises tools

### Infrastructure Services (Stay External)
- **Akamai GTM** - Global traffic management
- **InfoBlox** - DNS management
- **Apigee** - API gateway
- **Ping Identity** - SSO authentication
- **Entra ID** (Azure AD) - Identity management
- **HashiCorp Vault** - Secrets management
- **Dynatrace** - APM monitoring
- **Mezmo** - Log aggregation
- **PagerDuty** - Incident management

---


## Phase 0: Build & Test Everything (3-6 months)
### "Practice the move before doing it for real"

**Timeline**: 3-6 months (No specific dates in documentation)  
**Environment**: Non-Production Only  
**Risk Level**: LOW (No production impact)

### What Happens
Build and validate the entire NXOP platform in a test environment. Practice the migration multiple times until everyone is confident.

### Services Status

#### ✅ NXOP Services (Being Built & Tested)
**All 21 microservices** deployed in non-prod:
- Flight Data Adapter
- Aircraft Data Adapter
- Station Data Adapter
- Maintenance Data Adapter
- Crew Data Adapter
- MSK → EventHub Adapter
- MSK → On-Prem MQ Adapter
- Flightkeys Event Processor
- EventHub → MSK Connector
- On-Prem MQ → MSK Adapter
- Vendor RabbitMQ Processors (2)
- Flightkeys Integration Service
- LCA Flight Update Proxy
- Flight Plan Service
- Pilot Document Service
- Nav Data Service
- Fuel Data Service
- Data Maintenance Service
- Terminal Area Forecast UI
- Notification Service

**All 6 admin tools** deployed in non-prod

#### 🔵 FXIP Services (Still Running Production)
**All FXIP services** continue handling production traffic:
- AKS clusters
- Azure EventHub
- MongoDB (Confluent Cloud)
- Azure Tables
- Azure Blob Storage
- ConsulDB
- OpsHub Event Hubs

#### 🟢 External Systems (No Changes)
- FlightKeys, CyberJet FMS, IBM Fusion (vendors)
- FOS, OpsHub, CCI (internal on-prem)
- Akamai, InfoBlox, Apigee (infrastructure)

### Technical Activities

#### Epic E0-01: AWS Platform Foundation
**Build the infrastructure**:
- ✅ Provision EKS clusters (us-east-1 & us-west-2)
- ✅ Provision MSK clusters with IAM/OIDC auth
- ✅ Configure MSK cross-region replication (east ↔ west)
- ✅ Provision Global DocumentDB (multi-region)
- ✅ Provision S3 buckets with MRAP
- ✅ Configure Route 53 DNS zones
- ✅ Configure AWS ARC for failover

#### Epic E0-02: Data Migration & Sync
**Test moving data from FXIP to NXOP**:
- ✅ Design migration strategy (MongoDB → DocumentDB)
- ✅ Test Azure Tables → DocumentDB migration
- ✅ Test Azure Blob → S3 migration
- ✅ Build and test all 4 adapters/connectors:
  - EventHub → MSK (FXIP → NXOP)
  - MSK → EventHub (NXOP → FXIP)
  - MSK → On-Prem MQ (NXOP → OpsHub)
  - On-Prem MQ → MSK (OpsHub → NXOP)
- ✅ Build data reconciliation tools
- ✅ **Dress rehearsal**: Practice full migration multiple times

#### Epic E0-03: Connectivity & Integration
**Connect to all external systems**:
- ✅ Validate Direct Connect to on-premises
- ✅ Validate connectivity to vendors (FlightKeys, CyberJet, IBM Fusion)
- ✅ Configure Apigee routing to NXOP APIs
- ✅ Update IP allowlists for all systems
- ✅ Test NXOP → FXIP EventHub integration
- ✅ Test NXOP → OpsHub MQ integration
- ✅ Test NXOP → CCI integration

#### Epic E0-04: Security & Identity
**Lock down security**:
- ✅ Implement IRSA (Pod Identity) for all 21 microservices
- ✅ Replicate secrets from Vault → AWS Secrets Manager
- ✅ Update services to use Secrets Manager
- ✅ Manage TLS certificates in ACM
- ✅ Integrate Ping Identity + Entra ID SSO
- ✅ Validate IP allowlists and firewall rules

#### Epic E0-05: Observability
**Set up monitoring**:
- ✅ Configure Mezmo logging for all services
- ✅ Deploy Dynatrace agents for EKS, MSK, DocumentDB
- ✅ Create CloudWatch dashboards and alarms
- ✅ Integrate PagerDuty alerting
- ✅ Define SLOs/SLIs for critical flows

#### Epic E0-06: Testing
**Test everything**:
- ✅ End-to-end functional regression (all 21 services + 6 tools)
- ✅ Performance testing (load, stress, endurance)
- ✅ Chaos engineering (failure injection)
- ✅ Disaster recovery drills (regional failover)
- ✅ Cut-over rehearsal (practice the migration)

### Go/No-Go Decision Gate
**Criteria for proceeding to Phase 1**:
- ✅ All 21 microservices pass functional tests
- ✅ Performance meets or exceeds FXIP baseline
- ✅ All vendor integrations validated
- ✅ Disaster recovery tested successfully
- ✅ Cut-over rehearsal completed without major issues
- ✅ Runbooks documented and approved
- ✅ Stakeholder sign-off obtained

---

## Phase 1: NXOP Becomes the Backup (1-2 weeks)
### "New house is ready for emergencies, still living in old house"

**Timeline**: 1-2 weeks (No specific dates)  
**Environment**: Production  
**Risk Level**: LOW (FXIP still primary)

### What Happens
NXOP replaces the old AWS BCP system. It only sends data to Vienna (disaster recovery location). FXIP continues handling all normal production traffic.

### Services Status

#### 🟡 NXOP Services (BCP Mode - Vienna Only)
**Services activated for Vienna DR only**:
- ✅ Flight Data Adapter (Vienna-only config)
- ✅ Aircraft Data Adapter (Vienna-only config)
- ✅ Vendor RabbitMQ Processors (Vienna endpoints)
- ✅ MSK clusters (active, Vienna-only topics)
- ✅ DocumentDB (active, Vienna-only writes)

**Services NOT yet active**:
- ⏸️ All other 16 microservices (standby)
- ⏸️ All 6 admin tools (standby)

#### 🔵 FXIP Services (Still Primary for Everything)
**All FXIP services** continue handling 100% of production traffic:
- ✅ All AKS clusters (full production load)
- ✅ Azure EventHub (all message flows)
- ✅ MongoDB (all operational data)
- ✅ Azure Tables (all metadata)
- ✅ Azure Blob Storage (all documents)
- ✅ ConsulDB (all reference data)
- ✅ OpsHub Event Hubs (all integrations)

#### 🟢 External Systems (No Changes)
- ✅ FlightKeys, CyberJet FMS, IBM Fusion (vendors)
- ✅ FOS, OpsHub, CCI (internal on-prem)
- ✅ **Vienna DR** (now receiving from NXOP instead of old BCP)

### Technical Activities

**DNS & Routing Changes**:
- Update Route 53 to point Vienna DR traffic to NXOP
- Configure MSK topics for Vienna-only publishing
- Update firewall rules for Vienna endpoints

**Validation**:
- Test Vienna-only data flow from NXOP
- Verify FXIP unaffected by NXOP activation
- Validate rollback procedures

**Monitoring**:
- Monitor NXOP → Vienna data flow
- Monitor FXIP production traffic (should be unchanged)
- Track any errors or latency issues

### Rollback Plan
**If something goes wrong**:
- Switch Vienna DR back to old AWS BCP
- FXIP continues unaffected
- No impact to normal operations

### Success Criteria
- ✅ Vienna DR receiving data from NXOP successfully
- ✅ FXIP production traffic unaffected
- ✅ No data loss or latency issues
- ✅ Rollback tested and validated

---

## Phase 2: Move Low-Risk Services (2-4 weeks)
### "Move books and decorations, not the bed"

**Timeline**: 2-4 weeks (No specific dates)  
**Environment**: Production  
**Risk Level**: MEDIUM (Partial production traffic)

### What Happens
Carefully selected low-risk NXOP microservices start handling production traffic. FXIP still handles critical services. Gain confidence with real traffic.

### Services Status

#### 🟢 NXOP Services (Partial Production)
**Low-risk services moved to production** (examples):
- ✅ Notification Service (alerts only, non-critical)
- ✅ Data Maintenance Service (special messages)
- ✅ Terminal Area Forecast UI (weather data)
- ✅ Nav Data Service (navigation data APIs)
- ✅ Fuel Data Service (fuel planning APIs)
- ✅ Some admin tools (monitoring, reconciliation)

**High-risk services still in standby**:
- ⏸️ Flight Data Adapter (critical flight operations)
- ⏸️ Aircraft Data Adapter (critical aircraft tracking)
- ⏸️ Flightkeys Integration Service (critical workflows)
- ⏸️ LCA Flight Update Proxy (critical authorizations)
- ⏸️ Flight Plan Service (critical flight planning)
- ⏸️ Crew Data Adapter (critical crew assignments)

#### 🔵 FXIP Services (Still Primary for Critical Flows)
**FXIP continues handling critical services**:
- ✅ Flight operations (flight data, aircraft tracking)
- ✅ Crew management (crew assignments, check-in)
- ✅ Flight planning (briefing packages, authorizations)
- ✅ All EventHub message flows
- ✅ All MongoDB operational data
- ✅ All Azure Tables metadata
- ✅ All Azure Blob documents

#### 🟢 External Systems (Partial Routing Changes)
- ✅ Some vendor endpoints now route to NXOP
- ✅ Some on-prem systems now call NXOP APIs
- ✅ Most systems still route to FXIP

### Technical Activities

**Service Classification**:
- Classify all 21 microservices by risk level
- Identify dependencies and integration points
- Get stakeholder approval for low-risk list

**Production Cut-over**:
- Update DNS to route low-risk traffic to NXOP
- Update Apigee routing for selected APIs
- Configure MSK topics for selected message flows
- Update IP allowlists for selected services

**Stabilization Period**:
- Monitor low-risk services for 1-2 weeks
- Compare NXOP vs FXIP performance metrics
- Track errors, latency, data quality
- Test rollback for at least one service

**Monitoring**:
- Monitor NXOP services handling production traffic
- Monitor FXIP services (should be unaffected)
- Track SLOs/SLIs for all flows
- Alert on any anomalies

### Rollback Plan
**If something goes wrong**:
- Switch low-risk services back to FXIP
- Update DNS and routing
- FXIP takes over affected flows
- Minimal impact to operations

### Success Criteria
- ✅ Low-risk services running smoothly on NXOP
- ✅ No degradation in service quality
- ✅ FXIP critical services unaffected
- ✅ Rollback tested successfully
- ✅ Team gains confidence with live traffic

---

## Phase 3: The Big Switch (1-2 weeks)
### "Move into new house, keep old house keys"

**Timeline**: 1-2 weeks (No specific dates)  
**Environment**: Production  
**Risk Level**: HIGH (Full production cut-over)

### What Happens
**THIS IS THE MAJOR CHANGE**. All remaining microservices move to NXOP. NXOP becomes the primary platform handling all production traffic. FXIP is kept running as a backup (BCP) for safety.

### Services Status

#### 🟢 NXOP Services (NOW PRIMARY - All Production Traffic)
**ALL 21 microservices now in production**:
- ✅ Flight Data Adapter (handling all flight operations)
- ✅ Aircraft Data Adapter (handling all aircraft tracking)
- ✅ Station Data Adapter (handling all airport data)
- ✅ Maintenance Data Adapter (handling all maintenance)
- ✅ Crew Data Adapter (handling all crew assignments)
- ✅ MSK → EventHub Adapter (feeding FXIP)
- ✅ MSK → On-Prem MQ Adapter (feeding OpsHub)
- ✅ Flightkeys Event Processor (all flight releases)
- ✅ EventHub → MSK Connector (consuming from FXIP)
- ✅ On-Prem MQ → MSK Adapter (consuming from OpsHub)
- ✅ Vendor RabbitMQ Processors (all vendor data)
- ✅ Flightkeys Integration Service (all workflows)
- ✅ LCA Flight Update Proxy (all authorizations)
- ✅ Flight Plan Service (all flight planning)
- ✅ Pilot Document Service (all documents)
- ✅ Nav Data Service (all navigation data)
- ✅ Fuel Data Service (all fuel planning)
- ✅ Data Maintenance Service (all messages)
- ✅ Terminal Area Forecast UI (all weather)
- ✅ Notification Service (all alerts)

**ALL 6 admin tools now in production**:
- ✅ NXOP Admin Web UI
- ✅ Schema Registry UI
- ✅ Data Catalog UI
- ✅ Monitoring Dashboard
- ✅ Reconciliation Tool
- ✅ Migration Control Panel

#### 🟡 FXIP Services (NOW BACKUP - BCP Mode)
**FXIP kept running as safety net**:
- 🔄 All AKS clusters (standby, ready for failback)
- 🔄 Azure EventHub (receiving from NXOP via adapter)
- 🔄 MongoDB (receiving updates from NXOP)
- 🔄 Azure Tables (receiving updates from NXOP)
- 🔄 Azure Blob Storage (receiving updates from NXOP)
- 🔄 ConsulDB (standby)
- 🔄 OpsHub Event Hubs (receiving from NXOP)

**Purpose**: If NXOP fails, can quickly switch back to FXIP

#### 🟢 External Systems (All Routing to NXOP)
- ✅ FlightKeys → NXOP (all vendor traffic)
- ✅ CyberJet FMS → NXOP (all vendor traffic)
- ✅ IBM Fusion → NXOP (all vendor traffic)
- ✅ FOS → NXOP (all on-prem traffic)
- ✅ OpsHub → NXOP (all integration traffic)
- ✅ CCI → NXOP (all crew check-in traffic)

### Technical Activities

**Pre-Cut-over**:
- Final readiness review with all stakeholders
- Go/No-Go decision meeting
- Communication to all teams
- Freeze on configuration changes

**Cut-over Window** (typically overnight, low-traffic period):
1. **DNS Updates**:
   - Akamai GTM → NXOP endpoints
   - Route 53 → NXOP endpoints
   - InfoBlox → NXOP endpoints

2. **Routing Changes**:
   - Apigee → NXOP APIs (all 7 APIs)
   - MSK → EventHub adapter direction (NXOP → FXIP)
   - EventHub → MSK connector direction (FXIP → NXOP)
   - MQ adapters direction (bidirectional)

3. **IP Allowlist Updates**:
   - Vendor systems → NXOP IPs
   - On-prem systems → NXOP IPs
   - FXIP systems → NXOP IPs

4. **Publisher Coordination Tables**:
   - Update to make NXOP east/west active regions
   - Configure FXIP as passive/standby

**Post-Cut-over Validation**:
- Run full regression test suite in production
- Validate all 25 message flows
- Validate all vendor integrations
- Validate FXIP receiving data from NXOP (BCP mode)
- Monitor for 24-48 hours

**DR Drill**:
- Test switching back to FXIP temporarily
- Validate FXIP can still handle production traffic
- Switch back to NXOP
- Confirm rollback procedures work

### Rollback Plan
**If something goes wrong**:
- Switch all traffic back to FXIP
- FXIP becomes primary again
- NXOP becomes standby
- Investigate issues and retry later

### Success Criteria
- ✅ All 21 microservices handling production traffic
- ✅ All 25 message flows operational
- ✅ All vendor integrations working
- ✅ FXIP receiving data as BCP
- ✅ No critical errors or data loss
- ✅ Performance meets or exceeds SLOs
- ✅ Rollback tested and validated

---

## Phase 4: Turn Off the Old System (1-3 months)
### "Sell the old house"

**Timeline**: 1-3 months after Phase 3 (No specific dates)  
**Environment**: Production  
**Risk Level**: MEDIUM (Decommissioning)

### What Happens
After NXOP runs smoothly for a defined period (typically 30-90 days), safely decommission FXIP. NXOP becomes the only platform.

### Services Status

#### 🟢 NXOP Services (ONLY PLATFORM)
**ALL 21 microservices** - sole production platform:
- ✅ All services handling 100% of production traffic
- ✅ No backup platform (multi-region redundancy only)
- ✅ Full ownership of all operational data

**ALL 6 admin tools** - sole management platform

#### ❌ FXIP Services (DECOMMISSIONED)
**Phased shutdown of FXIP components**:
- ❌ AKS clusters (terminated)
- ❌ Azure EventHub (deleted)
- ❌ MongoDB (migrated, then deleted)
- ❌ Azure Tables (migrated, then deleted)
- ❌ Azure Blob Storage (migrated to S3, then deleted)
- ❌ ConsulDB (migrated, then deleted)
- ❌ OpsHub Event Hubs (migrated, then deleted)

#### 🟢 External Systems (All Routing to NXOP)
- ✅ All vendor systems → NXOP only
- ✅ All on-prem systems → NXOP only
- ✅ No FXIP dependencies remaining

### Technical Activities

**Pre-Decommission**:
- Inventory all FXIP Azure resources
- Confirm data retention and compliance requirements
- Plan archival strategy (copy residual data to S3/Glacier)
- Get stakeholder approval for decommission plan

**Phased Decommission** (start with non-critical, end with critical):
1. **Week 1-2**: Non-critical components
   - Admin tools
   - Monitoring agents
   - Test environments

2. **Week 3-4**: Integration components
   - EventHub → MSK connector (no longer needed)
   - MSK → EventHub adapter (no longer needed)
   - OpsHub Event Hubs (migrated to NXOP)

3. **Week 5-6**: Data storage
   - Archive residual data to S3/Glacier
   - Validate data migration completeness
   - Delete Azure Tables
   - Delete Azure Blob Storage

4. **Week 7-8**: Core platform
   - Delete MongoDB (after final backup)
   - Delete ConsulDB (after final backup)
   - Terminate AKS clusters

5. **Week 9-12**: Cleanup
   - Delete networking components
   - Delete DNS entries
   - Remove IP allowlists
   - Cancel Azure subscriptions

**Rollback Windows**:
- Each decommission step has a rollback window
- Can restore FXIP if critical issues discovered
- Rollback becomes harder as more components deleted

**Validation**:
- Confirm no NXOP dependencies on FXIP
- Validate cost reductions achieved
- Confirm compliance requirements met
- Get Finance sign-off on cost savings

### Rollback Plan
**If something goes wrong**:
- Early phases: Can restore FXIP from backups
- Later phases: Rollback becomes difficult/impossible
- Must have NXOP stable before proceeding

### Success Criteria
- ✅ All FXIP components safely decommissioned
- ✅ All data migrated and validated
- ✅ No NXOP dependencies on FXIP
- ✅ Cost reductions achieved and validated
- ✅ Compliance and audit requirements met
- ✅ Platform, Security, and Finance sign-off

---

## Data Migration Details

### What Data Moves When

#### Phase 0 (Testing)
- **Test data only** migrated to validate tooling
- MongoDB → DocumentDB (test collections)
- Azure Tables → DocumentDB (test metadata)
- Azure Blob → S3 (test documents)

#### Phase 1 (BCP)
- **Vienna DR data only**
- Minimal operational data for disaster recovery

#### Phase 2 (Low-Risk)
- **Low-risk domain data**
- Navigation data
- Fuel planning data
- Weather forecasts
- Non-critical reference data

#### Phase 3 (Full Cut-over)
- **ALL operational data**
- Flight operations data (FlightTimes, FlightLeg, FlightPlan)
- Aircraft data (AircraftLocation, AircraftPerformance, AircraftIdentity)
- Station data (StationIdentity, StationGeo, StationAuthorization)
- Maintenance data (all maintenance collections)
- Crew data (crew assignments, credentials)
- ADL data (FOS integration data)
- **ALL metadata** (Azure Tables → DocumentDB)
- **ALL documents** (Azure Blob → S3 via MRAP)

#### Phase 4 (Decommission)
- **Residual data archival**
- Historical data to S3/Glacier
- Audit logs to S3
- Compliance data to S3

### Data Synchronization Strategy

**During Coexistence (Phases 1-3)**:
- **NXOP → FXIP**: MSK → EventHub adapter keeps FXIP updated
- **FXIP → NXOP**: EventHub → MSK connector keeps NXOP updated
- **Bidirectional sync**: Both platforms have current data
- **Reconciliation**: Automated tools compare data between platforms

**After Cut-over (Phase 3)**:
- **NXOP is source of truth**
- **FXIP receives updates** (BCP mode)
- **One-way sync**: NXOP → FXIP only

**After Decommission (Phase 4)**:
- **NXOP is only platform**
- **No synchronization needed**
- **Multi-region replication**: us-east-1 ↔ us-west-2

---

## Integration Patterns & Message Flows

### 25 Message Flows Across 7 Integration Patterns

#### Pattern 1: Request-Response (5 flows)
**Synchronous HTTPS APIs**
- Nav Data Service APIs
- Fuel Data Service APIs
- Flight Plan Service APIs
- Pilot Document Service APIs
- Data Maintenance Service APIs

**Migration**: Phase 2 (low-risk) and Phase 3 (critical)

#### Pattern 2: Event-Driven (10 flows)
**Asynchronous Kafka/EventHub messaging**
- Flight events (AMQP → MSK)
- Aircraft events (AMQP → MSK)
- Crew events (AMQP → MSK)
- Maintenance events (MQ → MSK)
- Station events (HTTPS → MSK)

**Migration**: Phase 3 (all critical)

#### Pattern 3: Bidirectional Sync (3 flows)
**Two-way data synchronization**
- NXOP ↔ FXIP (EventHub ↔ MSK)
- NXOP ↔ OpsHub (MSK ↔ MQ)
- NXOP ↔ FOS (HTTPS ↔ MQ)

**Migration**: Phase 1 (adapters), Phase 3 (full traffic)

#### Pattern 4: Document Assembly (2 flows)
**Complex document generation**
- Pilot briefing packages
- Flight release documents

**Migration**: Phase 3 (critical workflows)

#### Pattern 5: Authorization (2 flows)
**eSignature and approval workflows**
- Pilot eSignature (HTTPS)
- ACARS eSignature (ACARS → HTTPS)

**Migration**: Phase 3 (critical workflows)

#### Pattern 6: Outbound Publishing (2 flows)
**Data publishing to external systems**
- NXOP → Vendor RabbitMQ (FlightKeys, CyberJet)
- NXOP → IBM Fusion APIs

**Migration**: Phase 1 (Vienna only), Phase 3 (all vendors)

#### Pattern 7: Notification/Alert (1 flow)
**Operational alerts**
- Email, SMS, push notifications

**Migration**: Phase 2 (low-risk)

---

## Risk Mitigation & Rollback

### Risk Levels by Phase

| Phase | Risk Level | Reason | Rollback Complexity |
|-------|-----------|--------|---------------------|
| 0 | **LOW** | Non-prod only, no production impact | N/A (testing) |
| 1 | **LOW** | Vienna DR only, FXIP still primary | Easy (DNS change) |
| 2 | **MEDIUM** | Partial production, low-risk services | Medium (DNS + routing) |
| 3 | **HIGH** | Full production cut-over | Complex (full failback) |
| 4 | **MEDIUM** | Decommissioning, NXOP proven | Difficult (restore from backup) |

### Rollback Procedures

#### Phase 1 Rollback
**Time**: < 15 minutes
1. Update Route 53 DNS for Vienna DR
2. Point Vienna back to old AWS BCP
3. Validate Vienna receiving data
4. FXIP unaffected

#### Phase 2 Rollback
**Time**: < 30 minutes
1. Update DNS for low-risk services
2. Update Apigee routing
3. Point traffic back to FXIP
4. Validate services operational
5. Critical services unaffected

#### Phase 3 Rollback
**Time**: 1-2 hours
1. **Emergency meeting** - confirm rollback decision
2. **DNS updates** - Akamai, Route 53, InfoBlox → FXIP
3. **Routing changes** - Apigee, adapters → FXIP
4. **IP allowlists** - revert to FXIP IPs
5. **Publisher tables** - make FXIP active
6. **Validation** - full regression test
7. **Communication** - notify all stakeholders
8. **Post-mortem** - analyze what went wrong

#### Phase 4 Rollback
**Time**: Days to weeks (depends on what's deleted)
- **Early decommission**: Can restore from backups
- **Late decommission**: May be impossible
- **Critical**: Don't proceed unless NXOP is stable

### Monitoring & Alerting

**Key Metrics to Watch**:
- **Latency**: End-to-end message flow latency
- **Error Rate**: Failed messages, API errors
- **Data Quality**: Schema validation failures, duplicate records
- **Throughput**: Messages per second, API requests per second
- **Availability**: Service uptime, regional health

**Alert Thresholds**:
- **Critical**: > 5% error rate, > 10s latency, service down
- **Warning**: > 1% error rate, > 5s latency, degraded performance
- **Info**: Approaching thresholds, unusual patterns

**Escalation**:
- **L1**: On-call engineer (PagerDuty)
- **L2**: Platform team lead
- **L3**: Engineering manager + stakeholders
- **L4**: Executive leadership (CIO, VP Flight Ops Tech)

---

## Success Metrics

### Phase 0 Success
- ✅ All 21 microservices pass functional tests
- ✅ Performance ≥ FXIP baseline
- ✅ All vendor integrations validated
- ✅ DR tested successfully
- ✅ Cut-over rehearsal completed

### Phase 1 Success
- ✅ Vienna DR receiving from NXOP
- ✅ FXIP production unaffected
- ✅ No data loss or latency issues
- ✅ Rollback tested

### Phase 2 Success
- ✅ Low-risk services on NXOP
- ✅ No service degradation
- ✅ FXIP critical services unaffected
- ✅ Rollback tested

### Phase 3 Success
- ✅ All 21 microservices in production
- ✅ All 25 message flows operational
- ✅ All vendor integrations working
- ✅ FXIP as BCP validated
- ✅ Performance meets SLOs

### Phase 4 Success
- ✅ FXIP decommissioned safely
- ✅ All data migrated
- ✅ No NXOP dependencies on FXIP
- ✅ Cost reductions achieved
- ✅ Compliance requirements met

---

## Key Contacts & Stakeholders

### Executive Leadership
- **CIO**: Executive sponsor
- **CDO**: Enterprise data governance
- **VP Flight Operations Technology**: NXOP platform ownership

### Technical Teams
- **NXOP Platform Team** (15-20 engineers): Platform development and operations
- **Integration Team** (5-7 engineers): Vendor integration and FOS connectivity
- **KPaaS Team**: Kubernetes infrastructure management
- **Enterprise Data Office**: Canonical model alignment

### Operational Teams
- **Flight Operations**: Flight domain data stewardship
- **Network Operations**: Station domain data stewardship
- **Maintenance Operations**: Maintenance domain data stewardship
- **FOS Integration**: ADL domain and vendor integration

### External Partners
- **FOS Vendors**: DECS, Load Planning, Takeoff Performance, Crew Management
- **Flightkeys** (Azure FXIP): Flight planning and crew integration
- **Vendor Systems**: FlightKeys, CyberJet FMS, IBM Fusion Flight Tracking

---

## Glossary

**FXIP**: Flight Planning and Crew Integration Platform (Azure)  
**NXOP**: Next Generation Operations Platform (AWS)  
**BCP**: Business Continuity Plan (backup system)  
**FOS**: Future of Operations Solutions (legacy on-prem systems)  
**MSK**: Amazon Managed Streaming for Kafka  
**EKS**: Amazon Elastic Kubernetes Service  
**DocumentDB**: Amazon DocumentDB (MongoDB-compatible)  
**MRAP**: Multi-Region Access Point (S3)  
**KPaaS**: Kubernetes Platform as a Service (internal AA team)  
**ARC**: AWS Application Recovery Controller  
**IRSA**: IAM Roles for Service Accounts (Pod Identity)  
**RTO**: Recovery Time Objective  
**RPO**: Recovery Point Objective  
**SLO**: Service Level Objective  
**SLI**: Service Level Indicator  

---

**Document End**
