# NXOP Message Flow Analysis

## Executive Summary

This document provides a comprehensive analysis of all 25 message flows in the NXOP (Network Operations Platform) system. The analysis focuses on integration patterns, dependencies, communication protocols, and architectural characteristics from the NXOP platform perspective.

### Key Findings

- **Total Message Flows**: 25 distinct integration patterns
- **Primary Integration Hub**: OpsHub On-Prem (100% of flows)
- **Primary Data Source**: Flightkeys (80% of flows)
- **Communication Protocols**: 6 protocols (HTTPS, AMQP, Kafka, MQ, ACARS, TCP)

---

## Table of Contents

1. [Integration Pattern Overview](#integration-pattern-overview)
2. [Message Flow Catalog](#message-flow-catalog)
3. [Source-to-Destination Patterns](#source-to-destination-patterns)
4. [NXOP Platform Dependencies](#nxop-platform-dependencies)
5. [Communication Patterns](#communication-patterns)
6. [Critical Dependencies](#critical-dependencies)
7. [Recommendations](#recommendations)

---

## Integration Pattern Overview

### Pattern Classification

The 25 message flows can be classified into 7 primary integration patterns:

| Pattern Type | Flow Count | Description |
|--------------|------------|-------------|
| **Inbound Data Ingestion** | 10 flows | External sources → NXOP → On-Prem |
| **Outbound Data Publishing** | 2 flows | On-Prem → NXOP → External systems |
| **Bidirectional Sync** | 6 flows | Two-way data synchronization |
| **Notification/Alert** | 3 flows | Event-driven notifications |
| **Document Assembly** | 1 flow | Multi-service document generation |
| **Authorization** | 2 flows | Electronic signature workflows |
| **Data Maintenance** | 1 flow | Reference data management |


---

## Message Flow Catalog

### Flow 1: Publish FOS Event Data to Flightkeys

**Pattern**: Outbound Data Publishing  
**Source**: FOS (On-Prem) → MQ → MQ-Kafka Adapter (On-Prem)  
**NXOP Components**: MSK, Flight Data Adapter, Aircraft Data Adapter (EKS in KPaaS), DocumentDB  
**Destinations**: Flightkeys (HTTPS)  
**Communication**: Asynchronous (MQ → Kafka → HTTPS)  

**Architecture Flow**:
1. **On-Prem Source**: FOS publishes events to MQ
2. **MQ-Kafka Adapter** (On-Prem): Consumes from FOS MQ and produces to MSK
3. **MSK Bootstrap**: Adapter uses Route53 DNS (kafka.nxop.com) → NLB → MSK brokers for bootstrap
4. **Direct Broker Connection**: After bootstrap, adapter produces directly to MSK brokers
5. **Cross-Region Replication**: MSK clusters replicate data bidirectionally (us-east-1 ↔ us-west-2)
6. **Flight/Aircraft Data Adapters** (EKS in KPaaS): Consume from MSK via Route53/NLB bootstrap
7. **Flightkeys Delivery**: Adapters invoke Flightkeys HTTPS API directly

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Primary event streaming backbone
  - **Replication**: Cross-region (us-east-1 ↔ us-west-2)
  - **Producers**: MQ-Kafka Adapter (on-prem)
  - **Consumers**: Flight Data Adapter, Aircraft Data Adapter (EKS)
  - **Bootstrap**: Route53 DNS (kafka.nxop.com) → NLB → MSK brokers
  - **Criticality**: HIGH - Event loss if MSK unavailable
  - **Failover**: Automatic cross-region replication, consumer group rebalancing
  
- **DocumentDB Global Cluster**:
  - **Role**: Reference data enrichment (aircraft configurations, fuel bias data)
  - **Regions**: Primary (us-east-1), Secondary (us-west-2)
  - **Access Pattern**: Read-heavy (adapters query reference data for enrichment)
  - **Criticality**: MEDIUM - Degraded functionality without reference data (events can be sent without enrichment)
  - **Failover**: Automatic failover to secondary region (< 1 minute)

**Key Components**:
- **MQ-Kafka Adapter**: On-premises component (not in AWS/KPaaS)
- **Flight Data Adapter**: EKS pods in KPaaS (both regions)
- **Aircraft Data Adapter**: EKS pods in KPaaS (both regions)
- **Route53/NLB**: MSK bootstrap infrastructure in NXOP account

---

### Flow 2: Receive and Publish Flight Plans and Events from Flightkeys

**Pattern**: Inbound Data Ingestion  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: Flight Plan Processor, MSK, Kafka Connector  
**Destinations**: On-Prem (Kafka → MQ adapter → FOS), FXIP Platform  
**Communication**: Asynchronous (AMQP → Kafka → MQ)  

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Central message bus for flight plan distribution
  - **Replication**: Cross-region (us-east-1 ↔ us-west-2)
  - **Producers**: Flight Plan Processor
  - **Consumers**: Kafka-to-MQ adapter, FXIP processors
  - **Criticality**: CRITICAL - Flight plan distribution stops if MSK unavailable
  - **Throughput**: High volume (1000+ messages/minute during peak)
  - **Failover**: Automatic cross-region replication, Route53 DNS failover
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 3: Update FOS with Flightkeys Events

**Pattern**: Inbound Data Ingestion  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: Flightkeys Event Processor, LCA Flight Update Proxy  
**Destinations**: FOS (On-Prem) via HTTPS → OpsHub On-Prem  
**Communication**: Asynchronous ingestion, Synchronous delivery (HTTPS)  

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP → HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 4: Update FOS with Flightplan Data

**Pattern**: Inbound Data Ingestion  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: Flightkeys FOS Update Processor, FTM Uplink Proxy  
**Destinations**: FOS (On-Prem) via HTTPS  
**Communication**: Asynchronous ingestion, Synchronous delivery (HTTPS)  

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP → HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 5: Receive and Publish Audit Log Events, Weather and FK OFP Data

**Pattern**: Inbound Data Ingestion  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: FXIP Audit Log Processor, MSK  
**Destinations**: OpsHub Event Hubs (Azure) → Databricks/Orion  
**Communication**: Asynchronous (AMQP → Kafka → Azure Event Hubs)  

**Architecture Flow**:
1. **Inbound**: Flightkeys sends audit logs, weather, and OFP data via AMQP
2. **FXIP Audit Log Processor** (EKS in KPaaS): Receives and processes messages
3. **MSK**: Processor produces events to MSK topics
4. **Kafka Connector** (Azure): Consumes from NXOP MSK and publishes to OpsHub Event Hubs
5. **OpsHub Event Hubs** (Azure): Receives events from Kafka Connector
6. **Databricks/Orion**: Consumes from OpsHub Event Hubs for analytics

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Event streaming for audit logs, weather, and OFP data
  - **Replication**: Cross-region (us-east-1 ↔ us-west-2)
  - **Producers**: FXIP Audit Log Processor
  - **Consumers**: Kafka Connector (Azure-based, consumes from MSK and publishes to OpsHub Event Hubs)
  - **Criticality**: HIGH - Audit trail and analytics data loss if unavailable
  - **Retention**: 7 days (compliance requirement)
  - **Failover**: Automatic cross-region replication
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

**Key Components**:
- **FXIP Audit Log Processor**: EKS pods in KPaaS (both regions)
- **MSK**: NXOP account (both regions with cross-region replication)
- **Kafka Connector**: Azure-based connector that bridges NXOP MSK to OpsHub Event Hubs
- **OpsHub Event Hubs**: Azure Event Hubs for event distribution to analytics platforms

---

### Flow 6: Send Summary Flight Plans to Dispatchers ScreenPrinter

**Pattern**: Inbound Data Ingestion  
**Source**: Flightkeys (AWS) via AMQP - Free Text Messages  
**NXOP Components**: Text Message Processor, OpsHub Host Print Proxy  
**Destinations**: FOS (On-Prem) via HTTPS → OpsHub On-Prem → Crew Management  
**Communication**: Asynchronous ingestion, Synchronous delivery (HTTPS)  

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP → HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 7: Send Flight Release Update Notifications to ACARS and CCI

**Pattern**: Notification/Alert  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: Notification Service (EKS), FTM Uplink Proxy (EKS), FlightInfo API (EKS)  
**Destinations**: 
- ACARS (via AIRCOM Server → Aircraft)
- CCI (Crew Check In) - Azure FXIP
- FOS (Flight Operations System) - On-Premises  
**Communication**: Asynchronous ingestion (AMQP), Synchronous delivery (HTTPS)  

**Architecture Flow**:
1. **Flightkeys** (AWS) publishes flight release update events via AMQP
2. **Notification Service** (EKS pod in KPaaS, us-east-1/us-west-2) consumes AMQP messages
3. **Notification Service** routes notifications to multiple destinations:
   - **Path A (ACARS)**: Notification Service → FTM Uplink Proxy (EKS) → AIRCOM Server (On-Prem) via HTTPS → Aircraft via ACARS
   - **Path B (CCI)**: Notification Service → FlightInfo API (EKS) → CCI (Azure FXIP) via HTTPS
   - **Path C (FOS)**: Notification Service → FlightInfo API (EKS) → FOS (On-Prem) via HTTPS
4. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound requests to FlightInfo API)
5. AMQP traffic goes directly to EKS pods (no Akamai)
6. Outbound HTTPS calls from EKS apps to external systems (AIRCOM, CCI, FOS) are direct (not through Akamai)

**Key Components**:
- **Notification Service**: EKS pod consuming AMQP, orchestrating multi-destination delivery
- **FTM Uplink Proxy**: EKS pod handling ACARS uplink via AIRCOM
- **FlightInfo API**: EKS pod exposing HTTPS API for CCI/FOS integration
- **Akamai GTM**: Global traffic manager fronting all HTTPS APIs
- **AIRCOM Server**: On-premises gateway to aircraft ACARS systems
- **CCI**: Azure FXIP component for crew check-in
- **FOS**: On-premises flight operations system

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP → HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 8: Retrieve Pilot Briefing Package

**Pattern**: Document Assembly  
**Source**: Flightkeys (AWS) via HTTPS  
**NXOP Components**: Flightkeys Integration Service (EKS), Flight Plan Service (EKS), Pilot Document Service (EKS), DocumentDB, S3  
**Destinations**: 
- FOS Business Resumption (On-Prem)
- CCI (Crew Check In) - Azure FXIP  
**Communication**: Synchronous (HTTPS request/response)  

**Architecture Flow**:
1. **Flightkeys** (AWS) sends HTTPS request for pilot briefing package
2. **Flightkeys Integration Service** (EKS pod in KPaaS, us-east-1/us-west-2) receives request via Akamai GTM (inbound to EKS API endpoint)
3. **Flightkeys Integration Service** orchestrates document assembly by calling:
   - **Flight Plan Service** (EKS) to retrieve flight plan data from DocumentDB
   - **Pilot Document Service** (EKS) to retrieve pilot-specific documents
4. **Flight Plan Service** and **Pilot Document Service** query:
   - **DocumentDB Global Cluster** for metadata (flight details, document references)
   - **S3** for document storage (PDFs, charts, weather data)
5. **Flightkeys Integration Service** assembles complete briefing package
6. Assembled package delivered to:
   - **FOS Business Resumption** (On-Prem) via direct HTTPS call
   - **CCI** (Azure FXIP) via direct HTTPS call
7. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound requests)
8. Outbound HTTPS calls from EKS apps to external systems (FOS, CCI) are direct (not through Akamai)

**Key Components**:
- **Flightkeys Integration Service**: EKS pod orchestrating briefing package assembly
- **Flight Plan Service**: EKS pod managing flight plan data and metadata
- **Pilot Document Service**: EKS pod (AWS) managing pilot-specific documents
- **DocumentDB Global Cluster**: Metadata storage (flight details, document references)
- **S3**: Document storage (PDFs, charts, weather data)
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps
- **FOS Business Resumption**: On-premises backup system
- **CCI**: Azure FXIP component for crew check-in

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (synchronous HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Briefing package metadata storage and retrieval
  - **Regions**: Primary (us-east-1), Secondary (us-west-2)
  - **Access Pattern**: Read-heavy with occasional writes (package assembly metadata)
  - **Criticality**: CRITICAL - Cannot assemble briefing packages without metadata
  - **Query Pattern**: Complex joins across multiple collections
  - **Failover**: Automatic failover to secondary region (< 1 minute)
  - **Performance**: Indexed queries on flight_number, departure_time, tail_number

---

### Flow 9: Pilot eSignature for Flight Release - CCI

**Pattern**: Authorization  
**Source**: Flightkeys (AWS) - Events (AMQP) + eSignature (HTTPS)  
**NXOP Components**: Flightkeys Event Processor (EKS), Flightkeys Integration Service (EKS), LCA Flight Update Proxy (EKS)  
**Destinations**: 
- FOS (On-Prem) via HTTPS → OpsHub On-Prem → Crew Management
- CCI (Crew Check In) - Azure FXIP  
**Communication**: Hybrid (AMQP events + HTTPS signatures)  

**Architecture Flow**:
1. **Flightkeys** (AWS) publishes flight release events via AMQP
2. **Flightkeys Event Processor** (EKS pod in KPaaS, us-east-1/us-west-2) consumes AMQP events
3. **Flightkeys Event Processor** detects flight release requiring pilot eSignature
4. **Flightkeys Integration Service** (EKS) receives eSignature capture request via HTTPS through Akamai GTM (inbound to EKS API endpoint)
5. Pilot provides eSignature via:
   - **CCI** (Azure FXIP) mobile/web interface
   - **FOS** (On-Prem) interface
6. **Flightkeys Integration Service** validates and processes eSignature
7. **LCA Flight Update Proxy** (EKS) forwards signed flight release to:
   - **FOS** (On-Prem) via direct HTTPS call
   - **OpsHub On-Prem** via direct HTTPS call for crew management system updates
   - **CCI** (Azure FXIP) via direct HTTPS call for crew check-in confirmation
8. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound requests)
9. AMQP traffic goes directly to EKS pods (no Akamai)
10. Outbound HTTPS calls from EKS apps to external systems (FOS, OpsHub, CCI) are direct (not through Akamai)

**Key Components**:
- **Flightkeys Event Processor**: EKS pod consuming AMQP events for flight releases
- **Flightkeys Integration Service**: EKS pod handling eSignature capture and validation
- **LCA Flight Update Proxy**: EKS pod forwarding signed releases to downstream systems
- **Akamai GTM**: Global traffic manager fronting all HTTPS APIs
- **CCI**: Azure FXIP component for crew check-in and eSignature capture
- **FOS**: On-premises flight operations system
- **OpsHub On-Prem**: On-premises crew management integration hub

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP → HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 10: Pilot eSignature for Flight Release - ACARS

**Pattern**: Authorization  
**Source**: Flightkeys (AWS) - Events (AMQP) + ACARS eSignature (HTTPS)  
**NXOP Components**: 
- **AWS NXOP**: Flightkeys Event Processor (EKS), Flight Data Adapter (EKS), LCA Flight Update Proxy (EKS), DocumentDB, MSK
- **FXIP (Azure)**: Flightkeys Event Processor, Flight Data Adapter, ConsulDB, OpsHub LCA Flight Update Proxy
- **OpsHub Azure**: OpsHub Event Hubs  
**Destinations**: 
- FOS (On-Prem) via MQ-Kafka adapter
- AIRCOM Server (On-Prem) → Aircraft via ACARS
- OpsHub On-Prem  
**Communication**: Hybrid (AMQP events + HTTPS signatures), Asynchronous (Kafka/MQ)  

**Architecture Flow**:
1. **Flightkeys** (AWS) publishes flight release events via AMQP to both:
   - **AWS NXOP Platform**: Flightkeys Event Processor (EKS)
   - **FXIP (Azure)**: Flightkeys Event Processor
2. **AWS Path**:
   - **Flightkeys Event Processor** (EKS pod in KPaaS, us-east-1/us-west-2) consumes AMQP events
   - Detects flight release requiring pilot eSignature via ACARS
   - Queries **DocumentDB** for reference data (crew credentials, flight authorization)
   - **Flight Data Adapter** (EKS) receives ACARS eSignature request via HTTPS through Akamai GTM (inbound)
   - Publishes flight events to **MSK** (Kafka)
   - **LCA Flight Update Proxy** (EKS) forwards FOS updates via HTTPS to FOS (On-Prem)
3. **FXIP (Azure) Path**:
   - **Flightkeys Event Processor** (Azure) consumes AMQP events
   - Queries **ConsulDB** for reference data
   - **Flight Data Adapter** (Azure) receives ACARS eSignature request via HTTPS
   - Publishes flight events to **OpsHub Event Hubs** (Azure)
   - **OpsHub LCA Flight Update Proxy** (Azure) forwards FOS updates via HTTPS
4. **MSK to On-Prem**:
   - **MQ-Kafka adapter** (On-Prem) consumes flight events from **MSK** (AWS NXOP)
   - Forwards to **FOS** components (DECS, Load Planning, Takeoff Performance, Crew Management)
5. **OpsHub Event Hubs to On-Prem**:
   - **OpsHub On-Prem** consumes flight events from **OpsHub Event Hubs** (Azure)
   - Forwards to **FOS** via TCP
6. **ACARS Delivery**:
   - **AIRCOM Server** (On-Prem) receives ACARS messages (MQ)
   - Transmits eSignature confirmation to aircraft via ACARS
7. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
8. AMQP traffic goes directly to EKS pods (no Akamai)
9. Outbound HTTPS calls from EKS apps to external systems are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Flightkeys Event Processor**: EKS pod consuming AMQP events for flight releases
  - **Flight Data Adapter**: EKS pod handling ACARS eSignature requests
  - **LCA Flight Update Proxy**: EKS pod forwarding FOS updates
  - **DocumentDB**: Reference data storage (crew credentials, flight authorization)
  - **MSK**: Event streaming for signature events and flight updates
- **FXIP (Azure)**:
  - **Flightkeys Event Processor**: Azure component consuming AMQP events
  - **Flight Data Adapter**: Azure component handling ACARS eSignature requests
  - **ConsulDB**: Reference data storage
  - **OpsHub LCA Flight Update Proxy**: Azure component forwarding FOS updates
- **OpsHub Azure**:
  - **OpsHub Event Hubs**: Azure event streaming service
- **On-Premises**:
  - **MQ-Kafka adapter**: Bridges MSK to FOS MQ
  - **FOS**: Flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)
  - **OpsHub On-Prem**: Integration hub consuming from OpsHub Event Hubs
  - **AIRCOM Server**: Gateway to aircraft ACARS systems
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Event streaming for signature events and flight updates
  - **Replication**: Cross-region (us-east-1 ↔ us-west-2)
  - **Producers**: Flightkeys Event Processor, Flight Data Adapter
  - **Consumers**: MQ-Kafka adapter (On-Prem)
  - **Criticality**: HIGH - Signature events must be reliably delivered
  - **Failover**: Automatic cross-region replication
  
- **DocumentDB Global Cluster**:
  - **Role**: Reference data for signature validation (crew credentials, flight authorization)
  - **Regions**: Primary (us-east-1), Secondary (us-west-2)
  - **Access Pattern**: Read for validation, Write for audit trail
  - **Criticality**: HIGH - Cannot validate signatures without reference data
  - **Failover**: Automatic failover to secondary region (< 1 minute)


---

### Flow 11: Publish Flight Event Data to Cyberjet

**Pattern**: Outbound Data Publishing  
**Source**: FXIP On-Prem Integration  
**NXOP Components**: None - NXOP has no role in this flow  
**Destinations**: 
- CyberJet FMS (AWS)
- FOS (On-Prem) via MQ  
**Communication**: Asynchronous (AMQP → MQ)  

**Architecture Flow**:
1. **FXIP ACARS Adapter** (On-Prem) receives flight events via MQ
2. **FXIP ACARS Adapter** publishes flight events via AMQP to:
   - **CyberJet FMS** (AWS) - direct AMQP connection
   - **FOS** (On-Prem) - via MQ (DECS, Load Planning, Takeoff Performance, Crew Management)
3. **OpsHub On-Prem** also receives flight events via MQ and forwards to FOS
4. **NXOP Platform** (AWS) is not involved in this flow
5. **FXIP** (Azure) and **OpsHub Azure** are not involved in this flow

**Key Components**:
- **FXIP ACARS Adapter**: On-premises component handling flight event publishing
- **CyberJet FMS**: AWS-based Flight Management System
- **FOS**: On-premises flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)
- **OpsHub On-Prem**: On-premises integration hub

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A

**Note**: This flow is entirely on-premises (FXIP) to AWS (CyberJet) and on-premises (FOS). NXOP Platform does not participate in this integration.

---

### Flow 12: Publish Flight Plans, Weather to Cyberjet

**Pattern**: Inbound Data Ingestion  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: None - NXOP has no role in this flow  
**Destinations**: CyberJet FMS (AWS), FOS (On-Prem)  
**Communication**: Asynchronous (AMQP)  

**Architecture Flow**:
1. **Flightkeys** (AWS) publishes flight plans and weather data via AMQP
2. **CyberJet FMS** (AWS) consumes flight plans and weather data directly via AMQP
3. **FOS** (On-Prem) may also receive this data through separate channels
4. **NXOP Platform** (AWS) is not involved in this flow
5. **FXIP** (Azure) and **OpsHub Azure** are not involved in this flow

**Key Components**:
- **Flightkeys**: AWS-based flight operations platform publishing flight plans and weather
- **CyberJet FMS**: AWS-based Flight Management System consuming flight data
- **FOS**: On-premises flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A

**Note**: This flow is a direct integration between Flightkeys (AWS) and CyberJet FMS (AWS). NXOP Platform does not participate in this integration.

---

### Flow 13: Aircraft FMS Initialization and Enroute ACARS Requests

**Pattern**: Bidirectional Sync  
**Source**: CyberJet FMS (AWS) & Flightkeys (AWS) - Flight Progress Reports  
**NXOP Components**: None - NXOP has no role in this flow  
**Destinations**: FOS (On-Prem) via MQ, AIRCOM Server → Aircraft  
**Communication**: Hybrid (AMQP + HTTPS), Bidirectional ACARS  

**Architecture Flow**:
1. **CyberJet FMS** (AWS) sends flight progress reports via HTTPS to **Flightkeys** (AWS)
2. **Flightkeys** (AWS) publishes flight progress reports via AMQP
3. **FXIP ACARS Adapter** (On-Prem) receives flight progress reports via AMQP
4. **FXIP ACARS Adapter** handles bidirectional ACARS communication:
   - **Downlinks**: Receives ACARS messages from aircraft via **AIRCOM Server** (On-Prem)
   - **Uplinks**: Sends ACARS messages to aircraft via **AIRCOM Server** (On-Prem)
5. **FXIP ACARS Adapter** forwards flight progress reports to **FOS** (On-Prem) via MQ
6. **OpsHub On-Prem** also receives FOS events via MQ
7. **NXOP Platform** (AWS) is not involved in this flow
8. **FXIP** (Azure) and **OpsHub Azure** are not involved in this flow

**Key Components**:
- **CyberJet FMS**: AWS-based Flight Management System sending flight progress reports
- **Flightkeys**: AWS-based flight operations platform publishing flight progress reports
- **FXIP ACARS Adapter**: On-premises component handling ACARS communication
- **AIRCOM Server**: On-premises gateway to aircraft ACARS systems
- **FOS**: On-premises flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)
- **OpsHub On-Prem**: On-premises integration hub

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A

**Note**: This flow involves CyberJet FMS (AWS), Flightkeys (AWS), and FXIP On-Prem components. NXOP Platform does not participate in this integration.

---

### Flow 14: Flightkeys ACARS Free Text Messaging

**Pattern**: Notification/Alert  
**Source**: Flightkeys (AWS) via AMQP  
**NXOP Components**: 
- **AWS NXOP**: Text Message Processor (EKS), FTM Uplink Proxy (EKS)
- **FXIP (Azure)**: Text Message Processor, FTM Uplink Proxy
- **OpsHub Azure**: OpsHub Event Hubs (not shown in diagram but part of architecture)  
**Destinations**: 
- FOS (On-Prem) via HTTPS/TCP
- AIRCOM Server (On-Prem) → Aircraft via ACARS  
**Communication**: Asynchronous ingestion (AMQP), Synchronous delivery (HTTPS), ACARS  

**Architecture Flow**:
1. **Flightkeys** (AWS) publishes free text messages via AMQP to both:
   - **AWS NXOP Platform**: Text Message Processor (EKS)
   - **FXIP (Azure)**: Text Message Processor
2. **AWS NXOP Path**:
   - **Text Message Processor** (EKS pod in KPaaS, us-east-1/us-west-2) consumes AMQP messages
   - Formats free text messages for ACARS delivery
   - **FTM Uplink Proxy** (EKS) receives formatted messages via HTTPS through Akamai GTM (inbound)
   - Sends ACARS messages to **FOS** (On-Prem) via direct HTTPS call
3. **FXIP (Azure) Path**:
   - **Text Message Processor** (Azure) consumes AMQP messages
   - Formats free text messages for ACARS delivery
   - **FTM Uplink Proxy** (Azure) receives formatted messages via HTTPS
   - Sends ACARS messages to **OpsHub On-Prem** via HTTPS
4. **ACARS Delivery**:
   - **OpsHub On-Prem** forwards ACARS messages via MQ
   - **AIRCOM Server** (On-Prem) receives ACARS messages
   - Transmits messages to aircraft via ACARS
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
6. AMQP traffic goes directly to EKS pods (no Akamai)
7. Outbound HTTPS calls from EKS apps to external systems are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Text Message Processor**: EKS pod consuming AMQP and formatting free text messages
  - **FTM Uplink Proxy**: EKS pod handling ACARS uplink delivery
- **FXIP (Azure)**:
  - **Text Message Processor**: Azure component consuming AMQP and formatting messages
  - **FTM Uplink Proxy**: Azure component handling ACARS uplink delivery
- **On-Premises**:
  - **FOS**: Flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)
  - **OpsHub On-Prem**: Integration hub forwarding ACARS messages
  - **AIRCOM Server**: Gateway to aircraft ACARS systems
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP → HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 15: Flight Progress Reports Initiated by Dispatchers

**Pattern**: Bidirectional Sync  
**Source**: Dispatchers → CyberJet FMS (AWS) & Flightkeys (AWS)  
**NXOP Components**: None - NXOP has no role in this flow  
**Destinations**: FOS (On-Prem) via MQ, AIRCOM Server → Aircraft  
**Communication**: Hybrid (AMQP + HTTPS), Bidirectional ACARS  

**Architecture Flow**:
1. **Dispatchers** initiate flight progress reports (connectivity flight plans)
2. **CyberJet FMS** (AWS) sends flight progress reports via HTTPS to **Flightkeys** (AWS)
3. **Flightkeys** (AWS) publishes flight progress reports via AMQP
4. **FXIP ACARS Adapter** (On-Prem) receives flight progress reports via AMQP
5. **FXIP ACARS Adapter** handles bidirectional ACARS communication:
   - **Downlinks**: Receives ACARS messages from aircraft via **AIRCOM Server** (On-Prem)
   - **Uplinks**: Sends ACARS messages to aircraft via **AIRCOM Server** (On-Prem)
6. **FXIP ACARS Adapter** forwards flight progress reports to **FOS** (On-Prem) via MQ
7. **OpsHub On-Prem** also receives FOS events via MQ
8. **NXOP Platform** (AWS) is not involved in this flow
9. **FXIP** (Azure) and **OpsHub Azure** are not involved in this flow

**Key Components**:
- **CyberJet FMS**: AWS-based Flight Management System sending flight progress reports
- **Flightkeys**: AWS-based flight operations platform publishing flight progress reports
- **FXIP ACARS Adapter**: On-premises component handling ACARS communication
- **AIRCOM Server**: On-premises gateway to aircraft ACARS systems
- **FOS**: On-premises flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)
- **OpsHub On-Prem**: On-premises integration hub

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A

