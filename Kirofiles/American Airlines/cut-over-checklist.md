# FXIP → NXOP Platform Migration Cut-over Plan & Checklist
---

## Table of Contents

- [Introduction & Objectives](#1-introduction-objectives)
- [Migration Phases Overview](#2-migration-phases-overview)
- [Phase 0 – Non‑Prod Readiness and Verification](#3-phase-0-nonprod-readiness-and-verification)
  - [Epic E0-01 – AWS Platform & Network Foundation Readiness](#31-epic-e0-01-aws-platform-network-foundation-readiness)
  - [Epic E0-02 – Data Migration & Synchronization Readiness](#32-epic-e0-02-data-migration-synchronization-readiness)
  - [Epic E0-03 – Connectivity & Integration to Vendors, FXIP, OpsHub & On‑Prem Readiness](#33-epic-e0-03-connectivity-and-integration-to-vendors-fxip-opshub-onprem-readiness)
  - [Epic E0-04 – Security, Identity, Secrets & Certificates Readiness](#34-epic-e0-04-security-identity-secrets-certificates-readiness)
  - [Epic E0-05 – Observability, Monitoring, Logging & Alerting Readiness](#35-epic-e0-05-observability-monitoring-logging-alerting-readiness)
  - [Epic E0-06 – Non‑Prod Functional, Performance, Chaos & DR Testing Readiness](#36-epic-e0-06-nonprod-functional-performance-chaos-dr-testing-readiness)
- [Phases 1–4 – Production Cut‑over & Decommission](#4-phases-14-production-cutover-decommission)
  - [Phase 1 – Replace current BCP with NXOP East with feed to Vienna FlightKeys](#41-phase-1-replace-current-bcp-with-nxop-east-with-feed-to-vienna-flightkeys)
  - [Phase 2 – Cut‑over Low‑Risk Microservices](#42-phase-2-cutover-lowrisk-microservices)
  - [Phase 3 – Cut‑over Remaining Microservices (Azure FXIP as BCP)](#43-phase-3-cutover-remaining-microservices-azure-fxip-as-bcp)
  - [Phase 4 – Azure FXIP Decommission](#44-phase-4-azure-fxip-decommission)
- [Runbooks & Documentation Required](#5-runbooks-documentation-required)
- [Cut‑over Risk & Mitigation Overview](#6-cutover-risk-mitigation-overview)
- [List of NXOP Services](#7-list-of-nxop-services)

---

## 1. Introduction & Objectives

This document provides a **comprehensive cut‑over checklist and non‑production readiness plan** for migrating the **FXIP** platform from **Azure** to a new **NXOP** platform on **AWS**.

Key external and internal integrations:

- Vendor systems:  
  - FlightKeys (RabbitMQ queues)  
  - CyberJet FMS (RabbitMQ queues)  
  - IBM Fusion Flight Tracking (HTTP APIs)
- Legacy/internal systems:  
  - FXIP integrations with Azure EventHub (FXIP must be fed from NXOP)  
  - FXIP integrations with on‑prem OpsHub via MQ  
  - FXIP integration with Crew Check In (CCI) on Azure via one of the APIs  
- New adapters/connectors in scope:  
  - MSK → On‑Prem MQ adapter (NXOP→OpsHub)  
  - On‑Prem MQ → MSK adapter (OpsHub→NXOP)  
  - MSK → Azure EventHub (Kafka) adapter (NXOP→FXIP)  
  - EventHub → MSK connector (FXIP→NXOP)

**Key objectives:**

- Minimize business disruption during migration and cut‑over.  
- Maintain data integrity and avoid data loss during coexistence and cut‑over.  
- Ensure equal or better resilience, security, and observability on NXOP vs FXIP.  
- Provide runbooks and clear Go/No‑Go gates for each phase.

---

## 2. Migration Phases Overview

### Phase Overview Table

| Phase | Description                                                                                      | Primary Outcome                                                                    |
|-------|--------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| 0     | **Full non‑prod build‑out of NXOP, validation, performance, chaos, DR, cut‑over rehearsal**<br><br>Key activities:<br>1. Complete platform provisioning and validation<br>2. Execute performance and chaos testing<br>3. Conduct cut‑over rehearsal<br>4. Validate all integrations | **Primary Outcome:**<br>1. NXOP non‑prod proven equivalent/better than FXIP<br>2. Runbooks and integrations validated<br>3. Go/No‑Go decision gate cleared |
| 1     | **Replace existing AWS BCP with NXOP (publishing only to vendor Vienna DR)**<br><br>Key activities:<br>1. Validate Vienna‑only configuration<br>2. Execute DNS and routing changes<br>3. Run Vienna‑only validation tests<br>4. Establish rollback criteria | **Primary Outcome:**<br>1. NXOP becomes AWS BCP for Vienna<br>2. FXIP remains primary for normal ops<br>3. Rollback tested and validated |
| 2     | **Cut‑over low‑risk NXOP microservices in production**<br><br>Key activities:<br>1. Classify microservices by risk<br>2. Execute production cut‑over for low‑risk services<br>3. Run stabilization period<br>4. Test rollback | **Primary Outcome:**<br>1. Partial production traffic on NXOP<br>2. FXIP remains primary for remaining flows<br>3. Live traffic experience gained |
| 3     | **Cut‑over remaining microservices to NXOP; FXIP retained as BCP**<br><br>Key activities:<br>1. Final readiness review<br>2. Update publisher coordination tables<br>3. Execute main production cut‑over window<br>4. Post‑cut‑over validation | **Primary Outcome:**<br>1. NXOP becomes primary<br>2. FXIP remains BCP for defined period<br>3. Production regression passed |
| 4     | **Decommission FXIP Azure platform**<br><br>Key activities:<br>1. Inventory FXIP Azure resources<br>2. Plan phased decommission<br>3. Execute decommission with rollback windows<br>4. Validate cost reductions | **Primary Outcome:**<br>1. FXIP footprint safely decommissioned<br>2. Compliance and risk managed<br>3. Cost reduction achieved |

The primary objective of Phase 0 is to cut-over reduce risk.
Phases 1–3 target controlled, reversible executions of a rehearsed plan for migration and cut-over.

---

## 3. Phase 0 – Non‑Prod Readiness and Verification

### 3.1 Epic E0-01 – AWS Platform & Network Foundation Readiness

**Goal:** EKS, MSK, Global DocumentDB, S3 (via MRAP), Route 53, AWS ARC and Direct Connect are fully provisioned, secure, and validated in non‑prod east and west for NXOP.

#### E0‑01 – Story Summary

| Story ID  | Title                                                     | Env Scope              | Description & Key Tasks                                                                                           | DoD / Acceptance Criteria                                                                                       |
|-----------|-----------------------------------------------------------|------------------------|-------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| E0‑01‑S1  | Provision EKS clusters (east & west) with pod identities  | Non‑prod east & west   | **Key Tasks:**<br>1. Create multi‑AZ EKS clusters for NXOP<br>2. Configure CNI, autoscaler, ingress, network policies<br>3. Enable IRSA<br>4. Deploy sample NXOP microservice via CI/CD | **Acceptance Criteria:**<br>1. EKS clusters up in both regions<br>2. Sample NXOP SpringBoot service deployed via CI/CD<br>3. Pods assume IAM roles via IRSA<br>4. Readiness and liveness probes pass consistently |
| E0‑01‑S2  | Provision MSK clusters with IAM and OIDC auth             | Non‑prod east & west   | **Key Tasks:**<br>1. Create MSK clusters for NXOP<br>2. Configure IAM auth for internal producers/consumers<br>3. Configure OIDC client credentials for external clients<br>4. Create NXOP topics (APIs, adapters, processors, connectors) | **Acceptance Criteria:**<br>1. MSK clusters reachable from EKS pods using IAM auth<br>2. External test client connects via OIDC<br>3. All required topics created with documented naming and retention<br>4. Test messages successfully produced and consumed in both regions |
| E0‑01‑S3  | Configure MSK bi‑directional cross‑region replication     | Non‑prod east & west   | **Key Tasks:**<br>1. Implement east↔west replication between NXOP MSK clusters (MSK Replicator/Kafka Connect)<br>2. Configure replication for selected topics<br>3. Include topics feeding vendor systems, FXIP, OpsHub, and CCI‑related flows<br>4. Test cross‑region behavior | **Acceptance Criteria:**<br>1. Cross‑region replication configured for relevant topics<br>2. Simulated failover shows messages appear in either region within SLA<br>3. No unacceptable duplication/order issues for idempotent consumers |
| E0‑01‑S4  | Provision Global DocumentDB & validate MongoDB compatibility | Non‑prod shared      | **Key Tasks:**<br>1. Provision Global DocumentDB (multi‑region) for NXOP<br>2. Validate compatibility with FXIP MongoDB schemas and query patterns<br>3. Validate TLS and region‑aware connectivity from EKS<br>4. Test stateful services and Azure Table‑based metadata compatibility | **Acceptance Criteria:**<br>1. Global DocumentDB cluster running with automated backups and encryption<br>2. CRUD and query tests pass against primary and regional replicas<br>3. NXOP services connect from EKS using IRSA+Secrets Manager<br>4. Documented client connection strategy for regional failover |
| E0‑01‑S5  | Provision S3 buckets with MRAP for long‑term storage and lifecycle | Non‑prod shared | **Key Tasks:**<br>1. Create S3 buckets for NXOP long‑term storage<br>2. Configure encryption, block public access, bucket policies, lifecycle rules<br>3. Configure Multi‑Region Access Point (MRAP) for global accessibility<br>4. Map Azure Blob containers from FXIP to S3 structure | **Acceptance Criteria:**<br>1. S3 buckets created with encryption and no public access<br>2. MRAP configured for relevant buckets<br>3. Access to S3 via MRAP from both regions validated<br>4. Lifecycle policies configured and validated; Blob→S3 mapping documented and approved |
| E0‑01‑S6  | Configure Route 53 zones & integrate with Akamai/InfoBlox | Non‑prod DNS           | **Key Tasks:**<br>1. Design DNS for NXOP across Akamai GTM, Route 53, Azure Traffic Manager<br>2. Configure for coexistence with FXIP<br>3. Integrate with InfoBlox<br>4. Configure hosted zones and health checks | **Acceptance Criteria:**<br>1. NXOP non‑prod endpoints resolvable externally and internally<br>2. Health checks configured for EKS ingress<br>3. DNS resolution via Akamai, Route 53 and InfoBlox validated |
| E0‑01‑S7  | Configure AWS ARC and SSM documents for failover          | Non‑prod east & west   | **Key Tasks:**<br>1. Implement ARC routing controls for NXOP east/west endpoints<br>2. Create SSM documents for regional traffic failover<br>3. Dry‑run failover between regions | **Acceptance Criteria:**<br>1. ARC routing controls deployed for relevant NXOP non‑prod endpoints<br>2. SSM documents successfully switch endpoints<br>3. RTO/RPO for regional failover measured and documented |

---

### 3.2 Epic E0-02 – Data Migration & Synchronization Readiness

**Goal:** Design and validate FXIP MongoDB + Azure Tables/Blob → NXOP Global DocumentDB + S3 (via MRAP) migration and EventHub↔MSK, MQ↔MSK synchronization to support FXIP coexistence.

#### E0‑02 – Story Summary

| Story ID  | Title                                                  | Env Scope     | Description & Key Tasks                                                                                                     | DoD / Acceptance Criteria                                                                                                  |
|-----------|--------------------------------------------------------|---------------|-----------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| E0‑02‑S1  | Design data migration and sync strategy                | Non‑prod      | **Key Tasks:**<br>1. Define migration strategy from FXIP Confluent MongoDB to NXOP Global DocumentDB<br>2. Plan Azure Tables→DocumentDB and Azure Blob→S3 (MRAP‑backed buckets) migrations<br>3. Define full‑load and incremental sync<br>4. Plan cut‑over (dual‑write/CDC/freeze window) and reconciliation/rollback strategy | **Acceptance Criteria:**<br>1. Migration design approved<br>2. All FXIP collections/tables/containers inventoried and classified<br>3. Sequencing, downtime and rollback clearly defined<br>4. Data owners sign off |
| E0‑02‑S2  | Implement and test MongoDB → Global DocumentDB tooling | Non‑prod      | **Key Tasks:**<br>1. Implement tooling to migrate FXIP MongoDB data into NXOP Global DocumentDB<br>2. Run full load in non‑prod<br>3. Validate schema mapping and transformations | **Acceptance Criteria:**<br>1. Full migration load completed in non‑prod<br>2. Row counts and key metrics match within tolerance<br>3. Migration window within plan |
| E0‑02‑S3  | Implement Azure Tables & Blob → DocumentDB & S3 (MRAP) | Non‑prod      | **Key Tasks:**<br>1. Migrate FXIP Azure Tables metadata into DocumentDB collections<br>2. Move Blob objects representing documents into S3 buckets fronted by MRAP<br>3. Validate metadata→S3 linkage using MRAP endpoints | **Acceptance Criteria:**<br>1. Non‑prod Azure Tables and Blob data fully migrated and validated<br>2. NXOP apps/admin tools retrieve documents correctly via DocumentDB metadata and S3 MRAP endpoints |
| E0‑02‑S4  | Implement EventHub, MQ, MSK adapters/connectors       | Non‑prod      | **Key Tasks:**<br>1. Build and deploy adapters/connectors for NXOP:<br>— EventHub→MSK connector (FXIP→NXOP)<br>— MSK→EventHub (Kafka) adapter (NXOP→FXIP)<br>— MSK→On‑Prem MQ adapter (NXOP→OpsHub)<br>— On‑Prem MQ→MSK adapter (OpsHub→NXOP)<br>2. Define topics/queues, ordering, idempotency and error‑handling strategy | **Acceptance Criteria:**<br>1. All four adapter/connector paths operational in non‑prod<br>2. Latency within SLAs<br>3. No data loss or unacceptable duplication<br>4. Mapping of FXIP EventHub/MQ topics/queues to NXOP MSK topics documented |
| E0‑02‑S5  | Implement data reconciliation framework                | Non‑prod      | **Key Tasks:**<br>1. Build reconciliation tooling comparing FXIP vs NXOP data for key entities:<br>— MongoDB vs Global DocumentDB<br>— Azure Tables vs DocumentDB<br>— Blob vs S3 MRAP buckets<br>2. Define thresholds and exception processes | **Acceptance Criteria:**<br>1. Automated reconciliation available for critical datasets<br>2. Exception thresholds and handling process agreed<br>3. Data owners sign off |
| E0‑02‑S6  | Dress rehearsal of data migration in non‑prod          | Non‑prod      | **Key Tasks:**<br>1. Execute end‑to‑end rehearsal:<br>— Full load, delta sync<br>— Use of adapters/connectors (EventHub, MQ)<br>— Cut‑over simulation<br>— Rollback simulation<br>2. Capture timings and issues | **Acceptance Criteria:**<br>1. Rehearsal completed<br>2. All flows including FXIP integrations (EventHub, OpsHub MQ) use NXOP migration path<br>3. Migration and rollback complete within planned windows<br>4. Rehearsal report approved; production migration runbook updated |

---

### 3.3 Epic E0-03 – Connectivity and Integration to Vendors, FXIP, OpsHub & On‑Prem Readiness

**Goal:** All vendor systems (FlightKeys, CyberJet FMS, IBM Fusion Flight Tracking), FXIP integrations (EventHub, CCI), on‑prem OpsHub via MQ, and other on‑prem systems are functioning end‑to‑end from NXOP in AWS non‑prod.

#### E0‑03 – Story Summary

| Story ID  | Title                                                                  | Env Scope     | Description & Key Tasks                                                                                                                                                                                                                                     | DoD / Acceptance Criteria                                                                                                                                       |
|-----------|------------------------------------------------------------------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| E0‑03‑S1  | Validate Direct Connect & on‑prem network paths                        | Non‑prod      | **Key Tasks:**<br>1. Confirm Direct Connect routing from NXOP VPCs to on‑prem networks<br>2. Validate IP ranges, firewalls, SGs, NACLs<br>3. Test connectivity from EKS pods to all on‑prem endpoints used by NXOP microservices<br>4. Include OpsHub MQ and other on‑prem APIs | **Acceptance Criteria:**<br>1. Connectivity validated to all on‑prem targets<br>2. Traceroute/reachability analysis performed<br>3. Connectivity matrix (IPs, ports, protocols, services) documented and agreed with network/security teams |
| E0‑03‑S2  | Validate connectivity to vendor systems (FlightKeys, CyberJet FMS, IBM Fusion Flight Tracking) | Non‑prod | **Key Tasks:**<br>1. For FlightKeys and CyberJet FMS: validate connectivity from NXOP EKS to vendor RabbitMQ brokers/queues<br>2. For IBM Fusion Flight Tracking: validate HTTPS API connectivity (DNS, TLS, IP allowlists)<br>3. Simulate vendor regional failover where supported<br>4. Include Vienna DR endpoints as applicable | **Acceptance Criteria:**<br>1. All vendor RabbitMQ endpoints (FlightKeys, CyberJet FMS) reachable<br>2. NXOP test consumers can connect and read messages<br>3. IBM Fusion Flight Tracking APIs reachable and pass TLS/auth checks<br>4. Vendor DR/failover scenarios behave as expected |
| E0‑03‑S3  | Validate Apigee microgateway routing to NXOP APIs (including CCI integration) | Non‑prod  | **Key Tasks:**<br>1. Configure Apigee microgateways to route traffic to NXOP APIs in non‑prod<br>2. Validate authentication flows, contracts, headers, and error codes<br>3. Ensure FXIP consumers and CCI system can call NXOP APIs via Apigee<br>4. Verify no contract breaks | **Acceptance Criteria:**<br>1. All 7 NXOP APIs reachable via Apigee<br>2. Regression tests pass for internal consumers, external consumers, and CCI integration<br>3. No breaking changes to external API contracts |
| E0‑03‑S4  | Validate internal‑only endpoints & IP allowlists                       | Non‑prod      | **Key Tasks:**<br>1. Ensure internal NXOP endpoints resolve to internal IPs via InfoBlox/Route 53<br>2. Confirm internal IP allowlists updated for all internal consumers and systems<br>3. Include FXIP components, CCI, OpsHub, and other internal apps | **Acceptance Criteria:**<br>1. Internal endpoints resolvable to correct internal IPs<br>2. Access tests from expected internal consumers succeed (FXIP, CCI, OpsHub‑connected services)<br>3. IP allowlist updates approved by Security and Network |
| E0‑03‑S5  | Validate NXOP data adapters (Azure/on‑prem → vendor RabbitMQ and IBM APIs) | Non‑prod   | **Key Tasks:**<br>1. Deploy NXOP data adapter microservices in EKS non‑prod<br>2. Validate flows: Azure/FXIP/on‑prem sources → adapters → vendor RabbitMQ queues<br>3. Include FlightKeys, CyberJet FMS, and IBM Fusion Flight Tracking APIs<br>4. Verify payload transformations and routing logic | **Acceptance Criteria:**<br>1. All adapters function correctly in non‑prod<br>2. End‑to‑end test cases pass from source systems through adapters to vendor RabbitMQ queues/APIs<br>3. Behavior equivalent or improved over FXIP implementation |
| E0‑03‑S6  | Validate NXOP data processors (vendor RabbitMQ/APIs → MSK)             | Non‑prod      | **Key Tasks:**<br>1. Deploy NXOP data processor microservices in EKS non‑prod<br>2. Validate processors consume from FlightKeys and CyberJet FMS RabbitMQ queues<br>3. Validate IBM Fusion APIs consumption<br>4. Publish transformed messages to appropriate NXOP MSK topics | **Acceptance Criteria:**<br>1. All processors read vendor RabbitMQ queues and IBM Fusion APIs correctly<br>2. Publish to MSK topics correctly<br>3. Payloads validated against schemas<br>4. Retry/backoff and error handling behaviors tested |
| E0‑03‑S7  | Validate microservices with on‑prem API and MQ integrations (OpsHub, others) | Non‑prod   | **Key Tasks:**<br>1. For NXOP microservices calling on‑prem APIs or integrating via OpsHub MQ:<br>— Validate DNS, TLS/mTLS (if applicable)<br>— Validate authentication, MQ channel config<br>— Validate timeouts, retries, error handling<br>2. Ensure only authorized NXOP services reach endpoints | **Acceptance Criteria:**<br>1. All such NXOP services reach on‑prem APIs and OpsHub MQ<br>2. Timeouts, retries, circuit breakers work as designed<br>3. Failures observable in logs/metrics<br>4. Access restricted by network policies and IAM |
| E0‑03‑S8  | Validate NXOP→FXIP EventHub integration for downstream FXIP consumers  | Non‑prod      | **Key Tasks:**<br>1. Validate that NXOP feeds FXIP Azure EventHub via MSK→EventHub adapter<br>2. Confirm FXIP applications consuming from EventHub continue to function<br>3. Include FXIP components and downstream systems<br>4. Validate expected behavior while NXOP is the source | **Acceptance Criteria:**<br>1. MSK→EventHub adapter functioning<br>2. FXIP EventHub consumers receive correct messages from NXOP<br>3. No functional regression for FXIP downstream consumers<br>4. Mapping of NXOP topics to FXIP EventHub topics documented |

---

### 3.4 Epic E0-04 – Security, Identity, Secrets & Certificates Readiness

**Goal:** Ensure a secure‑by‑design NXOP platform across IAM, pod identities, secrets, certificates, SSO, and IP allowlists.

#### E0‑04 – Story Summary

| Story ID  | Title                                                   | Env Scope | Description & Key Tasks                                                                                         | DoD / Acceptance Criteria                                                                                   |
|-----------|---------------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| E0‑04‑S1  | Implement pod identities (IRSA) for all NXOP services   | Non‑prod | **Key Tasks:**<br>1. Map each NXOP microservice and admin tool to IAM roles via IRSA<br>2. Define least‑privilege policies for MSK, Global DocumentDB, S3 (MRAP), Secrets Manager, CloudWatch<br>3. Remove static credentials from configuration | **Acceptance Criteria:**<br>1. All NXOP services in non‑prod use IRSA<br>2. No hard‑coded secrets<br>3. IAM policies reviewed and approved by Security<br>4. Automated tests confirm least‑privilege access |
| E0‑04‑S2  | Implement Vault → AWS Secrets Manager replication       | Non‑prod | **Key Tasks:**<br>1. Design secure replication of secrets from Hashicorp Vault into AWS Secrets Manager for NXOP<br>2. Define naming and rotation policies<br>3. Monitor sync | **Acceptance Criteria:**<br>1. All required NXOP secrets present in Secrets Manager<br>2. Sync process monitored with alerts<br>3. Procedures for updating secrets and verifying propagation documented |
| E0‑04‑S3  | Update NXOP services to use AWS Secrets Manager         | Non‑prod | **Key Tasks:**<br>1. Refactor NXOP service configuration for Secrets Manager retrieval via IRSA<br>2. Ensure secrets not embedded in images or plain‑text configs<br>3. Validate runtime secret access | **Acceptance Criteria:**<br>1. All NXOP services retrieve secrets exclusively from Secrets Manager<br>2. No secrets in container images or unencrypted configs<br>3. Secret rotation test executed successfully |
| E0‑04‑S4  | SSL/TLS certificate management in ACM and vendor PKI    | Non‑prod | **Key Tasks:**<br>1. Manage TLS certificates for NXOP external APIs, vendor connections, internal tools<br>2. Use ACM and vendor CA<br>3. Ensure trust chains between AWS workloads and on‑prem/vendor systems<br>4. Attach ACM certs to NXOP ingress and load balancers | **Acceptance Criteria:**<br>1. All NXOP HTTPS endpoints use valid certificates<br>2. TLS handshake tests pass from FXIP, vendors, CCI, OpsHub<br>3. Certificate inventory and renewal process documented and monitored |
| E0‑04‑S5  | Validate Ping Identity + Entra ID access to NXOP tools  | Non‑prod | **Key Tasks:**<br>1. Integrate SSO into NXOP admin web UI via Ping Identity and Entra ID<br>2. Integrate SSO into AWS‑hosted operational tools<br>3. Implement RBAC and test | **Acceptance Criteria:**<br>1. NXOP admin UI and tools accessible via SSO<br>2. RBAC enforced<br>3. Security/pen‑test of SSO and RBAC passed or mitigations agreed |
| E0‑04‑S6  | Validate IP allowlists and firewall rules               | Non‑prod | **Key Tasks:**<br>1. Compile IP ranges/endpoints for vendors (FlightKeys, CyberJet FMS, IBM Fusion), FXIP, CCI, OpsHub, and admin access<br>2. Ensure firewalls and IP allowlists updated for NXOP egress and ingress | **Acceptance Criteria:**<br>1. All critical flows (vendor, FXIP, CCI, OpsHub) succeed from NXOP<br>2. No unnecessary open ingress/egress<br>3. Security and Network sign‑off obtained |

---

### 3.5 Epic E0-05 – Observability, Monitoring, Logging & Alerting Readiness

**Goal:** Ensure NXOP logging, metrics, and alerting (Mezmo, Dynatrace, CloudWatch, PagerDuty) support end‑to‑end observability, including vendor, FXIP, CCI, and OpsHub integrations.

#### E0‑05 – Story Summary

| Story ID  | Title                                            | Env Scope | Description & Key Tasks                                                                                               | DoD / Acceptance Criteria                                                                                   |
|-----------|--------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| E0‑05‑S1  | Configure Mezmo logging for NXOP workloads       | Non‑prod | **Key Tasks:**<br>1. Configure log shipping from NXOP EKS (Fluent Bit/Fluentd/sidecars) to Mezmo<br>2. Standardize log formats, correlation IDs, log levels<br>3. Apply across NXOP microservices, adapters, processors, connectors | **Acceptance Criteria:**<br>1. Logs from all NXOP non‑prod microservices and admin tools appear in Mezmo<br>2. End‑to‑end transaction tracing possible using correlation IDs<br>3. Logging standards documented and adopted |
| E0‑05‑S2  | Configure Dynatrace for NXOP (EKS, MSK, Global DocumentDB) | Non‑prod | **Key Tasks:**<br>1. Deploy Dynatrace agents/operator for NXOP EKS clusters<br>2. Integrate MSK and Global DocumentDB metrics<br>3. Instrument key NXOP Java/SpringBoot transactions<br>4. Include vendor, FXIP, CCI, OpsHub flows | **Acceptance Criteria:**<br>1. All NXOP services visible in Dynatrace<br>2. Service maps available<br>3. Dashboards for EKS, MSK, DocumentDB created<br>4. Baseline performance metrics captured |
| E0‑05‑S3  | Configure CloudWatch dashboards and alarms       | Non‑prod | **Key Tasks:**<br>1. Create NXOP CloudWatch dashboards for EKS nodes, MSK brokers, DocumentDB instances/replicas, S3 MRAP endpoints, network<br>2. Configure alarms for critical metrics:<br>— CPU, memory, latency, error rate<br>— Disk, queue depth, replication lag | **Acceptance Criteria:**<br>1. Dashboards implemented and documented<br>2. Alarms defined and successfully tested<br>3. Integration to PagerDuty confirmed |
| E0‑05‑S4  | Integrate PagerDuty with NXOP monitoring         | Non‑prod | **Key Tasks:**<br>1. Configure PagerDuty services and escalation policies for NXOP<br>2. Integrate CloudWatch and Dynatrace alerts<br>3. Define on‑call rota | **Acceptance Criteria:**<br>1. Test incidents from NXOP non‑prod generate PagerDuty alerts<br>2. Correct escalation followed<br>3. On‑call rota documented<br>4. No misrouted alerts |
| E0‑05‑S5  | Define and validate SLOs/SLIs for critical NXOP flows | Non‑prod | **Key Tasks:**<br>1. Define SLIs and SLOs for critical NXOP flows:<br>— Vendor data (RabbitMQ, IBM Fusion APIs)<br>— FXIP EventHub/MQ flows<br>— CCI API integration<br>— OpsHub MQ flows<br>2. Implement SLO dashboards and alerts | **Acceptance Criteria:**<br>1. SLOs/SLA targets agreed with business<br>2. SLO dashboards implemented<br>3. SLO breach warnings and alerts tested for key NXOP flows |

---

### 3.6 Epic E0-06 – Non‑Prod Functional, Performance, Chaos & DR Testing Readiness

**Goal:** Execute end‑to‑end functional, performance, chaos, DR, and cut‑over rehearsals for NXOP in non‑prod, including MSK and Global DocumentDB regional failover and all critical integrations (FXIP, vendors, CCI, OpsHub).

#### E0‑06 – Story Summary

| Story ID  | Title                                       | Env Scope           | Description & Key Tasks                                                                                                    | DoD / Acceptance Criteria                                                                                     |
|-----------|---------------------------------------------|---------------------|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| E0‑06‑S1  | End‑to‑end functional regression            | Non‑prod            | **Key Tasks:**<br>1. Execute full regression across 21 NXOP microservices (APIs, adapters, processors, integration services) and 6 admin tools<br>2. Cover vendor flows (FlightKeys, CyberJet FMS, IBM Fusion)<br>3. Cover FXIP EventHub feeds, OpsHub MQ adapters, CCI API integration | **Acceptance Criteria:**<br>1. 100% of agreed regression executed<br>2. All critical/high defects resolved or explicitly accepted with mitigation<br>3. Business and QA sign off NXOP functional readiness |
| E0‑06‑S2  | Performance and scalability testing         | Non‑prod (perf env) | **Key Tasks:**<br>1. Define workload models for NXOP typical and peak loads<br>2. Cover critical flows (vendor queues/APIs, FXIP EventHub/MQ, CCI)<br>3. Execute performance tests<br>4. Validate autoscaling of EKS, MSK, Global DocumentDB | **Acceptance Criteria:**<br>1. NXOP meets throughput and latency targets under peak load<br>2. No critical bottlenecks<br>3. Autoscaling policies validated and tuned |
| E0‑06‑S3  | Chaos and resilience testing                | Non‑prod            | **Key Tasks:**<br>1. Inject failures impacting NXOP:<br>— EKS node/pod crashes<br>— MSK broker failures<br>— Global DocumentDB node/region failover<br>— Vendor unavailability (RabbitMQ and APIs)<br>— FXIP EventHub connectivity issues<br>— OpsHub MQ connectivity<br>2. Validate NXOP self‑healing and fallback behavior | **Acceptance Criteria:**<br>1. For each injected failure, NXOP recovers within agreed RTO<br>2. No data loss beyond agreed RPO<br>3. Resiliency gaps documented with remediation plans |
| E0‑06‑S4  | DR and regional failover testing (ARC, MSK, Global DocumentDB) | Non‑prod east/west | **Key Tasks:**<br>1. Execute DR tests switching NXOP traffic between AWS east and west via ARC+SSM<br>2. Validate MSK cross‑region replication under failover<br>3. Validate Global DocumentDB regional failover (planned and unplanned)<br>4. Test client reconnection and vendor/FXIP/CCI/OpsHub impact<br>5. Note: S3 uses MRAP—no explicit replication/failover needed | **Acceptance Criteria:**<br>1. DR tests executed with pre/post metrics<br>2. MSK replication continues to meet RPO<br>3. Global DocumentDB failover causes no data loss beyond RPO<br>4. NXOP applications reconnect correctly<br>5. RTO/RPO measured and documented; DR Runbook updated |
| E0‑06‑S5  | Cut‑over simulation for FXIP migration Phases 1–3 | Non‑prod      | **Key Tasks:**<br>1. Rehearse Phase 1–3 for NXOP in non‑prod:<br>— DNS and routing changes<br>— EventHub↔MSK and MQ↔MSK adapter direction changes<br>— Publisher coordination table updates<br>— FXIP and CCI endpoint shifts<br>2. Test rollback for each scenario | **Acceptance Criteria:**<br>1. Full simulated cut‑over and rollback for each phase executed successfully<br>2. Steps, timings, pre‑requisites, responsibilities documented in cut‑over runbooks and RACI<br>3. Scenarios include FXIP, CCI, OpsHub, and vendor integrations |

---

## 4. Phases 1–4 – Production Cut‑over & Decommission

### 4.1 Phase 1 – Replace current BCP with NXOP East with feed to Vienna FlightKeys

| Aspect        | Summary                                                                                           |
|---------------|---------------------------------------------------------------------------------------------------|
| Objective     | Use NXOP as AWS BCP, publishing only to vendor Vienna DR (for applicable vendor endpoints).      |
| Scope         | Flows that publish to Vienna only; FXIP remains primary for normal operations.                    |

Key activities (informed by Phase 0 rehearsals):

1. Validate Vienna‑only configuration in NXOP non‑prod, including vendor DR endpoints.
2. Execute DNS and routing changes to direct BCP traffic via NXOP→Vienna in production.
3. Run Vienna‑only validation tests for vendor flows.
4. Establish rollback criteria and test rollback in non‑prod before production change.

---

### 4.2 Phase 2 – Cut‑over Low‑Risk Microservices

| Aspect        | Summary                                                                                                      |
|---------------|--------------------------------------------------------------------------------------------------------------|
| Objective     | Migrate a selected set of low‑risk NXOP microservices into production to gain experience with live traffic. |
| Scope         | Low‑risk services only (minimal critical dependencies on vendors, FXIP, CCI, OpsHub) initially.             |

Key activities:

1. Classify all 21 NXOP microservices by risk category; agree low‑risk list with stakeholders.
2. Confirm non‑prod readiness (E0‑01 to E0‑06) for each selected service.
3. Execute production cut‑over for low‑risk NXOP services (DNS, routing, MSK topic routes, connectors).
4. Run a stabilization period where FXIP remains primary or BCP for relevant flows; monitor metrics and SLOs.
5. Test rollback for at least one representative low‑risk service in non‑prod and integrate findings into Phase 2 rollback runbook.

---

### 4.3 Phase 3 – Cut‑over Remaining Microservices (Azure FXIP as BCP)

| Aspect        | Summary                                                                                                 |
|---------------|---------------------------------------------------------------------------------------------------------|
| Objective     | Cut‑over all remaining microservices so NXOP becomes the primary platform; FXIP remains BCP for a period. |

Key activities:

1. Conduct final readiness review (functional, performance, security, DR) with stakeholders; obtain Go/No‑Go.
2. Update publisher coordination tables so NXOP east/west publishers become the active region(s) for vendor systems, FXIP EventHub, OpsHub MQ, and CCI‑relevant flows.
3. Execute main production cut‑over window:
   - DNS updates in Akamai, Route 53, InfoBlox
   - EventHub↔MSK and MQ↔MSK adapter direction changes
   - IP allowlist updates and Apigee routing changes toward NXOP APIs
4. Conduct post‑cut‑over validation and regression in production, including vendor, FXIP, CCI, and OpsHub flows.
5. Validate FXIP as BCP via a DR drill where feasible (switching certain flows back to FXIP temporarily) before fully retiring FXIP as BCP.

---

### 4.4 Phase 4 – Azure FXIP Decommission

| Aspect        | Summary                                                                                         |
|---------------|-------------------------------------------------------------------------------------------------|
| Objective     | Safely decommission FXIP Azure components after NXOP is stable and FXIP is no longer required.  |

Key activities:

1. Inventory FXIP Azure resources (AKS, EventHubs, MongoDB, Azure Tables/Blob, networking, DNS, OpsHub‑related components).
2. Confirm data retention and compliance requirements; decide archival strategy (e.g., copy residual data to NXOP S3 MRAP buckets/Glacier if needed).
3. Plan and schedule phased FXIP decommission (starting with non‑critical components, ending with critical ones) with rollback windows and communication plan.
4. Execute FXIP decommission, ensuring no NXOP dependencies remain; validate cost reductions and confirm no residual FXIP usage.
5. Produce FXIP decommission closure report with Platform, Security, and Finance sign‑off.

---

## 5. Runbooks & Documentation Required

The following must be authored, reviewed, and finalised prior to Phase 3 Go/No‑Go:

| Category      | Runbook / Documentation                                                                        |
|---------------|------------------------------------------------------------------------------------------------|
| Platform      | 1. EKS Provisioning & Operations (NXOP)<br>2. EKS Upgrade & Rollback<br>3. MSK Design & Operations<br>4. MSK Replication Runbook<br>5. Global DocumentDB Design & Operations (incl. regional failover)<br>6. S3 MRAP Operations & Lifecycle Policy |
| Data          | 1. Data Migration Design (FXIP→NXOP)<br>2. MongoDB→DocumentDB Migration Runbook<br>3. Azure Tables/Blob Mapping (FXIP→NXOP via S3 MRAP)<br>4. Data Reconciliation Framework & SOP<br>5. Migration Rehearsal Report<br>6. Production Migration Runbook |
| Connectivity  | 1. Network Connectivity Matrix (NXOP↔On‑Prem, NXOP↔FXIP, NXOP↔Vendors, NXOP↔CCI)<br>2. Direct Connect Operations Runbook<br>3. Vendor & On‑Prem Integration Matrix (FlightKeys, CyberJet FMS, IBM Fusion, OpsHub MQ)<br>4. Apigee Routing & Rollback Runbook (FXIP→NXOP APIs)<br>5. Internal Endpoint Catalog<br>6. IP Allowlist Register |
| Security      | 1. IAM Role Catalog per NXOP Service<br>2. IRSA Access Review Document<br>3. Secrets Replication Design & Sync Runbook (Vault→Secrets Manager)<br>4. Secrets Consumption Patterns<br>5. Secret Rotation Runbook<br>6. Certificate Inventory & Renewal Schedule<br>7. TLS Validation Runbook<br>8. Access Control Matrix<br>9. SSO (Ping/Entra) Integration Runbook<br>10. Firewall Change Runbook |
| Observability | 1. Logging Standards for NXOP<br>2. Mezmo Integration Runbook<br>3. Observability Design (Dynatrace, CloudWatch) for NXOP<br>4. Dynatrace Dashboard Catalog<br>5. CloudWatch Dashboard Definitions<br>6. Monitoring & Alerting Runbook<br>7. Incident Management Playbook<br>8. PagerDuty Integration Runbook<br>9. SLO/SLA Agreement<br>10. SLO Monitoring Runbook |
| Resilience & DR | 1. DR Runbook (AWS) including MSK and Global DocumentDB regional failover for NXOP (and S3 MRAP connectivity verification)<br>2. DR Test Reports (east↔west failover)<br>3. Azure FXIP BCP Runbook (post‑migration use)<br>4. Chaos Test Plan<br>5. Resiliency Assessment Report |
| Cut-over      | 1. Master FXIP→NXOP Cut‑over Runbook (Phases 1–3)<br>2. Phase‑specific DNS/Connector Change & Rollback Plans<br>3. Cut‑over RACI Matrix<br>4. Go‑Live Readiness Checklist<br>5. Production Validation Checklist |
| Decommission  | 1. FXIP Azure Asset Inventory<br>2. Data Retention & Compliance Document<br>3. FXIP Decommission Change Plan<br>4. FXIP Decommission Execution Runbook<br>5. FXIP Decommission Closure Report |

---

## 6. Cut‑over Risk & Mitigation Overview

| Risk Category | Risk Description | Mitigation Strategies |
|---------------|------------------|----------------------|
| Data Integrity | Inconsistent state between FXIP and NXOP during coexistence | 1. E0‑02 migration design (FXIP→NXOP)<br>2. EventHub/MQ↔MSK connectors<br>3. Reconciliation framework<br>4. Migration rehearsal E0‑02‑S6 |
| Vendor / On‑Prem Connectivity | Vendor (FlightKeys, CyberJet FMS, IBM Fusion) or OpsHub MQ endpoints unreachable | 1. E0‑03 vendor and OpsHub connectivity validation<br>2. IP Allowlist Register<br>3. Early vendor/on‑prem coordination<br>4. Non‑prod failover tests |
| FXIP Dependencies | FXIP downstream consumers (EventHub, CCI) broken by NXOP cut‑over | 1. E0‑02 adapters (MSK↔EventHub, MQ↔MSK)<br>2. E0‑03‑S3 (Apigee/CCI)<br>3. E0‑03‑S8 (NXOP→FXIP EventHub)<br>4. E0‑06 functional regression including FXIP flows |
| Security Gaps | Misconfigured IAM or secrets causing outages or vulnerabilities | 1. E0‑04 IRSA rollout<br>2. Vault→Secrets Manager replication<br>3. Access reviews<br>4. Secret rotation tests and remediation |
| Observability | Insufficient visibility, leading to slow incident detection and diagnosis | 1. E0‑05 unified logging/APM<br>2. CloudWatch dashboards<br>3. PagerDuty integration<br>4. SLO dashboards for vendor/FXIP/CCI/OpsHub flows |
| DR & Failover | Regional failure of AWS region hosting NXOP MSK/DocumentDB/front‑door endpoints | 1. E0‑01 MSK replication and Global DocumentDB design<br>2. E0‑06‑S4 DR tests using ARC, MSK replication, Global DocumentDB regional failover<br>3. S3 MRAP configuration removes need for S3 replication/failover<br>4. FXIP retained as BCP in Phase 3 |
| Operational Readiness | NXOP teams unfamiliar with AWS tooling and new runbooks | 1. Runbook authoring and training<br>2. Non‑prod cut‑over simulations E0‑06‑S5<br>3. DR and incident drills<br>4. Gradual ramp‑up via Phase 2 low‑risk cut‑over |

## 7. List of NXOP Services

The following Services are in-scope for this migration.

| # | AWS microservice | GitHub repo name | Message flow ID | Inbound | Outbound | Description |
|---|------------------|------------------| ----------------|---------|----------| ------------|
| 1 | Flight data adaptor (FDA) | nxop-fxip-flightkeys-data-adaptor | 1, 10 | Kafka | API | Reads operational data from OpsHub Eventhub via Kafka topics and posts it to Flightkeys APIs via HTTPS protocol. |
| 2 | Aircraft data adaptor (ADA)  | nxop-fxip-aircraft-data-adaptor | 1, 18 | Kafka | API | Reads MEL, Fuel, Crew, and ACARS Position Report information from OpsHub Eventhub via Kafka topics and posts it to Flightkeys APIs via HTTPS protocol. |
| 3 | Fusion flight movement adaptor (FFM) | nxop-fxip-fusion-flight-movement-adaptor | 19 | Kafka | API | Reads OOOI and other related flight data from OpsHub OnPrem and sends it to the Fusion desktop application via webservices. |
| 4 | Audit log processor (ALP) | nxop-fxip-audit-log-processor | 5 | AMQP | Kafka | Consume Flight Plan, Weather and OFP(Operational Flight Plan) XML messages from Flight Keys Rabbit MQ  and compress those messages and send to OpsHub Kafka topics and on to Orion for audit log. |
| 5 | Flight plan processor (FPP) | nxop-fxip-flight-plan-processor | 2 | AMQP | Kafka | Processes the ARINC 633 flight plans from Flightkeys and produce the flight plan events to Ops Hub topic in EventHub. |
| 6 | FlightKeys event processor (FEP) | nxop-fxip-flightkeys-event-processor | 3, 9, 10 | AMQP | API | Reads Flightkeys events and makes JPY, JPFF and PR entries to FOS using LCA Flight Update Proxy via Ops Hub On-Prem |
| 7 | Text message processor (TMP) | nxop-fxip-text-message-processor | 6, 14 | AMQP | API | Consumes Flightkeys queue for free text messages from dispatchers, using FTM Uplink Proxy or Host Print Proxy Service to issue FOS commands to send teletype messages to cockpit crews |
| 8 | FOS update processor (FUP) | nxop-fxip-fos-update-processor | 4 | AMQP | API | Reads Flight Plan Information from the Flightkeys RabittMQ in XML format and sends it to Opshub FTMUplinkFOS endpoint as a comma delimited string which will eventually update FOS. |
| 9 | Notification services (SNS) | nxop-fxip-notification-service | 7 | AMQP | API | Receives flight plans via FlightInfor API from OpsHub OnPrem, and sends notifications (HTTP APIs) for Crew Check-In and ACARS (via FTP Uplink Proxy). |
| 10 | Fusion integration adaptor (FIA) | nxop-fxip-fusion-integration-adaptor | 20 | AMQP | API | Consumes FlightPlan messages produced by FlightKeys that are published over RabbitMQ and transforms the data to a TWC Fusion format and sends to Fusion endpoints via a webservice call |
| 11 | FK integration service (FIS) | nxop-fxip-flightkeys-integration-service | 8, 9 | API | API | "The Flightkeys Integration service is a REST based JSON API for 3 reasons: 1. CCI calls this service to post Pilot eSignatures from CCI to FlightKeys 2. This Service calls FlightKeys to pull Flight Plan Briefings in PDF format for cockpit crew 3. This Service provides status to CCI" |
| 12 | Flight plan service (FPS) | nxop-fxip-flight-plan-service | 8 | API | API | "The Flight plan service is a REST based JSON API that is used for: 1. Pull Flight Plan Briefings in PDF format for cockpit crew 2. Pull Operation Flight Plan (OFP) from FKYS in ARINC 633 XML format for OE and FPS business groups 3. To pull weather info and NOTAMS info in pdf format" |
| 13 | Data maintenance service (DMS) | nxop-fxip-data maintenance-service | 23 | API | API | API called by Special Information Messages – FOS F2, F4, J8 messages, etc., and posts them to FlightKeys. |
| 14 | Pilot document service (PDS) | nxop-fxip-pilot document-service | 8 | API | API | API to enable the storage of CCI electronic flight briefing package (e.g. OpsTrak CCIEFP) for regulatory audit trail purposes.   |
| 15 | Aircraft data service (ADS) | nxop-fxip-aircraft-data-service | 16 | API | API | API to enable the maintenance of aircraft / fleet data required by the Flight Planning System.   |
| 16 | Nav data service (NDS) | nxop-fxip-nav-data-service | 17 | API | API | API to enable maintenance of statistical fuel values (i.e. Performance Based Contingency Fuel, QBR) in the Flightkeys system.   |
| 17 | Fusion ACARS service (FAS) | nxop-fxip-fusion-acars-service | 22 | API | API | Enables the Dispatcher ability to send text messages to the flight deck of the aircraft to inform crew on various issues |
| 18 | Terminal area forecast UI (TAFU) | nxop-fxip-weatherapp | 24 | API | API | The Terminal Aerodrome Forecast application is responsible for retrieving the latest Terminal Aerodrome Forecast (TAF) based on the given Airport Code. Once the meteorologists in the IOC verify the given TAF, they have the option to cancel the TAF |
| 19 | FTM Uplink Proxy (FTS) | OpsHub_Proxy_FTMUplinkService-Apigee-nxop | 4,  7, 14, 22 |  API | API | Proxy to On-prem OpsHub Service |
| 20 | Host Print Proxy (HPS) | OpsHub_Proxy_HostPrintRequest-Apigee-nxop | 6 | API | API | Proxy to On-prem OpsHub Service |
| 21 | LCA Flight Update Proxy (FUS) | OpsHub_Proxy_FlightUpdateService-Apigee-nxop-eks | 3, 9, 10 | API | API | Proxy to On-prem OpsHub Service |
---