**Note**: This flow is initiated by dispatchers and involves CyberJet FMS (AWS), Flightkeys (AWS), and FXIP On-Prem components. NXOP Platform does not participate in this integration.

---

### Flow 16: Ops Engineering Fleet / Reference Data Maintenance

**Pattern**: Bidirectional Sync  
**Source**: Flightkeys (AWS) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Aircraft Data Service (EKS)
- **FXIP (Azure)**: Nav Data Service  
**Destinations**: Ops Engineering Client Apps (On-Prem) via HTTPS  
**Communication**: Synchronous (HTTPS bidirectional)  

**Architecture Flow**:
1. **Flightkeys** (AWS) sends aircraft data and fleet information via HTTPS
2. **AWS NXOP Path**:
   - **Aircraft Data Service** (EKS pod in KPaaS, us-east-1/us-west-2) receives aircraft data via Akamai GTM (inbound)
   - Maintains fleet and reference data
   - **Ops Engineering Client Apps** (On-Prem) query aircraft data via HTTPS through Akamai GTM (inbound to EKS)
   - **Aircraft Data Service** sends updates to Ops Engineering Client Apps via direct HTTPS (outbound)
3. **FXIP (Azure) Path**:
   - **Nav Data Service** (Azure) receives aircraft data via HTTPS
   - Maintains fleet and reference data
   - **Ops Engineering Client Apps** (On-Prem) query nav data via HTTPS
   - **Nav Data Service** sends updates to Ops Engineering Client Apps via HTTPS
4. **OpsHub On-Prem** may also be involved in data synchronization
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
6. Outbound HTTPS calls from EKS apps to Ops Engineering Client Apps are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Aircraft Data Service**: EKS pod managing fleet and reference data
- **FXIP (Azure)**:
  - **Nav Data Service**: Azure component managing navigation and fleet data
- **On-Premises**:
  - **Ops Engineering Client Apps**: On-premises applications for fleet/reference data maintenance
  - **OpsHub On-Prem**: Integration hub for data synchronization
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (synchronous HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow (Aircraft Data Service uses separate data store)
  - **Criticality**: N/A

---

### Flow 17: Performance Based Contingency Fuel / Statistical Fuel Updates

**Pattern**: Bidirectional Sync  
**Source**: Flightkeys (AWS) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Nav Data Service (EKS)
- **FXIP (Azure)**: Nav Data Service  
**Destinations**: Ops Engineering Client Apps (On-Prem) via HTTPS  
**Communication**: Synchronous (HTTPS bidirectional)  

**Architecture Flow**:
1. **Flightkeys** (AWS) sends min fuel and statistical fuel data via HTTPS
2. **AWS NXOP Path**:
   - **Nav Data Service** (EKS pod in KPaaS, us-east-1/us-west-2) receives min fuel data via Akamai GTM (inbound)
   - Maintains performance-based contingency fuel and statistical fuel data
   - **Ops Engineering Client Apps** (On-Prem) query fuel data via HTTPS through Akamai GTM (inbound to EKS)
   - **Nav Data Service** sends updates to Ops Engineering Client Apps via direct HTTPS (outbound)
3. **FXIP (Azure) Path**:
   - **Nav Data Service** (Azure) receives min fuel data via HTTPS
   - Maintains performance-based contingency fuel and statistical fuel data
   - **Ops Engineering Client Apps** (On-Prem) query fuel data via HTTPS
   - **Nav Data Service** sends updates to Ops Engineering Client Apps via HTTPS
4. **OpsHub On-Prem** may also be involved in data synchronization
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
6. Outbound HTTPS calls from EKS apps to Ops Engineering Client Apps are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Nav Data Service**: EKS pod managing performance-based contingency fuel and statistical fuel data
- **FXIP (Azure)**:
  - **Nav Data Service**: Azure component managing fuel data
- **On-Premises**:
  - **Ops Engineering Client Apps**: On-premises applications for fuel data maintenance
  - **OpsHub On-Prem**: Integration hub for data synchronization
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (synchronous HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow (Nav Data Service uses separate data store)
  - **Criticality**: N/A

---

### Flow 18: Position Reports to Flightkeys

**Pattern**: Outbound Data Publishing  
**Source**: FOS (On-Prem) via MQ  
**NXOP Components**: 
- **AWS NXOP**: Aircraft Data Adapter (EKS), DocumentDB, MSK
- **FXIP (Azure)**: Aircraft Data Adapter, ConsulDB, OpsHub Event Hubs  
**Destinations**: Flightkeys (AWS) via HTTPS  
**Communication**: Asynchronous (MQ → Kafka), Synchronous delivery (HTTPS)  

**Architecture Flow**:
1. **FOS** (On-Prem) publishes position reports via MQ
2. **AWS NXOP Path**:
   - **MQ-Kafka adapter** (On-Prem) consumes position reports from FOS MQ
   - Publishes to **MSK** (Kafka)
   - **Aircraft Data Adapter** (EKS pod in KPaaS, us-east-1/us-west-2) consumes from MSK
   - Queries **DocumentDB** for reference data enrichment (aircraft details, route info)
   - Sends enriched position reports to **Flightkeys** (AWS) via direct HTTPS call
3. **FXIP (Azure) Path**:
   - **Aircraft Data Adapter** (Azure) consumes position reports
   - Queries **ConsulDB** for reference data enrichment
   - Publishes to **OpsHub Event Hubs** (Azure)
   - **OpsHub On-Prem** consumes from OpsHub Event Hubs
   - Forwards position reports to FOS and other systems
4. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
5. Outbound HTTPS calls from EKS apps to Flightkeys are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Aircraft Data Adapter**: EKS pod consuming position reports from MSK and enriching with reference data
  - **MSK**: Event streaming for position reports
  - **DocumentDB**: Reference data storage (aircraft details, route info)
- **FXIP (Azure)**:
  - **Aircraft Data Adapter**: Azure component consuming and enriching position reports
  - **ConsulDB**: Reference data storage
  - **OpsHub Event Hubs**: Azure event streaming service
- **On-Premises**:
  - **FOS**: Flight operations system publishing position reports
  - **MQ-Kafka adapter**: Bridges FOS MQ to MSK
  - **OpsHub On-Prem**: Integration hub consuming from OpsHub Event Hubs
- **Flightkeys**: AWS-based flight operations platform receiving position reports

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Event streaming for position reports
  - **Replication**: Cross-region (us-east-1 ↔ us-west-2)
  - **Producers**: MQ-Kafka adapter (On-Prem)
  - **Consumers**: Aircraft Data Adapter (EKS)
  - **Criticality**: HIGH - Real-time flight tracking depends on position reports
  - **Throughput**: Medium volume (100-500 messages/minute)
  - **Failover**: Automatic cross-region replication
  
- **DocumentDB Global Cluster**:
  - **Role**: Reference data enrichment for position reports (aircraft details, route info)
  - **Regions**: Primary (us-east-1), Secondary (us-west-2)
  - **Access Pattern**: Read-heavy (adapter queries reference data for enrichment)
  - **Criticality**: MEDIUM - Position reports can be sent without enrichment
  - **Failover**: Automatic failover to secondary region (< 1 minute)

---

### Flow 19: Publish Flight Events to FXIP Fusion

**Pattern**: Inbound Data Ingestion  
**Source**: IBM Fusion Flight Tracking (AWS) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Fusion Flight Movement Adapter (EKS), DocumentDB, MSK
- **FXIP (Azure)**: Flight Movement Adapter, ConsulDB, OpsHub Event Hubs  
**Destinations**: FOS (On-Prem) via MQ, AIRCOM Server → Aircraft  
**Communication**: Synchronous ingestion (HTTPS), Asynchronous distribution (Kafka/MQ)  

**Architecture Flow**:
1. **IBM Fusion Flight Tracking** (AWS) sends flight movement events via HTTPS
2. **AWS NXOP Path**:
   - **Fusion Flight Movement Adapter** (EKS pod in KPaaS, us-east-1/us-west-2) receives flight movement events via Akamai GTM (inbound)
   - Queries **DocumentDB** for reference data validation and enrichment
   - Publishes flight movement events to **MSK** (Kafka)
   - **MQ-Kafka adapter** (On-Prem) consumes from MSK
   - Forwards to **FOS** (On-Prem) via MQ
3. **FXIP (Azure) Path**:
   - **Flight Movement Adapter** (Azure) receives flight movement events via HTTPS
   - Queries **ConsulDB** for reference data validation and enrichment
   - Publishes to **OpsHub Event Hubs** (Azure)
   - **OpsHub On-Prem** consumes from OpsHub Event Hubs
   - Forwards to **FOS** and **AIRCOM Server** (On-Prem)
4. **AIRCOM Server** (On-Prem) may transmit flight updates to aircraft via ACARS
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
6. Outbound HTTPS calls from EKS apps are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Fusion Flight Movement Adapter**: EKS pod receiving flight movement events from IBM Fusion
  - **MSK**: Event streaming for flight movement events
  - **DocumentDB**: Reference data storage for validation and enrichment
- **FXIP (Azure)**:
  - **Flight Movement Adapter**: Azure component receiving and enriching flight movement events
  - **ConsulDB**: Reference data storage
  - **OpsHub Event Hubs**: Azure event streaming service
- **On-Premises**:
  - **MQ-Kafka adapter**: Bridges MSK to FOS MQ
  - **FOS**: Flight operations system receiving flight movement events
  - **OpsHub On-Prem**: Integration hub consuming from OpsHub Event Hubs
  - **AIRCOM Server**: Gateway to aircraft ACARS systems
- **IBM Fusion Flight Tracking**: AWS-based flight tracking system
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Event streaming for flight movement events
  - **Replication**: Cross-region (us-east-1 ↔ us-west-2)
  - **Producers**: Fusion Flight Movement Adapter (EKS)
  - **Consumers**: MQ-Kafka adapter (On-Prem)
  - **Criticality**: HIGH - Enterprise flight tracking distribution
  - **Throughput**: Medium volume (200-800 messages/minute)
  - **Failover**: Automatic cross-region replication
  
- **DocumentDB Global Cluster**:
  - **Role**: Reference data for flight movement validation and enrichment
  - **Regions**: Primary (us-east-1), Secondary (us-west-2)
  - **Access Pattern**: Read-heavy with occasional writes (movement history)
  - **Criticality**: MEDIUM - Events can be processed without full enrichment
  - **Failover**: Automatic failover to secondary region (< 1 minute)

---

### Flow 20: Publish Flight Plan Data to FXIP Fusion

**Pattern**: Bidirectional Sync  
**Source**: Flightkeys (AWS) via AMQP + IBM Fusion Flight Tracking (AWS) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Fusion Integration Adapter (EKS)
- **FXIP (Azure)**: Fusion Integration Adapter  
**Destinations**: IBM Fusion Flight Tracking (AWS), FOS (On-Prem)  
**Communication**: Hybrid (AMQP + HTTPS bidirectional)  

**Architecture Flow**:
1. **Flightkeys** (AWS) publishes flight plans via AMQP to:
   - **AWS NXOP Platform**: Fusion Integration Adapter (EKS)
   - **FXIP (Azure)**: Fusion Integration Adapter
2. **AWS NXOP Path**:
   - **Fusion Integration Adapter** (EKS pod in KPaaS, us-east-1/us-west-2) consumes flight plans via AMQP
   - Sends flight plan data to **IBM Fusion Flight Tracking** (AWS) via direct HTTPS call
   - **IBM Fusion** sends flight plan data back via HTTPS through Akamai GTM (inbound to EKS)
3. **FXIP (Azure) Path**:
   - **Fusion Integration Adapter** (Azure) consumes flight plans via AMQP
   - Sends flight plan data to **IBM Fusion Flight Tracking** (AWS) via HTTPS
   - **IBM Fusion** sends flight plan data back via HTTPS
4. **OpsHub On-Prem** may receive flight plan updates for FOS distribution
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
6. AMQP traffic goes directly to EKS pods (no Akamai)
7. Outbound HTTPS calls from EKS apps to IBM Fusion are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Fusion Integration Adapter**: EKS pod handling bidirectional flight plan sync with IBM Fusion
- **FXIP (Azure)**:
  - **Fusion Integration Adapter**: Azure component handling bidirectional flight plan sync
- **Flightkeys**: AWS-based flight operations platform publishing flight plans
- **IBM Fusion Flight Tracking**: AWS-based flight tracking system
- **On-Premises**:
  - **FOS**: Flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management)
  - **OpsHub On-Prem**: Integration hub for data distribution
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct AMQP and HTTPS processing)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 21: Publish Position Reports to FXIP Fusion

**Pattern**: Inbound Data Ingestion  
**Source**: IBM Fusion Flight Tracking (AWS) via HTTPS  
**NXOP Components**: None - NXOP has no role in this flow  
**Destinations**: FOS (On-Prem), AIRCOM Server → Aircraft  
**Communication**: Synchronous (HTTPS), ACARS  

**Architecture Flow**:
1. **IBM Fusion Flight Tracking** (AWS) sends position reports via HTTPS
2. **FXIP (Azure) Path**:
   - **OpsHub Event Hubs** (Azure) receives position reports via HTTPS
   - **OpsHub On-Prem** consumes position reports from OpsHub Event Hubs
   - Forwards to **FOS** (On-Prem) via MQ
   - Forwards to **AIRCOM Server** (On-Prem) for aircraft delivery via ACARS
3. **NXOP Platform** (AWS) is not involved in this flow
4. **FXIP** (Azure) components handle the integration

**Key Components**:
- **FXIP (Azure)**:
  - **OpsHub Event Hubs**: Azure event streaming service receiving position reports
- **On-Premises**:
  - **OpsHub On-Prem**: Integration hub consuming from OpsHub Event Hubs
  - **FOS**: Flight operations system receiving position reports
  - **AIRCOM Server**: Gateway to aircraft ACARS systems
- **IBM Fusion Flight Tracking**: AWS-based flight tracking system

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A

**Note**: This flow is entirely handled by FXIP (Azure) and on-premises components. NXOP Platform does not participate in this integration.

---

### Flow 22: FXIP Fusion ACARS Free Text Messaging

**Pattern**: Notification/Alert  
**Source**: IBM Fusion Flight Tracking (AWS) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Fusion ACARS Service (EKS), FTM Uplink Proxy (EKS)
- **FXIP (Azure)**: Free Text Service, FTM Uplink Proxy  
**Destinations**: FOS (On-Prem) via HTTPS, AIRCOM Server → Aircraft  
**Communication**: Synchronous (HTTPS), ACARS  

**Architecture Flow**:
1. **IBM Fusion Flight Tracking** (AWS) sends free text messages via HTTPS
2. **AWS NXOP Path**:
   - **Fusion ACARS Service** (EKS pod in KPaaS, us-east-1/us-west-2) receives free text messages via Akamai GTM (inbound)
   - Formats messages for ACARS delivery
   - **FTM Uplink Proxy** (EKS) receives formatted messages
   - Sends ACARS messages to **FOS** (On-Prem) via direct HTTPS call
3. **FXIP (Azure) Path**:
   - **Free Text Service** (Azure) receives free text messages via HTTPS
   - Formats messages for ACARS delivery
   - **FTM Uplink Proxy** (Azure) receives formatted messages
   - Sends ACARS messages to **OpsHub On-Prem** via HTTPS
4. **ACARS Delivery**:
   - **OpsHub On-Prem** forwards ACARS messages via MQ
   - **AIRCOM Server** (On-Prem) receives ACARS messages
   - Transmits messages to aircraft via ACARS
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests)
6. Outbound HTTPS calls from EKS apps to FOS are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Fusion ACARS Service**: EKS pod receiving and formatting free text messages from IBM Fusion
  - **FTM Uplink Proxy**: EKS pod handling ACARS uplink delivery
- **FXIP (Azure)**:
  - **Free Text Service**: Azure component receiving and formatting free text messages
  - **FTM Uplink Proxy**: Azure component handling ACARS uplink delivery
- **On-Premises**:
  - **FOS**: Flight operations system receiving ACARS messages
  - **OpsHub On-Prem**: Integration hub forwarding ACARS messages
  - **AIRCOM Server**: Gateway to aircraft ACARS systems
- **IBM Fusion Flight Tracking**: AWS-based flight tracking system
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (direct HTTPS → ACARS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow
  - **Criticality**: N/A

---

### Flow 23: Manage Special Information Messages (F4/J8/J2)

**Pattern**: Outbound Data Publishing  
**Source**: Special Info Messages (On-Prem) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Data Maintenance Service (EKS)
- **FXIP (Azure)**: Data Maintenance Service (existing path - to be discontinued)  
**Destinations**: Flightkeys (AWS) via HTTPS  
**Communication**: Synchronous (HTTPS)  

**Architecture Flow**:
1. **Special Info Messages** (On-Prem) sends company special information messages (F4/J8/J2) via HTTPS
2. **AWS NXOP Path** (new):
   - **Data Maintenance Service** (EKS pod in KPaaS, us-east-1/us-west-2) receives special info messages via Akamai GTM (inbound)
   - Processes and validates special information message data
   - **Data Maintenance Service** sends messages to Flightkeys via direct HTTPS (outbound)
3. **FXIP (Azure) Path** (existing - to be discontinued):
   - **Data Maintenance Service** (Azure) receives special info messages via HTTPS
   - Processes special information message data
   - **Data Maintenance Service** sends messages to Flightkeys via HTTPS
4. **OpsHub On-Prem** may also be involved in data routing
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests from On-Prem)
6. Outbound HTTPS calls from EKS apps to Flightkeys are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Data Maintenance Service**: EKS pod managing special information messages (F4/J8/J2)
- **FXIP (Azure)**:
  - **Data Maintenance Service**: Azure component managing special information messages (existing path)
- **On-Premises**:
  - **Special Info Messages**: On-premises system publishing special information messages
  - **OpsHub On-Prem**: Integration hub for data routing
- **Flightkeys**: AWS-based flight operations platform receiving special info messages
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (synchronous HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow (Data Maintenance Service uses separate data store)
  - **Criticality**: N/A

---

### Flow 24: Delete Terminal Area Forecasts from Flightkeys

**Pattern**: Outbound Data Publishing  
**Source**: IOC Meteorologists (On-Prem) via HTTPS  
**NXOP Components**: 
- **AWS NXOP**: Terminal Area Forecast UI (EKS)
- **FXIP (Azure)**: Terminal Area Forecast UI (existing path - to be discontinued)  
**Destinations**: Flightkeys (AWS) via HTTPS  
**Communication**: Synchronous (HTTPS)  

**Architecture Flow**:
1. **IOC Meteorologists** (On-Prem) send TAF (Terminal Area Forecast) deletions via HTTPS
2. **AWS NXOP Path** (new):
   - **Terminal Area Forecast UI** (EKS pod in KPaaS, us-east-1/us-west-2) receives TAF deletions via Akamai GTM (inbound)
   - Processes TAF deletion records
   - **Terminal Area Forecast UI** sends TAF deletions to Flightkeys via direct HTTPS (outbound)
3. **FXIP (Azure) Path** (existing - to be discontinued):
   - **Terminal Area Forecast UI** (Azure) receives TAF deletions via HTTPS
   - Processes TAF deletion records
   - **Terminal Area Forecast UI** sends TAF deletions to Flightkeys via HTTPS
4. **OpsHub On-Prem** may also be involved in TAF data routing
5. **Akamai GTM** fronts the API endpoints exposed by EKS apps (for inbound HTTPS requests from On-Prem)
6. Outbound HTTPS calls from EKS apps to Flightkeys are direct (not through Akamai)

**Key Components**:
- **AWS NXOP Platform**:
  - **Terminal Area Forecast UI**: EKS pod managing TAF deletions for meteorologists
- **FXIP (Azure)**:
  - **Terminal Area Forecast UI**: Azure component managing TAF deletions (existing path)
- **On-Premises**:
  - **IOC Meteorologists**: On-premises users publishing TAF deletions
  - **OpsHub On-Prem**: Integration hub for data routing
- **Flightkeys**: AWS-based flight operations platform receiving TAF deletions
- **Akamai GTM**: Global traffic manager fronting inbound API endpoints exposed by EKS apps

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used in this flow (synchronous HTTPS)
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used in this flow (TAF UI uses separate data store)
  - **Criticality**: N/A

---

### Flow 25: ACARS REQLDI Requests Fulfilled by FOS

**Pattern**: Bidirectional Sync  
**Source**: Aircraft → AIRCOM Server → OpsHub On-Prem  
**NXOP Components**: None - NXOP has no role in this flow  
**Destinations**: AIRCOM Server → Aircraft  
**Communication**: Synchronous (ACARS request/response)  

**Architecture Flow**:
1. **Aircraft** sends REQLDI (Request Load Information) request via ACARS
2. **AIRCOM Server** (On-Prem) receives ACARS request
3. **AIRCOM Server** forwards REQLDI request to **OpsHub On-Prem** via MQ
4. **OpsHub On-Prem** forwards request to **FOS** (On-Prem) via MQ
5. **FOS** (DECS, Load Planning, Takeoff Performance, Crew Management) processes REQLDI request
6. **FOS** sends REQLDI response back to **OpsHub On-Prem** via MQ
7. **OpsHub On-Prem** forwards response to **AIRCOM Server** via MQ
8. **AIRCOM Server** transmits REQLDI response to aircraft via ACARS
9. **NXOP Platform** (AWS) is not involved in this flow
10. **FXIP** (Azure) and **OpsHub Azure** are not involved in this flow

**Key Components**:
- **On-Premises**:
  - **AIRCOM Server**: Gateway to aircraft ACARS systems
  - **OpsHub On-Prem**: Integration hub routing REQLDI requests/responses
  - **FOS**: Flight operations system (DECS, Load Planning, Takeoff Performance, Crew Management) fulfilling REQLDI requests
- **Aircraft**: Requesting load information via ACARS

**NXOP Infrastructure Dependencies**:
- **MSK Cluster**: 
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A
  
- **DocumentDB Global Cluster**:
  - **Role**: Not used - NXOP has no role in this flow
  - **Criticality**: N/A

**Note**: This flow is entirely on-premises. NXOP Platform does not participate in this integration. This flow may not be actively monitored by NXOP.


---

## Source-to-Destination Patterns

### Primary Data Sources

| Source System | Flow Count | Percentage | Flow Numbers |
|---------------|------------|------------|--------------|
| **Flightkeys** | 16 flows | 64% | 1, 2, 3, 4, 6, 7, 8, 9, 12, 14, 16, 17, 20, 23, 24 |
| **IBM Fusion Flight Tracking** | 4 flows | 16% | 19, 20, 21, 22 |
| **CyberJet FMS** | 2 flows | 8% | 13, 15 |
| **FOS (On-Prem)** | 3 flows | 12% | 1, 5, 18 |
| **Aircraft (ACARS)** | 1 flow | 4% | 25 |
| **FXIP On-Prem** | 1 flow | 4% | 11 |

**Note**: Flows 11, 12, 13, 15, 21, 25 have no NXOP involvement (NXOP Platform not used)

### Primary Destinations

| Destination System | Flow Count | Percentage | Flow Numbers |
|--------------------|------------|------------|--------------|
| **FOS (On-Prem)** | 19 flows | 76% | 1, 2, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 15, 18, 19, 21, 22, 25 |
| **OpsHub On-Prem** | 18 flows | 72% | 1, 5, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24 |
| **AIRCOM Server → Aircraft** | 10 flows | 40% | 7, 10, 11, 13, 14, 15, 19, 21, 22, 25 |
| **Flightkeys** | 2 flows | 8% | 1, 18 |
| **CyberJet FMS** | 2 flows | 8% | 11, 12 |
| **IBM Fusion Flight Tracking** | 1 flow | 4% | 20 |
| **Ops Engineering Apps** | 2 flows | 8% | 16, 17 |
| **CCI (Crew Check In)** | 3 flows | 12% | 7, 8, 9 |
| **IOC Meteorologists** | 1 flow | 4% | 24 |
| **Special Info Messages (On-Prem)** | 1 flow | 4% | 23 |
| **OpsHub Event Hubs (Azure)** | 1 flow | 4% | 5 |
| **Databricks/Orion** | 1 flow | 4% | 5 |

### Integration Pattern Summary

#### Pattern 1: Flightkeys → NXOP → On-Prem (Most Common)
**Flows**: 2, 3, 4, 6, 7, 8, 9, 14, 23, 24  
**Characteristics**:
- Source: Flightkeys (AMQP or HTTPS)
- Processing: NXOP Platform services (AWS EKS) + FXIP (Azure) parallel processing
- Destination: FOS/OpsHub On-Prem (HTTPS, MQ, or TCP)
- Communication: Asynchronous ingestion (AMQP), Synchronous or Asynchronous delivery
- **NXOP Role**: Active - EKS services process and route messages

#### Pattern 2: On-Prem → NXOP → External (Reverse Flow)
**Flows**: 1, 5, 18  
**Characteristics**:
- Source: FOS (On-Prem) via MQ
- Processing: NXOP Platform adapters (AWS EKS) + FXIP (Azure) parallel processing
- Destination: Flightkeys, OpsHub Event Hubs (Azure), or external systems (HTTPS)
- Communication: Asynchronous (MQ → Kafka → HTTPS)
- **NXOP Role**: Active - EKS adapters consume from MSK and deliver to destinations

#### Pattern 3: IBM Fusion → NXOP → On-Prem/Aircraft
**Flows**: 19, 20, 22  
**Characteristics**:
- Source: IBM Fusion Flight Tracking (HTTPS)
- Processing: NXOP Platform Fusion adapters (AWS EKS) + FXIP (Azure) parallel processing
- Destination: FOS, Aircraft via AIRCOM
- Communication: Synchronous ingestion (HTTPS), Mixed delivery (Kafka/MQ/ACARS)
- **NXOP Role**: Active - EKS Fusion adapters receive and process flight tracking data

#### Pattern 4: Bidirectional Engineering Data
**Flows**: 16, 17, 23, 24  
**Characteristics**:
- Source: Flightkeys (HTTPS)
- Processing: NXOP Platform data services (AWS EKS) + FXIP (Azure) parallel processing
- Destination: Ops Engineering Apps, IOC Meteorologists, or Special Info Messages (On-Prem)
- Communication: Synchronous bidirectional (HTTPS)
- **NXOP Role**: Active - EKS data services manage bidirectional sync

#### Pattern 5: eSignature Flows
**Flows**: 9, 10  
**Characteristics**:
- Source: Flightkeys (AMQP + HTTPS)
- Processing: NXOP Platform event processors (AWS EKS) + FXIP (Azure) parallel processing
- Destination: FOS, CCI, OpsHub On-Prem, Aircraft via AIRCOM
- Communication: Hybrid (AMQP events + HTTPS signatures)
- **NXOP Role**: Active - EKS event processors handle eSignature capture and validation

#### Pattern 6: No NXOP Involvement (Pass-Through or On-Prem Only)
**Flows**: 11, 12, 13, 15, 21, 25  
**Characteristics**:
- Source: Various (CyberJet FMS, Flightkeys, IBM Fusion, Aircraft)
- Processing: FXIP On-Prem, FXIP (Azure), or OpsHub components only
- Destination: FOS, CyberJet FMS, Aircraft via AIRCOM
- Communication: AMQP, HTTPS, ACARS, MQ
- **NXOP Role**: None - NXOP Platform does not participate in these flows

---

## NXOP Platform Dependencies

### NXOP Managed Infrastructure Overview

The NXOP platform operates two critical shared infrastructure components that serve multiple message flows:

1. **MSK (Managed Streaming for Apache Kafka)** - Event streaming backbone
2. **DocumentDB Global Cluster** - Reference data and metadata storage

### MSK Cluster Architecture

#### Cluster Configuration

**Primary Cluster (us-east-1)**:
- **Broker Count**: 6 brokers across 3 AZs (2 per AZ)
- **Instance Type**: kafka.m5.2xlarge
- **Storage**: 1TB EBS per broker (gp3)
- **Replication Factor**: 3 (within region)
- **Min In-Sync Replicas**: 2

**Secondary Cluster (us-west-2)**:
- **Broker Count**: 6 brokers across 3 AZs (2 per AZ)
- **Instance Type**: kafka.m5.2xlarge
- **Storage**: 1TB EBS per broker (gp3)
- **Replication Factor**: 3 (within region)
- **Min In-Sync Replicas**: 2

**Cross-Region Replication**:
- **Mechanism**: MSK Replicator
- **Direction**: Bidirectional (us-east-1 ↔ us-west-2)
- **Lag Target**: < 30 seconds
- **Monitoring**: CloudWatch metrics for replication lag

#### MSK Usage by Flow

| Flow # | Flow Name | Producer | Consumers | Criticality |
|--------|-----------|----------|-----------|-------------|
| 1 | FOS Events to Flightkeys | Aircraft/Flight Data Adapter (EKS) | Flightkeys connector, Kafka Connector (Azure) | HIGH |
| 2 | Flight Plans from Flightkeys | Flight Plan Processor (EKS) | MQ-Kafka adapter (On-Prem) | CRITICAL |
| 5 | Audit Logs, Weather, OFP | FXIP Audit Log Processor (EKS) | Kafka Connector (Azure) | HIGH |
| 10 | eSignature - ACARS | Flightkeys Event Processor (EKS), Flight Data Adapter (EKS) | MQ-Kafka adapter (On-Prem) | HIGH |
| 18 | Position Reports to FK | MQ-Kafka adapter (On-Prem) | Aircraft Data Adapter (EKS) | HIGH |
| 19 | Events to Fusion | Fusion Flight Movement Adapter (EKS) | MQ-Kafka adapter (On-Prem) | HIGH |

**Total Flows Using MSK**: 6 of 25 (24%)  
**Average Message Size**: 5-50 KB  
**Peak Throughput**: 5,000 messages/minute  
**Retention**: 7 days (compliance requirement)

**Note**: Flows 11, 12, 13, 15, 21, 25 do not use MSK as NXOP Platform is not involved

#### MSK Failure Scenarios

| Failure Type | Impact | Affected Flows | Mitigation Strategy |
|--------------|--------|----------------|---------------------|
| Single Broker Failure | Minimal - partition unavailability | All MSK flows | AWS auto-replacement, partition rebalancing |
| Multiple Broker Failures | High - reduced capacity | All MSK flows | Auto-scaling, partition rebalancing |
| Regional MSK Failure | Critical - regional unavailable | All MSK flows | Cross-region failover via ARC, Route53 DNS update |
| Cross-Region Replication Lag | Medium - stale data in secondary | All MSK flows | Replicator restart, manual recreation |
| Topic Partition Corruption | High - data unreadable | Specific flow | Partition recovery, topic recreation |

### DocumentDB Global Cluster Architecture

#### Cluster Configuration

**Global Cluster**:
- **Primary Region**: us-east-1
- **Secondary Region**: us-west-2
- **Instance Type**: db.r6g.2xlarge
- **Instances per Region**: 3 (1 primary, 2 read replicas)
- **Storage**: Auto-scaling (up to 64 TB)
- **Backup Retention**: 35 days
- **Encryption**: At rest (KMS) and in transit (TLS 1.3)

**Replication**:
- **Mechanism**: Native DocumentDB global cluster replication
- **Lag Target**: < 1 second
- **Consistency**: Eventual consistency for reads from secondary
- **Failover**: Automatic (< 1 minute)

#### DocumentDB Usage by Flow

| Flow # | Flow Name | Access Pattern | Criticality | Failover Impact |
|--------|-----------|----------------|-------------|-----------------|
| 1 | FOS Events to Flightkeys | Read-heavy (reference data enrichment) | MEDIUM | Degraded enrichment |
| 8 | Pilot Briefing Package | Read-heavy, occasional writes (metadata) | CRITICAL | Cannot assemble packages |
| 10 | eSignature - ACARS | Read for validation, Write for audit | HIGH | Cannot validate signatures |
| 18 | Position Reports to FK | Read-heavy (reference data enrichment) | MEDIUM | Position reports without enrichment |
| 19 | Events to Fusion | Read-heavy, occasional writes (movement history) | MEDIUM | Events without full enrichment |

**Total Flows Using DocumentDB**: 5 of 25 (20%)  
**Average Document Size**: 2-10 KB  
**Peak Read IOPS**: 10,000 IOPS  
**Peak Write IOPS**: 1,000 IOPS

**Note**: Flows 11, 12, 13, 15, 21, 25 do not use DocumentDB as NXOP Platform is not involved

#### DocumentDB Failure Scenarios

| Failure Type | Impact | Affected Flows | Mitigation Strategy |
|--------------|--------|----------------|---------------------|
| Read Replica Failure | Minimal - reduced read capacity | All DocumentDB flows | Automatic replacement |
| Primary Instance Failure | High - cannot write | Flows 8, 10, 19 | Automatic failover to replica |
| Regional Cluster Failure | Critical - regional unavailable | All DocumentDB flows | Global cluster failover to secondary region |
| Replication Lag | Medium - stale reads | All DocumentDB flows | Monitor lag, acceptable threshold |
| Connection Pool Exhaustion | High - cannot connect | All DocumentDB flows | Connection pool scaling, recycling |

### Combined MSK + DocumentDB Dependencies

**Flows Using Both MSK and DocumentDB**: 4 flows (1, 10, 18, 19)

#### Flow 1: FOS Events to Flightkeys
- **MSK**: Event streaming backbone
- **DocumentDB**: Reference data enrichment
- **Dependency Chain**: FOS → MQ-Kafka adapter → MSK → Aircraft/Flight Data Adapter (EKS) → DocumentDB (lookup) → Flightkeys (HTTPS)
- **Failure Impact**: MSK failure stops event flow; DocumentDB failure degrades enrichment

#### Flow 10: eSignature - ACARS
- **MSK**: Signature event streaming
- **DocumentDB**: Signature validation and audit
- **Dependency Chain**: Flightkeys → Flightkeys Event Processor (EKS) → DocumentDB (validate) → MSK → MQ-Kafka adapter → FOS
- **Failure Impact**: MSK failure stops event distribution; DocumentDB failure prevents validation

#### Flow 18: Position Reports to Flightkeys
- **MSK**: Position report streaming
- **DocumentDB**: Position data enrichment
- **Dependency Chain**: FOS → MQ-Kafka adapter → MSK → Aircraft Data Adapter (EKS) → DocumentDB (lookup) → Flightkeys (HTTPS)
- **Failure Impact**: MSK failure stops position reports; DocumentDB failure degrades enrichment

#### Flow 19: Publish Flight Events to FXIP Fusion
- **MSK**: Flight movement event streaming
- **DocumentDB**: Flight movement validation and enrichment
- **Dependency Chain**: IBM Fusion → Fusion Flight Movement Adapter (EKS) → DocumentDB (validate) → MSK → MQ-Kafka adapter → FOS
- **Failure Impact**: MSK failure stops event distribution; DocumentDB failure degrades enrichment

### Infrastructure Monitoring and Alerting

#### MSK Monitoring

**CloudWatch Metrics**:
- `BytesInPerSec`, `BytesOutPerSec` - Throughput monitoring
- `MessagesInPerSec` - Message rate
- `UnderReplicatedPartitions` - Replication health
- `OfflinePartitionsCount` - Partition availability
- `ActiveControllerCount` - Controller health
- `ReplicationLatency` - Cross-region lag

**Alarms**:
- High replication lag (> 60 seconds)
- Offline partitions (> 0)
- Under-replicated partitions (> 0)
- Disk usage (> 80%)
- CPU utilization (> 70%)

#### DocumentDB Monitoring

**CloudWatch Metrics**:
- `CPUUtilization` - Compute usage
- `DatabaseConnections` - Connection pool health
- `FreeableMemory` - Memory availability
- `ReadLatency`, `WriteLatency` - Performance
- `ReplicationLag` - Global cluster sync
- `VolumeBytesUsed` - Storage usage

**Alarms**:
- High replication lag (> 5 seconds)
- Connection pool exhaustion (> 90%)
- High CPU (> 80%)
- Low memory (< 20%)
- High read/write latency (> 100ms)

### Cost Optimization

#### MSK Costs
- **Broker Instances**: $1,200/month per broker × 12 brokers = $14,400/month
- **Storage**: $0.10/GB-month × 12 TB = $1,200/month
- **Data Transfer**: $0.02/GB × 10 TB/month = $200/month
- **Total MSK**: ~$15,800/month

#### DocumentDB Costs
- **Instances**: $800/month per instance × 6 instances = $4,800/month
- **Storage**: $0.10/GB-month × 500 GB = $50/month
- **Backup Storage**: $0.02/GB-month × 1 TB = $20/month
- **Data Transfer**: $0.02/GB × 1 TB/month = $20/month
- **Total DocumentDB**: ~$4,890/month

**Total Infrastructure Cost**: ~$20,690/month

### Core NXOP Services

**Note**: Services marked with (EKS) are deployed on AWS NXOP Platform. Services marked with (On-Prem) or (Azure) are not NXOP-managed.

#### 1. Message Processing Services

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **Flight Plan Processor** | 2, 8 | Flight plan ingestion and processing | EKS (us-east-1, us-west-2) |
| **Flightkeys Event Processor** | 3, 9, 10 | Event processing and transformation | EKS (us-east-1, us-west-2) |
| **Text Message Processor** | 6, 14 | Free-text message formatting | EKS (us-east-1, us-west-2) |
| **Notification Service** | 7 | Flight release notifications | EKS (us-east-1, us-west-2) |
| **FXIP Audit Log Processor** | 5 | Audit log processing | EKS (us-east-1, us-west-2) |

#### 2. Data Adapter Services

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **Aircraft Data Adapter** | 1, 18 | Aircraft data transformation | EKS (us-east-1, us-west-2) |
| **Flight Data Adapter** | 1, 10 | Flight data transformation | EKS (us-east-1, us-west-2) |
| **Fusion Flight Movement Adapter** | 19 | IBM Fusion integration | EKS (us-east-1, us-west-2) |
| **Fusion Integration Adapter** | 20 | IBM Fusion flight plan integration | EKS (us-east-1, us-west-2) |
| **FXIP ACARS Adapter** | 11, 13, 15 | ACARS protocol handling | On-Prem (not NXOP) |

#### 3. Integration Services

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **Flightkeys Integration Service** | 8, 9 | Flightkeys API integration | EKS (us-east-1, us-west-2) |
| **Flight Plan Service** | 8 | Flight plan retrieval | EKS (us-east-1, us-west-2) |
| **Pilot Document Service** | 8 | Document assembly | EKS (us-east-1, us-west-2) |
| **Fusion ACARS Service** | 22 | IBM Fusion ACARS messaging | EKS (us-east-1, us-west-2) |

#### 4. Proxy Services

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **FTM Uplink Proxy** | 4, 7, 14, 22 | FTM uplink to FOS | EKS (us-east-1, us-west-2) |
| **LCA Flight Update Proxy** | 3, 9, 10 | LCA updates to FOS | EKS (us-east-1, us-west-2) |
| **OpsHub Host Print Proxy** | 6 | Print service proxy | EKS (us-east-1, us-west-2) |

#### 5. Data Services

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **Aircraft Data Service** | 16 | Aircraft reference data | EKS (us-east-1, us-west-2) |
| **Nav Data Service** | 17 | Navigation and fuel data | EKS (us-east-1, us-west-2) |
| **Data Maintenance Service** | 23 | Special information messages | EKS (us-east-1, us-west-2) |
| **Terminal Area Forecast UI** | 24 | Weather forecast management | EKS (us-east-1, us-west-2) |

#### 6. Infrastructure Services

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **MSK (Kafka)** | 1, 2, 5, 10, 18, 19 | Event streaming backbone | AWS MSK (us-east-1, us-west-2) |
| **DocumentDB** | 1, 8, 10, 18, 19 | Reference data storage | AWS DocumentDB (global cluster) |
| **S3** | 8 | Document storage | AWS S3 (us-east-1, us-west-2) |
| **Akamai GTM** | All EKS services | Global traffic manager for inbound APIs | Global CDN |
| **Route53** | 1, 2, 5, 10, 18, 19 | DNS for MSK bootstrap (kafka.nxop.com) | AWS Route53 |
| **NLB** | 1, 2, 5, 10, 18, 19 | Network load balancer for MSK | AWS NLB (us-east-1, us-west-2) |

#### 7. Non-NXOP Components (For Reference)

| Service | Flows | Purpose | Deployment |
|---------|-------|---------|------------|
| **MQ-Kafka Adapter** | 1, 2, 10, 18, 19 | Bridges FOS MQ to NXOP MSK | On-Prem |
| **Kafka Connector (Azure)** | 5 | Bridges NXOP MSK to OpsHub Event Hubs | Azure |
| **OpsHub On-Prem** | Multiple | Integration hub | On-Prem |
| **AIRCOM Server** | Multiple | Aircraft ACARS gateway | On-Prem |
| **FOS** | Multiple | Flight operations system | On-Prem |

### Service Dependency Matrix

| NXOP Service | Depends On | Used By Flows |
|--------------|------------|---------------|
| **Flight Plan Processor** | MSK, DocumentDB | 2, 8 |
| **Aircraft Data Adapter** | DocumentDB, MSK | 1, 18 |
| **Flight Data Adapter** | DocumentDB, MSK | 1, 10 |
| **Flightkeys Event Processor** | LCA Flight Update Proxy | 3, 9, 10 |
| **Notification Service** | FTM Uplink Proxy, FlightInfo API | 7 |
| **Pilot Document Service** | DocumentDB, S3, Flight Plan Service | 8 |
| **Fusion Flight Movement Adapter** | DocumentDB, MSK, OpsHub Event Hubs | 19 |
| **Text Message Processor** | FTM Uplink Proxy, OpsHub Host Print Proxy | 6, 14 |

### External System Dependencies

| External System | Flows | Criticality | Failure Impact |
|-----------------|-------|-------------|----------------|
| **Flightkeys** | 20 flows | Critical | 80% of flows affected |
| **AIRCOM Server** | 10 flows | Critical | Aircraft communication loss |
| **OpsHub On-Prem** | 25 flows | Critical | Complete on-prem integration loss |
| **FOS** | 19 flows | Critical | Operational system unavailable |
| **IBM Fusion** | 4 flows | High | Enterprise tracking loss |
| **CyberJet FMS** | 4 flows | High | FMS integration loss |
| **DocumentDB** | 8 flows | High | Reference data unavailable |
| **MSK** | 10 flows | High | Event streaming disruption |


---

## Communication Patterns

### Protocol Distribution

| Protocol | Flow Count | Percentage | Primary Use Case |
|----------|------------|------------|------------------|
| **HTTPS** | 21 flows | 84% | Synchronous APIs, critical operations |
| **AMQP** | 15 flows | 60% | Asynchronous messaging, Flightkeys integration |
| **Kafka** | 10 flows | 40% | Event streaming, data distribution |
| **MQ** | 9 flows | 36% | On-prem messaging, legacy integration |
| **ACARS** | 10 flows | 40% | Aircraft communication |
| **TCP** | 4 flows | 16% | OpsHub delivery |

### Synchronous vs. Asynchronous Communication

#### Synchronous Communication (HTTPS)

**Flows with Synchronous Patterns**: 3, 4, 6, 7, 8, 9, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25

**Characteristics**:
- Request/response pattern
- Immediate acknowledgment required
- Used for critical operations (flight release, signatures, data retrieval)
- Typically HTTPS protocol
- Lower latency requirements

**Use Cases**:
1. **Flight Release Operations** (Flows 7, 9, 10): Immediate confirmation required
2. **Document Retrieval** (Flow 8): Real-time briefing package assembly
3. **Data Maintenance** (Flows 16, 17, 23, 24): Bidirectional data synchronization
4. **Position Reporting** (Flows 18, 21): Real-time tracking updates
5. **ACARS Requests** (Flow 25): Aircraft-initiated data requests

#### Asynchronous Communication (AMQP, Kafka, MQ)

**Flows with Asynchronous Patterns**: 1, 2, 5, 10, 11, 12, 13, 14, 15, 18, 19, 20

**Characteristics**:
- Fire-and-forget or eventual consistency
- Message queuing and buffering
- Decoupled producers and consumers
- Higher throughput, lower latency sensitivity
- Resilient to temporary outages

**Use Cases**:
1. **Event Streaming** (Flows 1, 2, 5, 10, 18, 19): High-volume event distribution
2. **Flight Plan Distribution** (Flows 2, 12, 20): Batch processing acceptable
3. **Audit Logging** (Flow 5): Non-blocking event capture
4. **Text Messaging** (Flows 6, 14): Queued message delivery

#### Hybrid Communication Patterns

**Flows with Hybrid Patterns**: 8, 9, 10, 13, 15, 19, 20, 22

**Characteristics**:
- Combine synchronous and asynchronous patterns
- Asynchronous ingestion with synchronous delivery
- Event-driven with request/response components

**Examples**:
1. **Flow 8 (Pilot Briefing)**: Synchronous HTTPS request triggers asynchronous document assembly
2. **Flow 9 (CCI eSignature)**: AMQP events + HTTPS signature capture
3. **Flow 10 (ACARS eSignature)**: AMQP events + HTTPS signatures + Kafka distribution
4. **Flow 19 (Fusion Events)**: HTTPS ingestion + Kafka distribution + MQ delivery

### Communication Flow Patterns

#### Pattern A: Asynchronous Ingestion → Synchronous Delivery
**Flows**: 3, 4, 6, 7, 14  
**Flow**: AMQP (Flightkeys) → NXOP Processing → HTTPS (On-Prem)  
**Rationale**: Decouple from source, ensure reliable delivery to destination

#### Pattern B: Synchronous Ingestion → Asynchronous Distribution
**Flows**: 18, 19, 21  
**Flow**: HTTPS (Source) → NXOP Processing → Kafka/MQ (Distribution)  
**Rationale**: Immediate acknowledgment to source, fan-out to multiple consumers

#### Pattern C: Asynchronous End-to-End
**Flows**: 1, 2, 5, 11, 12  
**Flow**: AMQP/MQ (Source) → NXOP Processing → Kafka/MQ (Destination)  
**Rationale**: High throughput, eventual consistency acceptable

#### Pattern D: Synchronous End-to-End
**Flows**: 16, 17, 23, 24, 25  
**Flow**: HTTPS (Source) → NXOP Processing → HTTPS (Destination)  
**Rationale**: Immediate consistency required, bidirectional operations

#### Pattern E: Event-Driven with Multiple Protocols
**Flows**: 10, 13, 15, 22  
**Flow**: Multiple protocols (AMQP + HTTPS + Kafka + ACARS)  
**Rationale**: Complex workflows requiring multiple communication patterns

### Protocol Usage by Flow Type

| Flow Type | Primary Protocol | Secondary Protocol | Rationale |
|-----------|------------------|-------------------|-----------|
| **Flight Planning** | AMQP | Kafka, HTTPS | High volume, eventual consistency |
| **Flight Operations** | AMQP, Kafka | HTTPS | Event-driven, real-time distribution |
| **Communications** | AMQP | HTTPS, ACARS | Queued messaging, aircraft delivery |
| **Authorization** | HTTPS | AMQP | Immediate confirmation required |
| **Aircraft Systems** | ACARS | HTTPS, MQ | Aircraft-specific protocol |
| **Engineering/Maintenance** | HTTPS | None | Bidirectional sync, immediate consistency |
| **Operational Support** | HTTPS | None | User-facing, immediate feedback |

### Message Delivery Guarantees

| Protocol | Delivery Guarantee | Ordering | Durability |
|----------|-------------------|----------|------------|
| **HTTPS** | At-most-once (with retries) | N/A | Application-dependent |
| **AMQP** | At-least-once | Per-queue | Persistent queues |
| **Kafka** | At-least-once (configurable) | Per-partition | Replicated logs |
| **MQ** | At-least-once | Per-queue | Persistent queues |
| **ACARS** | At-most-once | N/A | Non-persistent |
| **TCP** | At-most-once | Stream-ordered | Non-persistent |

### Latency Characteristics

| Communication Pattern | Typical Latency | Flows | Use Case |
|----------------------|-----------------|-------|----------|
| **Synchronous HTTPS** | < 1 second | 16, 17, 23, 24, 25 | Interactive operations |
| **Async AMQP → HTTPS** | 1-5 seconds | 3, 4, 6, 7, 14 | Near real-time delivery |
| **Async AMQP → Kafka** | 5-30 seconds | 1, 2, 5 | Batch processing |
| **HTTPS → Kafka → MQ** | 10-60 seconds | 18, 19 | Multi-hop distribution |
| **ACARS** | 30-120 seconds | 7, 10, 13-15, 21, 22, 25 | Aircraft communication |

---

---

## Critical Dependencies

### Tier 1 Dependencies (Critical - Affects 50%+ of Flows)

#### 1. OpsHub On-Prem
**Affected Flows**: All 25 flows (100%)  
**Impact**: Complete on-prem integration loss  
**Mitigation**: 
- Redundant OpsHub instances
- Health monitoring and alerting
- Backup communication paths

#### 2. Flightkeys
**Affected Flows**: 20 flows (80%)  
**Impact**: Primary data source unavailable  
**Mitigation**:
- Vendor SLA monitoring
- Cached data for critical operations
- Alternative data sources where available

#### 3. FOS (Flight Operations System)
**Affected Flows**: 19 flows (76%)  
**Impact**: Core operational system unavailable  
**Mitigation**:
- On-prem redundancy
- Business continuity procedures
- Manual operational fallback

### Tier 2 Dependencies (High - Affects 25-50% of Flows)

#### 4. AIRCOM Server
**Affected Flows**: 10 flows (40%)  
**Impact**: Aircraft communication loss  
**Mitigation**:
- Redundant AIRCOM instances
- Alternative communication channels (satellite)
- Ground-based backup communication

#### 5. MSK (Kafka)
**Affected Flows**: 10 flows (40%)  
**Impact**: Event streaming disruption  
**Mitigation**:
- Multi-AZ MSK cluster
- Cross-region replication
- Message buffering in producers

#### 6. DocumentDB
**Affected Flows**: 8 flows (32%)  
**Impact**: Reference data unavailable  
**Mitigation**:
- Global cluster with automatic failover
- Read replicas in multiple regions
- Cached reference data in applications
- Direct Kafka integration as backup

#### 8. IBM Fusion Flight Tracking
**Affected Flows**: 4 flows (16%)  
**Impact**: Enterprise tracking loss  
**Mitigation**:
- Vendor SLA monitoring
- Alternative tracking sources
- Cached position data

#### 9. CyberJet FMS
**Affected Flows**: 4 flows (16%)  
**Impact**: FMS integration loss  
**Mitigation**:
- Vendor SLA monitoring
- Alternative FMS data sources
- Manual FMS updates

### Tier 4 Dependencies (Low - Affects < 10% of Flows)

#### 10. S3 Storage
**Affected Flows**: 1 flow (4%)  
**Impact**: Document storage unavailable  
**Mitigation**:
- Cross-region replication
- Multi-cloud storage (S3 + Azure Blob)
- Cached documents

#### 11. Ops Engineering Client Apps
**Affected Flows**: 2 flows (8%)  
**Impact**: Engineering operations disrupted  
**Mitigation**:
- Client application redundancy
- Web-based backup interfaces
- Manual data entry procedures

#### 12. CCI (Crew Check In)
**Affected Flows**: 3 flows (12%)  
**Impact**: Crew operations disrupted  
**Mitigation**:
- CCI system redundancy
- Alternative crew notification channels
- Manual crew check-in procedures

### Dependency Chain Analysis

#### Chain 1: Flightkeys → NXOP → MSK → On-Prem
**Flows**: 1, 2, 5, 10, 18, 19  
**Risk**: Multi-hop failure potential  
**Architecture**: Each hop has independent redundancy

#### Chain 2: Flightkeys → NXOP → HTTPS → On-Prem
**Flows**: 3, 4, 6, 7, 14, 23, 24  
**Risk**: Synchronous dependency chain  
**Architecture**: Timeout and retry mechanisms

#### Chain 3: On-Prem → NXOP → Kafka → External
**Flows**: 1, 18  
**Risk**: Reverse flow dependency  
**Architecture**: Message buffering and retry

#### Chain 4: IBM Fusion → NXOP → Multiple Destinations
**Flows**: 19, 20, 21, 22  
**Risk**: Single vendor dependency (Accepted)  
**Architecture**: Vendor SLA, alternative sources

### Single Points of Failure (SPOF)

| Component | Affected Flows | Mitigation Status | Risk Level |
|-----------|----------------|-------------------|------------|
| **OpsHub On-Prem** | All 25 flows | Redundant instances | Low |
| **Flightkeys** | 20 flows | Vendor-managed, SLA | Medium |
| **AIRCOM Server** | 10 flows | Redundant instances | Low |
| **FOS** | 19 flows | On-prem redundancy | Low |
| **IBM Fusion** | 4 flows | Vendor-managed, SLA | Medium |
| **CyberJet FMS** | 4 flows | Vendor-managed, SLA | Medium |


------

## Appendix

### Flow Quick Reference

| Flow # | Name | Source | Destination | Protocol | NXOP Role | MSK | DocumentDB |
|--------|------|--------|-------------|----------|-----------|-----|------------|
| 1 | FOS Events to Flightkeys | FOS | Flightkeys | MQ→Kafka→HTTPS | Active | ✓ | ✓ |
| 2 | Flight Plans from Flightkeys | Flightkeys | FOS | AMQP→Kafka→MQ | Active | ✓ | - |
| 3 | Flightkeys Events to FOS | Flightkeys | FOS | AMQP→HTTPS | Active | - | - |
| 4 | Flightplan Data to FOS | Flightkeys | FOS | AMQP→HTTPS | Active | - | - |
| 5 | Audit Logs, Weather, OFP | Flightkeys | Azure | AMQP→Kafka | Active | ✓ | - |
| 6 | Summary Flight Plans | Flightkeys | FOS | AMQP→HTTPS | Active | - | - |
| 7 | Flight Release Notifications | Flightkeys | ACARS, CCI | AMQP→HTTPS | Active | - | - |
| 8 | Pilot Briefing Package | Flightkeys | FOS, CCI | HTTPS | Active | - | ✓ |
| 9 | eSignature - CCI | Flightkeys | FOS | AMQP+HTTPS | Active | - | - |
| 10 | eSignature - ACARS | Flightkeys | FOS, Aircraft | AMQP+HTTPS | Active | ✓ | ✓ |
| 11 | Events to CyberJet | FXIP On-Prem | CyberJet FMS | AMQP→MQ | None | - | - |
| 12 | Flight Plans to CyberJet | Flightkeys | CyberJet FMS | AMQP | None | - | - |
| 13 | FMS Init & ACARS Requests | CyberJet, FK | FOS, Aircraft | AMQP+HTTPS | None | - | - |
| 14 | ACARS Free Text | Flightkeys | FOS, Aircraft | AMQP→HTTPS | Active | - | - |
| 15 | Flight Progress Reports | Dispatchers | FOS, Aircraft | AMQP+HTTPS | None | - | - |
| 16 | Fleet Reference Data | Flightkeys | Ops Eng Apps | HTTPS | Active | - | - |
| 17 | Fuel Data Updates | Flightkeys | Ops Eng Apps | HTTPS | Active | - | - |
| 18 | Position Reports to FK | FOS | Flightkeys | MQ→Kafka→HTTPS | Active | ✓ | ✓ |
| 19 | Events to Fusion | IBM Fusion | FOS, Aircraft | HTTPS→Kafka | Active | ✓ | ✓ |
| 20 | Flight Plans to Fusion | FK, IBM Fusion | FOS | AMQP+HTTPS | Active | - | - |
| 21 | Position Reports to Fusion | IBM Fusion | FOS, Aircraft | HTTPS | None | - | - |
| 22 | Fusion ACARS Messaging | IBM Fusion | FOS, Aircraft | HTTPS→ACARS | Active | - | - |
| 23 | Special Info Messages | Flightkeys | On-Prem | HTTPS | Active | - | - |
| 24 | TAF Deletions | Flightkeys | Meteorologists | HTTPS | Active | - | - |
| 25 | ACARS REQLDI | Aircraft | Aircraft | ACARS | None | - | - |

**Legend**:
- ✓ = Used by flow
- \- = Not used by flow
- **NXOP Role**: 
  - Active = NXOP Platform (AWS EKS) actively processes messages
  - None = NXOP Platform not involved (FXIP On-Prem, FXIP Azure, or OpsHub only)

**Summary Statistics**:
- **Total Flows**: 25
- **Flows with Active NXOP Role**: 19 (76%)
- **Flows with No NXOP Role**: 6 (24%) - Flows 11, 12, 13, 15, 21, 25
- **Flows Using MSK**: 6 (24%)
- **Flows Using DocumentDB**: 5 (20%)
- **Flows Using Both MSK and DocumentDB**: 4 (16%)

### Glossary

**Infrastructure Terms**:
- **MSK**: Managed Streaming for Apache Kafka (AWS) - Event streaming platform
- **DocumentDB**: AWS DocumentDB (MongoDB-compatible) - NoSQL database
- **Global Cluster**: DocumentDB multi-region deployment with automatic failover
- **Cross-Region Replication**: Data replication between AWS regions (us-east-1 ↔ us-west-2)
- **Partition**: Kafka topic subdivision for parallel processing
- **Consumer Group**: Kafka consumer coordination mechanism
- **Replication Factor**: Number of Kafka partition replicas (default: 3)
- **ISR**: In-Sync Replicas - Kafka replicas that are up-to-date

**Protocol and Communication Terms**:
- **ACARS**: Aircraft Communications Addressing and Reporting System
- **AMQP**: Advanced Message Queuing Protocol
- **ARC**: Application Recovery Controller (AWS)
- **CCI**: Crew Check In
- **DECS**: Dispatch Engineering Computer System
- **FMS**: Flight Management System
- **FOS**: Flight Operations System
- **FXIP**: Flight Exchange Integration Platform
- **HA**: High Availability
- **IOC**: Integrated Operations Center
- **LCA**: Load Control Agent
- **NXOP**: Network Operations Platform
- **OFP**: Operational Flight Plan
- **PBCF**: Performance Based Contingency Fuel
- **REQLDI**: Request Load Information (ACARS message type)
- **RTO**: Recovery Time Objective
- **TAF**: Terminal Area Forecast

### Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-17 | System Analysis | Initial comprehensive analysis of 25 message flows |
| 1.1 | 2026-01-18 | System Analysis | Enhanced with detailed MSK and DocumentDB dependencies |
| 2.0 | 2026-01-18 | System Analysis | Removed resilience/recovery sections - focused on integration patterns and dependencies only |

---

**End of Document**
