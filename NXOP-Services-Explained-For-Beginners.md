# NXOP Services Explained for Beginners
## Understanding the 21 Microservices in Simple Terms

**Document Version**: 1.0  
**Date**: February 8, 2026  
**Audience**: New team members, non-technical stakeholders  
**Purpose**: Explain what each NXOP service does in plain English with real-world examples

---

## Table of Contents

1. [Understanding the Big Picture](#understanding-the-big-picture)
2. [Category 1: Data Adapters (7 services)](#category-1-data-adapters-7-services)
3. [Category 2: Data Processors (5 services)](#category-2-data-processors-5-services)
4. [Category 3: Integration Services (4 services)](#category-3-integration-services-4-services)
5. [Category 4: API Services (3 services)](#category-4-api-services-3-services)
6. [Category 5: Specialized Services (2 services)](#category-5-specialized-services-2-services)
7. [Admin Tools (6 tools)](#admin-tools-6-tools)
8. [External Systems Explained](#external-systems-explained)
9. [How They All Work Together](#how-they-all-work-together)

---

## Understanding the Big Picture

### What is a Microservice?

Think of a microservice like a specialized worker in a factory. Instead of one giant program that does everything, you have many small programs that each do one specific job really well.

**Example**: 
- Instead of one "Flight System" that does everything
- You have separate services: one tracks flights, one tracks aircraft, one handles crew, etc.
- If one breaks, the others keep working

### Why 21 Different Services?

American Airlines operates 6,800+ flights daily. That's a LOT of data:
- Flight schedules and updates
- Aircraft locations and status
- Crew assignments
- Maintenance records
- Weather information
- Airport data

Each service handles a specific type of data or workflow.



### The Three Main Data Highways

Before we dive into services, understand these three "highways" where data travels:

1. **MSK (Managed Streaming for Kafka)** - Think of this as a super-fast highway where messages flow
   - Like a conveyor belt that never stops
   - Services put messages on it, other services read messages from it
   - Can handle millions of messages per day

2. **DocumentDB** - Think of this as a giant filing cabinet
   - Stores operational data (flights, aircraft, crew, etc.)
   - Services read from it and write to it
   - Like a database, but designed for real-time operations

3. **S3** - Think of this as a warehouse for documents
   - Stores PDFs, charts, weather maps, etc.
   - Long-term storage for files
   - Services retrieve documents when needed

---

## Category 1: Data Adapters (7 services)
### "The Translators and Routers"

**What They Do**: Adapters take data from one place, transform it if needed, and send it somewhere else. Like a translator who also delivers mail.

---

### 1. Flight Data Adapter
**Simple Explanation**: Handles everything about flight schedules and status

**Real-World Example**:
```
Flight AA100 from Dallas to New York:
- Departure time changed from 2:00 PM to 2:15 PM
- Gate changed from D15 to D18
- Aircraft changed from tail number N12345 to N67890

This adapter:
1. Receives this update from MSK (the highway)
2. Updates DocumentDB (the filing cabinet) with new info
3. Sends notification to Flightkeys system via HTTPS
```

**What It Touches**:
- **Reads from**: MSK topics (flight-event-aa-*, flight-event-mq-*, flight-event-te-*)
- **Writes to**: DocumentDB collections (FlightTimes, FlightLeg, FlightPlan)
- **Sends to**: Flightkeys system (external vendor)

**Why It Matters**: If this breaks, flight updates don't get processed. Pilots, crew, and passengers won't know about changes.

---

### 2. Aircraft Data Adapter
**Simple Explanation**: Tracks where every aircraft is and how it's performing

**Real-World Example**:
```
Aircraft N12345 (Boeing 737):
- Currently over Kansas City at 35,000 feet
- Speed: 450 knots
- Fuel remaining: 8,500 lbs
- ETA to destination: 45 minutes

This adapter:
1. Receives position updates from MSK
2. Updates DocumentDB with current location and performance
3. Makes this data available to other systems
```

**What It Touches**:
- **Reads from**: MSK topics (aircraft-*)
- **Writes to**: DocumentDB collections (AircraftLocation, AircraftPerformance, AircraftIdentity)
- **Used by**: Flight planning, maintenance, operations teams

**Why It Matters**: Operations needs to know where every plane is at all times. If this breaks, you lose visibility of your fleet.

---

### 3. Station Data Adapter
**Simple Explanation**: Manages information about airports and gates

**Real-World Example**:
```
Dallas/Fort Worth Airport (DFW):
- Terminal D, Gate 15 is now available
- Gate equipment: Jetway operational
- Weather: Clear, 75°F
- Runway 18R/36L: Open

This adapter:
1. Receives airport updates from external providers
2. Updates DocumentDB with station information
3. Makes gate and airport data available to flight planning
```

**What It Touches**:
- **Reads from**: External airport data providers (HTTPS APIs)
- **Writes to**: DocumentDB collections (StationIdentity, StationGeo, StationAuthorization)
- **Used by**: Flight planning, crew scheduling, operations

**Why It Matters**: You need to know which gates are available, airport conditions, etc. If this breaks, you can't assign gates or plan operations.

---

### 4. Maintenance Data Adapter
**Simple Explanation**: Handles aircraft maintenance records and schedules

**Real-World Example**:
```
Aircraft N12345:
- Engine inspection due in 50 flight hours
- Tire replacement completed yesterday
- Next major maintenance: March 15, 2026
- Current maintenance status: Airworthy

This adapter:
1. Receives maintenance events from on-prem FOS systems via MQ
2. Updates DocumentDB with maintenance records
3. Alerts if maintenance is due soon
```

**What It Touches**:
- **Reads from**: On-prem FOS via MQ-Kafka adapter
- **Writes to**: DocumentDB maintenance collections
- **Used by**: Maintenance teams, flight planning (can't fly if maintenance due)

**Why It Matters**: Safety-critical. You can't fly an aircraft that needs maintenance. If this breaks, you might miss maintenance requirements.

---

### 5. Crew Data Adapter
**Simple Explanation**: Manages pilot and flight attendant assignments

**Real-World Example**:
```
Flight AA100:
- Captain: John Smith (employee #12345)
- First Officer: Jane Doe (employee #67890)
- Flight Attendants: 4 crew members assigned
- Crew check-in status: All checked in
- Crew qualifications: All current

This adapter:
1. Receives crew assignments from Azure FXIP
2. Updates DocumentDB with crew information
3. Forwards to FOS systems for legacy integration
```

**What It Touches**:
- **Reads from**: Azure FXIP (AMQP events)
- **Writes to**: DocumentDB crew collections
- **Sends to**: FOS systems (legacy)

**Why It Matters**: You can't fly without a qualified crew. If this breaks, crew assignments don't get processed.

---

### 6. MSK → EventHub Adapter
**Simple Explanation**: Sends NXOP data to the old FXIP system (during migration)

**Real-World Example**:
```
During migration, FXIP still needs data:
- NXOP processes a flight update
- This adapter takes that update from MSK
- Sends it to Azure EventHub (FXIP's message system)
- FXIP receives the update and continues working

This is like forwarding your mail to a new address while you still check the old one.
```

**What It Touches**:
- **Reads from**: NXOP MSK topics
- **Writes to**: Azure EventHub (FXIP)
- **Purpose**: Keep FXIP updated during coexistence period

**Why It Matters**: Critical during Phases 1-3. Without this, FXIP (the backup system) wouldn't have current data. After Phase 4, this gets decommissioned.

---

### 7. MSK → On-Prem MQ Adapter
**Simple Explanation**: Sends NXOP data to on-premises systems

**Real-World Example**:
```
On-premises OpsHub needs flight updates:
- NXOP processes a gate change
- This adapter takes the update from MSK
- Converts it to IBM MQ format
- Sends to on-prem OpsHub
- OpsHub distributes to legacy systems

This is like translating English to Spanish and delivering the message.
```

**What It Touches**:
- **Reads from**: NXOP MSK topics
- **Writes to**: On-premises OpsHub MQ queues
- **Protocol**: IBM MQ (legacy messaging system)

**Why It Matters**: Many legacy systems are on-premises and can't be moved to cloud. This bridges cloud and on-prem worlds.

---


## Category 2: Data Processors (5 services)
### "The Listeners and Publishers"

**What They Do**: Processors listen to external systems, receive data, and publish it to MSK so other NXOP services can use it. Like a receptionist who receives packages and distributes them.

---

### 8. Flightkeys Event Processor
**Simple Explanation**: Listens to Flightkeys system and brings flight data into NXOP

**Real-World Example**:
```
Flightkeys (flight planning system) sends an event:
"Flight AA100 flight plan approved by dispatcher"

This processor:
1. Listens to Flightkeys AMQP queue (like a mailbox)
2. Receives the flight plan approval event
3. Publishes to MSK topic "flight-event-aa-flightplan-avro"
4. Now all NXOP services can see the approved flight plan
```

**What It Touches**:
- **Reads from**: Flightkeys AMQP queues (Azure FXIP)
- **Writes to**: MSK topics (flight-event-*)
- **Handles**: Flight releases, flight plan approvals, crew notifications

**Why It Matters**: Flightkeys is the primary flight planning system. If this breaks, flight plans don't make it into NXOP.

**Technical Details**:
- **Protocol**: AMQP (Advanced Message Queuing Protocol)
- **Message Format**: Avro (binary format for efficiency)
- **Frequency**: Thousands of events per day

---

### 9. EventHub → MSK Connector
**Simple Explanation**: Brings data from old FXIP system into NXOP (during migration)

**Real-World Example**:
```
During migration, FXIP still generates some data:
- FXIP processes a crew assignment
- Publishes to Azure EventHub
- This connector listens to EventHub
- Publishes to NXOP MSK
- Now NXOP has the crew assignment

This is like having someone check your old email and forward important messages.
```

**What It Touches**:
- **Reads from**: Azure EventHub (FXIP)
- **Writes to**: NXOP MSK topics
- **Purpose**: Bidirectional sync during coexistence

**Why It Matters**: During Phases 1-3, both systems need to stay in sync. After Phase 4, this gets decommissioned.

---

### 10. On-Prem MQ → MSK Adapter
**Simple Explanation**: Brings data from on-premises systems into NXOP

**Real-World Example**:
```
On-premises FOS system sends maintenance update:
"Aircraft N12345 completed tire replacement"

This adapter:
1. Listens to on-prem OpsHub MQ queue
2. Receives the maintenance event
3. Converts from MQ format to Kafka format
4. Publishes to MSK topic "maintenance-event-avro"
5. Maintenance Data Adapter picks it up and updates DocumentDB
```

**What It Touches**:
- **Reads from**: On-premises OpsHub MQ queues
- **Writes to**: NXOP MSK topics
- **Protocol**: IBM MQ → Kafka

**Why It Matters**: Legacy on-prem systems can't be moved to cloud immediately. This brings their data into NXOP.

**Technical Details**:
- **Connection**: Direct Connect (dedicated network link between on-prem and AWS)
- **Security**: TLS encryption, IP allowlists
- **Reliability**: Guaranteed message delivery (no data loss)

---

### 11. Vendor RabbitMQ Processor (FlightKeys)
**Simple Explanation**: Listens to FlightKeys vendor system and brings flight planning data into NXOP

**Real-World Example**:
```
FlightKeys (external vendor) publishes flight plan:
"Flight AA100: Route DFW→JFK, altitude 35,000 ft, fuel 12,000 lbs"

This processor:
1. Connects to FlightKeys RabbitMQ broker (vendor's message system)
2. Consumes flight planning messages
3. Validates and transforms the data
4. Publishes to MSK topic "flight-event-aa-flightplan-avro"
```

**What It Touches**:
- **Reads from**: FlightKeys RabbitMQ queues (external vendor)
- **Writes to**: MSK topics (flight-event-*)
- **Data**: Flight plans, routes, fuel calculations, weather

**Why It Matters**: FlightKeys is a critical vendor for flight planning. If this breaks, flight plans don't make it into NXOP.

**Technical Details**:
- **Protocol**: AMQP (RabbitMQ)
- **Connection**: HTTPS with TLS
- **Authentication**: OAuth 2.0 client credentials
- **Failover**: Vienna DR endpoints for disaster recovery

---

### 12. Vendor RabbitMQ Processor (CyberJet FMS)
**Simple Explanation**: Listens to CyberJet FMS vendor system and brings flight management data into NXOP

**Real-World Example**:
```
CyberJet FMS (Flight Management System) sends update:
"Flight AA100: Current position 35.5°N, 97.2°W, ETA JFK 4:30 PM"

This processor:
1. Connects to CyberJet FMS RabbitMQ broker
2. Consumes flight management messages
3. Validates and transforms the data
4. Publishes to MSK topic "flight-event-aa-misc-avro"
```

**What It Touches**:
- **Reads from**: CyberJet FMS RabbitMQ queues (external vendor)
- **Writes to**: MSK topics (flight-event-*)
- **Data**: In-flight updates, position reports, ETA calculations

**Why It Matters**: CyberJet FMS provides real-time flight management data. If this breaks, you lose visibility of in-flight operations.

**Technical Details**:
- **Protocol**: AMQP (RabbitMQ)
- **Connection**: HTTPS with TLS
- **Authentication**: OAuth 2.0 client credentials
- **Frequency**: Updates every few minutes during flight

---


## Category 3: Integration Services (4 services)
### "The Orchestrators and Workflow Managers"

**What They Do**: Integration services handle complex workflows that involve multiple steps and systems. Like a project manager who coordinates different teams.

---

### 13. Flightkeys Integration Service
**Simple Explanation**: Assembles pilot briefing packages and handles electronic signatures

**Real-World Example - Pilot Briefing Package**:
```
Pilot needs briefing for Flight AA100:

This service orchestrates:
1. Calls Flight Plan Service → Gets flight plan from DocumentDB
2. Calls Pilot Document Service → Gets pilot-specific docs from S3
3. Retrieves weather data from DocumentDB
4. Retrieves airport charts from S3
5. Assembles everything into one PDF package
6. Delivers to pilot's iPad via CCI (Crew Check-In) app

It's like a personal assistant gathering all documents for a meeting.
```

**Real-World Example - Electronic Signature**:
```
Pilot needs to sign flight release:

This service:
1. Receives eSignature request from Flightkeys
2. Sends notification to pilot's iPad (CCI app)
3. Pilot reviews and signs electronically
4. Validates signature
5. Forwards signed release to FOS systems
6. Updates flight status to "Released"

It's like DocuSign for flight operations.
```

**What It Touches**:
- **Calls**: Flight Plan Service, Pilot Document Service
- **Reads from**: DocumentDB (flight data, crew data)
- **Reads from**: S3 (documents, charts, weather maps)
- **Integrates with**: CCI (Crew Check-In) on Azure, FOS systems
- **Exposes**: HTTPS APIs via Akamai GTM

**Why It Matters**: Pilots can't fly without proper briefing and signed release. If this breaks, flights get delayed.

**Technical Details**:
- **API Gateway**: Akamai GTM (global traffic management)
- **Authentication**: OAuth 2.0 + Ping Identity SSO
- **Document Assembly**: Combines multiple PDFs into single package
- **eSignature**: Compliant with FAA regulations

---

### 14. LCA Flight Update Proxy
**Simple Explanation**: Forwards signed flight releases to legacy FOS systems

**Real-World Example**:
```
Flight AA100 is released by pilot:

This proxy:
1. Receives signed flight release from Flightkeys Integration Service
2. Validates the signature and authorization
3. Transforms data to FOS format (legacy system format)
4. Forwards to FOS via HTTPS
5. FOS distributes to:
   - Crew Management system
   - Load Planning system
   - Takeoff Performance system
   - Other legacy systems

It's like a translator and courier for legacy systems.
```

**What It Touches**:
- **Receives from**: Flightkeys Integration Service
- **Sends to**: FOS (Future of Operations Solutions) on-premises
- **Protocol**: HTTPS with TLS
- **Data**: Flight releases, authorizations, crew updates

**Why It Matters**: Legacy FOS systems need flight release data. If this breaks, legacy systems don't get updates, causing operational issues.

**Technical Details**:
- **Connection**: Direct Connect to on-premises
- **Security**: mTLS (mutual TLS), IP allowlists
- **Retry Logic**: Automatic retries on failure
- **Monitoring**: Alerts if FOS unreachable

---

### 15. Flight Plan Service
**Simple Explanation**: Manages flight plan data and provides APIs for retrieval

**Real-World Example**:
```
Dispatcher creates flight plan for AA100:
- Route: DFW → JFK
- Altitude: 35,000 ft
- Fuel: 12,000 lbs
- Alternate airports: PHL, EWR
- Flight time: 3 hours 15 minutes

This service:
1. Stores flight plan in DocumentDB
2. Provides API for other services to retrieve it
3. Validates flight plan data
4. Tracks flight plan versions (if dispatcher makes changes)
```

**What It Touches**:
- **Reads/Writes**: DocumentDB (FlightPlan collection)
- **Exposes**: HTTPS APIs for flight plan retrieval
- **Used by**: Flightkeys Integration Service, Pilot Document Service, other services

**Why It Matters**: Flight plans are critical for safe operations. If this breaks, pilots can't get flight plans.

**Technical Details**:
- **API**: RESTful HTTPS APIs
- **Data Format**: JSON
- **Caching**: In-memory cache for frequently accessed plans
- **Versioning**: Tracks changes to flight plans

---

### 16. Pilot Document Service
**Simple Explanation**: Manages pilot-specific documents and retrieves them from S3

**Real-World Example**:
```
Pilot John Smith needs documents for Flight AA100:

This service:
1. Looks up pilot's credentials in DocumentDB
2. Retrieves pilot-specific documents from S3:
   - Pilot license
   - Medical certificate
   - Training records
   - Airport authorizations (which airports pilot is qualified for)
3. Retrieves flight-specific documents:
   - Airport charts for DFW and JFK
   - Approach plates
   - Weather briefing
4. Returns all documents to Flightkeys Integration Service

It's like a librarian who knows exactly which books you need.
```

**What It Touches**:
- **Reads from**: DocumentDB (pilot credentials, document metadata)
- **Reads from**: S3 (actual document files - PDFs, charts)
- **Exposes**: HTTPS APIs for document retrieval
- **Used by**: Flightkeys Integration Service

**Why It Matters**: Pilots need specific documents for each flight. If this breaks, pilots can't get required documents, delaying flights.

**Technical Details**:
- **Storage**: S3 with MRAP (Multi-Region Access Points)
- **Document Types**: PDFs, images, charts
- **Caching**: CloudFront CDN for frequently accessed documents
- **Security**: Encrypted at rest and in transit

---


## Category 4: API Services (3 services)
### "The Information Providers"

**What They Do**: API services expose HTTPS endpoints that external systems can call to get data. Like a help desk that answers questions.

---

### 17. Nav Data Service
**Simple Explanation**: Provides navigation data APIs for flight planning

**Real-World Example**:
```
Ops Engineering Client App (on-premises) needs navigation data:

Request: "Give me navigation data for route DFW → JFK"

This service:
1. Receives HTTPS request via Akamai GTM
2. Queries DocumentDB for navigation waypoints
3. Returns data:
   - Waypoints: DFW → TUL → STL → IND → PIT → JFK
   - Coordinates for each waypoint
   - Magnetic headings
   - Distances between waypoints
   - Airway identifiers (like highway numbers)

It's like Google Maps for airplanes.
```

**What It Touches**:
- **Reads from**: DocumentDB (navigation data)
- **Exposes**: HTTPS APIs via Akamai GTM
- **Serves**: On-prem Ops Engineering Client Apps
- **Data**: Waypoints, airways, coordinates, headings

**Why It Matters**: Flight planning requires accurate navigation data. If this breaks, dispatchers can't plan routes.

**Technical Details**:
- **API**: RESTful HTTPS
- **Authentication**: OAuth 2.0
- **Rate Limiting**: Prevents abuse
- **Caching**: Frequently requested routes cached

---

### 18. Fuel Data Service
**Simple Explanation**: Provides fuel planning data APIs

**Real-World Example**:
```
Ops Engineering Client App needs fuel calculation:

Request: "How much fuel for Flight AA100 (DFW → JFK)?"

This service:
1. Receives HTTPS request via Akamai GTM
2. Queries DocumentDB for:
   - Aircraft type (Boeing 737-800)
   - Route distance (1,391 miles)
   - Weather (headwinds, temperature)
   - Alternate airports (PHL, EWR)
3. Calculates fuel required:
   - Trip fuel: 10,500 lbs
   - Reserve fuel: 1,200 lbs
   - Alternate fuel: 800 lbs
   - Contingency: 500 lbs
   - Total: 13,000 lbs
4. Returns fuel plan

It's like a fuel calculator that considers all factors.
```

**What It Touches**:
- **Reads from**: DocumentDB (fuel data, aircraft performance, weather)
- **Exposes**: HTTPS APIs via Akamai GTM
- **Serves**: On-prem Ops Engineering Client Apps
- **Data**: Fuel requirements, aircraft performance, weather factors

**Why It Matters**: Accurate fuel planning is critical for safety and cost. Too little fuel is dangerous, too much wastes money.

**Technical Details**:
- **API**: RESTful HTTPS
- **Calculations**: Complex algorithms considering weather, weight, altitude
- **Real-time**: Weather data updated continuously
- **Compliance**: FAA fuel reserve requirements

---

### 19. Data Maintenance Service
**Simple Explanation**: Handles special information messages and operational data updates

**Real-World Example**:
```
Operations needs to send special message to Flightkeys:

Message: "Runway 18R at DFW closed for maintenance until 6 PM"

This service:
1. Receives message from operations team
2. Validates the message format
3. Sends to Flightkeys via HTTPS
4. Flightkeys distributes to:
   - Dispatchers (so they don't plan flights using that runway)
   - Pilots (so they know about the closure)
   - Ground operations (so they adjust gate assignments)

It's like a broadcast system for important operational messages.
```

**What It Touches**:
- **Receives from**: Operations teams (web UI or API)
- **Sends to**: Flightkeys system
- **Data**: Special messages, NOTAMs (Notices to Airmen), operational updates

**Why It Matters**: Critical operational information needs to reach everyone quickly. If this breaks, important messages don't get distributed.

**Technical Details**:
- **API**: RESTful HTTPS
- **Message Types**: NOTAMs, runway closures, weather alerts, operational changes
- **Priority Levels**: Critical, high, medium, low
- **Delivery**: Guaranteed delivery with acknowledgment

---


## Category 5: Specialized Services (2 services)
### "The Specialists"

**What They Do**: Handle specific operational workflows that don't fit other categories.

---

### 20. Terminal Area Forecast UI
**Simple Explanation**: Manages weather forecast data for airports

**Real-World Example**:
```
Weather forecaster updates TAF (Terminal Area Forecast) for DFW:

Original forecast: "Clear skies, winds 10 knots"
Updated forecast: "Thunderstorms expected 3-5 PM, winds 25 knots gusting 40"

This service:
1. Provides web interface for forecasters
2. Forecaster enters updated TAF
3. Validates the forecast format
4. Sends to Flightkeys via HTTPS
5. Flightkeys distributes to:
   - Dispatchers (may need to delay flights)
   - Pilots (need to know about weather)
   - Ground operations (may need to secure equipment)

If forecast is deleted (weather improved):
1. Forecaster deletes TAF
2. Service sends TAF deletion to Flightkeys
3. Everyone knows the bad weather forecast is cancelled

It's like a weather bulletin board for aviation.
```

**What It Touches**:
- **Provides**: Web UI for forecasters
- **Reads/Writes**: DocumentDB (TAF data)
- **Sends to**: Flightkeys system
- **Data**: Terminal Area Forecasts, weather updates, deletions

**Why It Matters**: Weather is critical for flight safety. Pilots and dispatchers need accurate, timely weather information.

**Technical Details**:
- **UI**: Web-based interface
- **Authentication**: Ping Identity SSO (only authorized forecasters)
- **Format**: Standard TAF format (aviation weather format)
- **Real-time**: Updates distributed immediately

---

### 21. Notification Service
**Simple Explanation**: Sends operational alerts to people who need to know

**Real-World Example**:
```
Critical event: Aircraft N12345 has maintenance issue

This service:
1. Detects critical event from MSK
2. Determines who needs to be notified:
   - Maintenance team (need to fix it)
   - Dispatcher (may need to swap aircraft)
   - Crew scheduler (may need to reassign crew)
   - Operations manager (needs to know)
3. Sends notifications:
   - Email to maintenance team
   - SMS to on-call dispatcher
   - Push notification to operations manager's phone
   - Alert in operations dashboard

It's like an emergency broadcast system for operations.
```

**What It Touches**:
- **Reads from**: MSK topics (monitoring for critical events)
- **Sends via**: Email (SMTP), SMS (Twilio), Push notifications (mobile apps)
- **Integrates with**: PagerDuty (for on-call escalation)

**Why It Matters**: Critical events need immediate attention. If this breaks, people don't get alerted to problems.

**Technical Details**:
- **Event Types**: 
  - Critical: Aircraft issues, safety concerns (immediate notification)
  - High: Delays, cancellations (5-minute notification)
  - Medium: Schedule changes (15-minute notification)
  - Low: Informational updates (hourly digest)
- **Escalation**: If no response, escalates to manager
- **Channels**: Email, SMS, push, PagerDuty, Slack
- **Filtering**: Users can configure which alerts they receive

---


## Admin Tools (6 tools)
### "The Management and Monitoring Tools"

**What They Do**: Help operators manage, monitor, and troubleshoot the NXOP platform.

---

### 1. NXOP Admin Web UI
**Simple Explanation**: Main dashboard for platform administration

**What You Can Do**:
- View system health (all services running?)
- See current traffic (how many messages per second?)
- Manage user access (who can do what?)
- View recent errors and warnings
- Trigger manual operations (like data reconciliation)

**Real-World Example**:
```
Platform operator logs in:

Dashboard shows:
- ✅ All 21 microservices: Healthy
- ✅ MSK: 5,000 messages/second
- ✅ DocumentDB: 2,000 writes/second
- ⚠️ Flight Data Adapter: High latency (3 seconds)
- ❌ Crew Data Adapter: Connection error to FXIP

Operator clicks on Crew Data Adapter:
- Sees error: "Connection timeout to Azure EventHub"
- Checks recent changes: "FXIP IP address changed"
- Updates IP allowlist
- Service recovers

It's like a car dashboard showing engine status, fuel, speed, warnings.
```

**Who Uses It**: Platform operators, on-call engineers, managers

---

### 2. Schema Registry UI
**Simple Explanation**: Manages data schemas (the structure of messages)

**What You Can Do**:
- View all schemas (what fields are in each message type?)
- See schema versions (how has the schema changed over time?)
- Validate new schemas (will this change break anything?)
- Approve schema changes (who approved this change?)

**Real-World Example**:
```
Developer wants to add new field to flight event:

Current schema:
{
  "flightNumber": "AA100",
  "departureTime": "2026-02-08T14:00:00Z",
  "arrivalTime": "2026-02-08T17:15:00Z"
}

Proposed new schema:
{
  "flightNumber": "AA100",
  "departureTime": "2026-02-08T14:00:00Z",
  "arrivalTime": "2026-02-08T17:15:00Z",
  "estimatedFuelBurn": 12000  ← NEW FIELD
}

Schema Registry UI:
1. Developer uploads new schema
2. System validates: "Compatible with existing consumers"
3. Data steward reviews and approves
4. New schema version deployed
5. All services automatically use new schema

It's like a blueprint library for data structures.
```

**Who Uses It**: Developers, data stewards, architects

---

### 3. Data Catalog UI
**Simple Explanation**: Helps you discover and understand data

**What You Can Do**:
- Search for data ("Where is flight departure time stored?")
- See data lineage (where does this data come from? where does it go?)
- View data quality metrics (how accurate is this data?)
- Find data owners (who do I ask about this data?)

**Real-World Example**:
```
New developer needs to find aircraft location data:

Searches: "aircraft location"

Results:
1. DocumentDB Collection: AircraftLocation
   - Fields: tailNumber, latitude, longitude, altitude, speed
   - Updated by: Aircraft Data Adapter
   - Update frequency: Every 2 minutes
   - Data owner: Fleet Management team
   - Quality score: 99.8%

2. MSK Topic: aircraft-location-avro
   - Real-time aircraft position updates
   - Producers: Vendor RabbitMQ Processor (CyberJet FMS)
   - Consumers: Aircraft Data Adapter, Monitoring Dashboard
   - Message rate: 500/minute

It's like a search engine for data.
```

**Who Uses It**: Developers, analysts, data stewards, new team members

---

### 4. Monitoring Dashboard
**Simple Explanation**: Real-time operational metrics and alerts

**What You Can See**:
- Message flow rates (messages per second for each topic)
- Service health (CPU, memory, response time for each service)
- Error rates (how many errors per service?)
- Data quality metrics (schema validation pass rate)
- Infrastructure health (MSK, DocumentDB, S3 status)

**Real-World Example**:
```
Operations team monitors dashboard:

Normal day:
- Flight Data Adapter: 1,000 msg/sec, 0.5s latency ✅
- Aircraft Data Adapter: 500 msg/sec, 0.3s latency ✅
- MSK: 5,000 msg/sec total, 0 errors ✅

Suddenly:
- Flight Data Adapter: 100 msg/sec, 5s latency ⚠️
- MSK: 5,000 msg/sec, 0 errors ✅

Alert: "Flight Data Adapter processing slowdown"

Team investigates:
- DocumentDB is slow (high CPU)
- Recent deployment increased query complexity
- Rollback deployment
- Service recovers

It's like a mission control center for the platform.
```

**Who Uses It**: Operations team, on-call engineers, managers

**Integrations**:
- Dynatrace (APM monitoring)
- CloudWatch (AWS metrics)
- Mezmo (log aggregation)
- PagerDuty (alerting)

---

### 5. Reconciliation Tool
**Simple Explanation**: Compares data between systems to find discrepancies

**What You Can Do**:
- Compare NXOP vs FXIP data (during migration)
- Find missing records (did any data get lost?)
- Find duplicate records (did any data get duplicated?)
- Generate reconciliation reports (what's different?)

**Real-World Example**:
```
During Phase 3 migration, need to verify data sync:

Reconciliation Tool runs:

Comparing Flight Data:
- NXOP DocumentDB: 6,847 flights
- FXIP MongoDB: 6,850 flights
- Difference: 3 flights missing in NXOP ⚠️

Missing flights:
- AA1234 (DFW → LAX)
- AA5678 (ORD → MIA)
- AA9012 (JFK → SFO)

Investigation:
- These flights were added to FXIP during migration window
- EventHub → MSK connector was briefly down
- Re-sync these 3 flights manually
- Verify: Now both systems have 6,850 flights ✅

It's like an accountant reconciling bank statements.
```

**Who Uses It**: Data engineers, migration team, data stewards

**During Migration**:
- Critical for Phases 1-3 (ensuring NXOP and FXIP stay in sync)
- Runs automatically every hour
- Alerts if discrepancies exceed threshold

---

### 6. Migration Control Panel
**Simple Explanation**: Manages the cut-over process from FXIP to NXOP

**What You Can Do**:
- View migration status (which phase are we in?)
- Execute cut-over steps (DNS changes, routing updates)
- Monitor cut-over progress (real-time status)
- Trigger rollback (if something goes wrong)
- Generate cut-over reports (what happened during cut-over?)

**Real-World Example**:
```
Phase 3 cut-over night:

Migration Control Panel shows:

Pre-Cut-over Checklist:
✅ All 21 microservices healthy
✅ Data reconciliation passed (0 discrepancies)
✅ Rollback procedures tested
✅ Stakeholder approval obtained
✅ Communication sent to all teams

Cut-over Steps:
1. ⏳ Update Akamai GTM DNS → NXOP (in progress)
2. ⏸️ Update Route 53 DNS → NXOP (waiting)
3. ⏸️ Update Apigee routing → NXOP (waiting)
4. ⏸️ Update IP allowlists (waiting)
5. ⏸️ Validate all flows (waiting)

Step 1 completes:
✅ Akamai GTM updated (5 minutes)
✅ DNS propagation verified
✅ Test traffic flowing to NXOP

Proceed to Step 2...

If error occurs:
❌ Step 3 failed: "Apigee routing error"
🔄 Rollback initiated
⏪ Reverting to FXIP
✅ Rollback complete (10 minutes)

It's like a flight checklist for the migration.
```

**Who Uses It**: Migration team lead, platform architects, operations manager

**Features**:
- **Step-by-step execution**: Can't skip steps
- **Validation gates**: Each step validates before proceeding
- **Rollback**: One-click rollback at any point
- **Audit trail**: Complete log of who did what when
- **Real-time status**: Live updates during cut-over

---


## External Systems Explained
### "The Systems NXOP Talks To"

These systems are NOT part of NXOP, but NXOP integrates with them.

---

### Vendor Systems (External Companies)

#### FlightKeys (AWS)
**What It Is**: Flight planning and crew integration system (external vendor)  
**What It Does**: 
- Flight planning and optimization
- Crew scheduling and assignments
- Pilot briefing packages
- Flight release management

**How NXOP Integrates**:
- Receives flight events via RabbitMQ (AMQP)
- Sends flight data via HTTPS APIs
- Bidirectional communication

**Real-World Example**: Dispatcher creates flight plan in FlightKeys → FlightKeys sends to NXOP → NXOP distributes to other systems

---

#### CyberJet FMS (AWS)
**What It Is**: Flight Management System (external vendor)  
**What It Does**:
- In-flight navigation and guidance
- Real-time position tracking
- ETA calculations
- Fuel burn monitoring

**How NXOP Integrates**:
- Receives flight management data via RabbitMQ (AMQP)
- Sends flight plans via HTTPS APIs

**Real-World Example**: Aircraft sends position update to CyberJet FMS → CyberJet sends to NXOP → NXOP updates aircraft location in DocumentDB

---

#### IBM Fusion Flight Tracking (AWS)
**What It Is**: Flight tracking and monitoring system (external vendor)  
**What It Does**:
- Real-time flight tracking
- Flight status updates
- Delay predictions
- Historical flight data

**How NXOP Integrates**:
- Bidirectional HTTPS APIs
- Sends flight plans and updates
- Receives flight tracking data

**Real-World Example**: NXOP sends flight plan to IBM Fusion → IBM Fusion tracks flight → Sends updates back to NXOP

---

#### Vienna DR (Disaster Recovery)
**What It Is**: Disaster recovery endpoints for vendor systems  
**What It Does**:
- Backup endpoints if primary vendor systems fail
- Located in Vienna, Austria (geographic diversity)

**How NXOP Integrates**:
- Same protocols as primary endpoints
- Activated during Phase 1 (NXOP becomes BCP)
- Failover if primary endpoints unavailable

---

### Internal Systems (American Airlines Owned)

#### FOS (Future of Operations Solutions)
**What It Is**: Legacy on-premises systems  
**What It Does**:
- Load planning (how to load cargo and passengers)
- Takeoff performance calculations
- Crew management
- Various operational systems

**Why Still On-Premises**: Too complex/risky to move to cloud immediately

**How NXOP Integrates**:
- Receives data via IBM MQ (legacy messaging)
- Sends data via HTTPS APIs
- LCA Flight Update Proxy handles communication

**Real-World Example**: Pilot signs flight release in NXOP → LCA Flight Update Proxy sends to FOS → FOS distributes to crew management, load planning, etc.

---

#### OpsHub (Azure + On-Premises)
**What It Is**: Integration hub connecting various systems  
**What It Does**:
- Message routing between systems
- Protocol translation
- Legacy system integration

**Why It Exists**: Many legacy systems can't talk directly to modern systems

**How NXOP Integrates**:
- Bidirectional via IBM MQ
- MSK → MQ Adapter (NXOP → OpsHub)
- MQ → MSK Adapter (OpsHub → NXOP)

**Real-World Example**: On-prem maintenance system sends update to OpsHub → OpsHub sends to NXOP via MQ → NXOP processes and stores in DocumentDB

---

#### CCI (Crew Check-In) on Azure FXIP
**What It Is**: Mobile/web app for pilots and flight attendants  
**What It Does**:
- Crew check-in for flights
- View flight assignments
- Receive briefing packages
- Electronic signature for flight releases

**How NXOP Integrates**:
- Calls NXOP APIs via Apigee
- Receives briefing packages from Flightkeys Integration Service
- Sends eSignatures back to NXOP

**Real-World Example**: Pilot opens CCI app → Sees Flight AA100 assignment → Requests briefing package → NXOP assembles and delivers → Pilot reviews and signs → Signature sent back to NXOP

---

#### AIRCOM Server (On-Premises)
**What It Is**: Aircraft communications server  
**What It Does**:
- ACARS (Aircraft Communications Addressing and Reporting System)
- Sends messages to/from aircraft
- Position reports, weather updates, operational messages

**How NXOP Integrates**:
- Receives ACARS messages via TCP
- Sends messages to aircraft via ACARS

**Real-World Example**: Dispatcher sends gate change to aircraft → NXOP sends to AIRCOM → AIRCOM transmits via ACARS → Pilots receive message in cockpit

---

#### Ops Engineering Client Apps (On-Premises)
**What It Is**: Desktop applications used by operations teams  
**What It Does**:
- Flight planning tools
- Navigation data management
- Fuel planning
- Operational dashboards

**How NXOP Integrates**:
- Calls NXOP APIs (Nav Data Service, Fuel Data Service)
- Receives operational data

**Real-World Example**: Dispatcher uses desktop app to plan route → App calls NXOP Nav Data Service → NXOP returns waypoints and navigation data → Dispatcher sees route on map

---

### Infrastructure Services (Shared Services)

#### Akamai GTM (Global Traffic Manager)
**What It Is**: Global load balancer and traffic manager  
**What It Does**:
- Routes traffic to nearest/healthiest region
- DDoS protection
- SSL/TLS termination
- Caching

**How NXOP Uses It**: All external HTTPS APIs go through Akamai

---

#### InfoBlox
**What It Is**: DNS management system  
**What It Does**:
- Internal DNS resolution
- IP address management
- DNS security

**How NXOP Uses It**: Internal service discovery and DNS

---

#### Apigee
**What It Is**: API gateway and management platform  
**What It Does**:
- API authentication and authorization
- Rate limiting
- API analytics
- Protocol translation

**How NXOP Uses It**: All external API calls go through Apigee

---

#### Ping Identity + Entra ID (Azure AD)
**What It Is**: Identity and access management  
**What It Does**:
- Single Sign-On (SSO)
- User authentication
- Role-based access control (RBAC)

**How NXOP Uses It**: All admin tools and APIs use SSO

---

#### HashiCorp Vault
**What It Is**: Secrets management system  
**What It Does**:
- Stores passwords, API keys, certificates
- Secret rotation
- Access control

**How NXOP Uses It**: Secrets replicated from Vault to AWS Secrets Manager

---

#### Dynatrace
**What It Is**: Application Performance Monitoring (APM)  
**What It Does**:
- Service monitoring
- Performance metrics
- Distributed tracing
- Anomaly detection

**How NXOP Uses It**: Monitors all 21 microservices

---

#### Mezmo
**What It Is**: Log aggregation and analysis  
**What It Does**:
- Collects logs from all services
- Log search and analysis
- Log-based alerting

**How NXOP Uses It**: All service logs sent to Mezmo

---

#### PagerDuty
**What It Is**: Incident management and alerting  
**What It Does**:
- On-call scheduling
- Alert escalation
- Incident tracking

**How NXOP Uses It**: Critical alerts trigger PagerDuty incidents

---


## How They All Work Together
### "The Complete Picture"

Let's walk through a complete real-world scenario to see how all these services work together.

---

### Scenario: Flight AA100 from Dallas (DFW) to New York (JFK)

#### Step 1: Flight Planning (Morning - 6 hours before departure)

**Dispatcher creates flight plan in FlightKeys**:

```
1. Dispatcher logs into FlightKeys system
2. Creates flight plan:
   - Flight: AA100
   - Route: DFW → JFK
   - Departure: 2:00 PM
   - Aircraft: N12345 (Boeing 737-800)
   - Crew: Captain John Smith, FO Jane Doe, 4 FAs

3. FlightKeys publishes event to RabbitMQ
   ↓
4. Vendor RabbitMQ Processor (FlightKeys) consumes event
   ↓
5. Publishes to MSK topic "flight-event-aa-flightplan-avro"
   ↓
6. Flight Data Adapter consumes from MSK
   ↓
7. Updates DocumentDB:
   - FlightPlan collection: Route, fuel, timing
   - FlightLeg collection: DFW → JFK leg details
   - FlightTimes collection: Scheduled times
   ↓
8. Sends notification to Flightkeys via HTTPS
   ↓
9. Notification Service detects new flight
   ↓
10. Sends email to crew: "You're assigned to AA100"
```

**Services Involved**:
- Vendor RabbitMQ Processor (FlightKeys)
- Flight Data Adapter
- Notification Service

**Data Stores**:
- MSK topics
- DocumentDB (FlightPlan, FlightLeg, FlightTimes)

---

#### Step 2: Crew Check-In (2 hours before departure)

**Pilot checks in via CCI app**:

```
1. Captain John Smith opens CCI app on iPad
2. Sees Flight AA100 assignment
3. Clicks "Request Briefing Package"
   ↓
4. CCI calls NXOP API via Apigee
   ↓
5. Flightkeys Integration Service receives request
   ↓
6. Orchestrates briefing package assembly:
   
   a. Calls Flight Plan Service
      → Queries DocumentDB for flight plan
      → Returns route, fuel, timing
   
   b. Calls Pilot Document Service
      → Queries DocumentDB for pilot credentials
      → Retrieves from S3:
        - Pilot license
        - Medical certificate
        - Airport charts (DFW, JFK)
        - Approach plates
   
   c. Retrieves weather data from DocumentDB
      → Current weather at DFW and JFK
      → Forecast for departure and arrival times
   
   d. Assembles complete PDF package
   
7. Delivers briefing package to CCI app
8. Captain reviews briefing package
9. Clicks "Sign Flight Release"
   ↓
10. Flightkeys Integration Service validates signature
    ↓
11. LCA Flight Update Proxy forwards to FOS
    ↓
12. FOS distributes to:
    - Crew Management (crew confirmed)
    - Load Planning (can start loading)
    - Takeoff Performance (calculate takeoff data)
```

**Services Involved**:
- Flightkeys Integration Service
- Flight Plan Service
- Pilot Document Service
- LCA Flight Update Proxy

**Data Stores**:
- DocumentDB (FlightPlan, pilot credentials, weather)
- S3 (documents, charts)

---

#### Step 3: Pre-Departure Updates (30 minutes before departure)

**Gate change and aircraft swap**:

```
1. Operations decides to change gate and aircraft:
   - Old gate: D15 → New gate: D18
   - Old aircraft: N12345 → New aircraft: N67890
   
2. Operations updates in FlightKeys
   ↓
3. FlightKeys publishes event to RabbitMQ
   ↓
4. Flightkeys Event Processor consumes event
   ↓
5. Publishes to MSK topic "flight-event-aa-misc-avro"
   ↓
6. Flight Data Adapter consumes from MSK
   ↓
7. Updates DocumentDB:
   - FlightLeg: New gate D18
   - FlightTimes: Updated departure time
   ↓
8. Aircraft Data Adapter detects aircraft change
   ↓
9. Updates DocumentDB:
   - AircraftIdentity: N67890 now assigned to AA100
   ↓
10. Notification Service detects critical change
    ↓
11. Sends notifications:
    - SMS to crew: "Gate changed to D18"
    - Email to ground ops: "Aircraft swapped to N67890"
    - Push notification to operations manager
    ↓
12. Data Maintenance Service sends special message
    ↓
13. Sends to Flightkeys: "AA100 gate change D15 → D18"
    ↓
14. Flightkeys distributes to all systems
```

**Services Involved**:
- Flightkeys Event Processor
- Flight Data Adapter
- Aircraft Data Adapter
- Notification Service
- Data Maintenance Service

**Data Stores**:
- MSK topics
- DocumentDB (FlightLeg, FlightTimes, AircraftIdentity)

---

#### Step 4: Departure (2:00 PM)

**Flight departs DFW**:

```
1. Aircraft N67890 pushes back from gate D18
2. CyberJet FMS (onboard system) sends position update
   ↓
3. Vendor RabbitMQ Processor (CyberJet FMS) receives update
   ↓
4. Publishes to MSK topic "aircraft-location-avro"
   ↓
5. Aircraft Data Adapter consumes from MSK
   ↓
6. Updates DocumentDB:
   - AircraftLocation: Lat/Long, altitude, speed
   - AircraftPerformance: Fuel burn, ETA
   ↓
7. IBM Fusion Flight Tracking receives update via HTTPS
   ↓
8. Tracks flight in real-time
```

**Services Involved**:
- Vendor RabbitMQ Processor (CyberJet FMS)
- Aircraft Data Adapter

**Data Stores**:
- MSK topics
- DocumentDB (AircraftLocation, AircraftPerformance)

---

#### Step 5: In-Flight Updates (Every 2 minutes)

**Aircraft sends position reports**:

```
1. CyberJet FMS sends position update every 2 minutes
   ↓
2. Vendor RabbitMQ Processor (CyberJet FMS) receives
   ↓
3. Publishes to MSK
   ↓
4. Aircraft Data Adapter updates DocumentDB
   ↓
5. Operations Dashboard shows real-time position
   ↓
6. If delay detected:
   - Notification Service sends alert
   - "AA100 ETA delayed by 15 minutes"
```

**Continuous Updates**:
- Position (lat/long, altitude)
- Speed and heading
- Fuel remaining
- ETA to destination

---

#### Step 6: Arrival (5:15 PM)

**Flight arrives at JFK**:

```
1. Aircraft lands at JFK
2. CyberJet FMS sends arrival event
   ↓
3. Vendor RabbitMQ Processor (CyberJet FMS) receives
   ↓
4. Publishes to MSK topic "flight-event-aa-time-avro"
   ↓
5. Flight Data Adapter consumes from MSK
   ↓
6. Updates DocumentDB:
   - FlightTimes: Actual arrival time 5:15 PM
   - FlightLeg: Status = "Arrived"
   ↓
7. Notification Service sends notifications:
   - Email to crew: "AA100 arrived on time"
   - Update to operations dashboard
   ↓
8. LCA Flight Update Proxy sends to FOS
   ↓
9. FOS updates:
   - Crew Management (crew duty time)
   - Maintenance (flight hours logged)
```

**Services Involved**:
- Vendor RabbitMQ Processor (CyberJet FMS)
- Flight Data Adapter
- Notification Service
- LCA Flight Update Proxy

---

#### Step 7: Post-Flight (After arrival)

**Maintenance check**:

```
1. Maintenance team inspects aircraft N67890
2. Finds tire wear, needs replacement
3. Enters in on-prem maintenance system
   ↓
4. On-prem system sends to OpsHub via MQ
   ↓
5. On-Prem MQ → MSK Adapter receives
   ↓
6. Publishes to MSK topic "maintenance-event-avro"
   ↓
7. Maintenance Data Adapter consumes from MSK
   ↓
8. Updates DocumentDB:
   - Maintenance collection: Tire replacement needed
   - AircraftIdentity: Status = "Maintenance Required"
   ↓
9. Notification Service sends critical alert:
   - SMS to maintenance manager
   - Email to operations
   - "N67890 requires tire replacement before next flight"
   ↓
10. Operations removes N67890 from next flight assignment
```

**Services Involved**:
- On-Prem MQ → MSK Adapter
- Maintenance Data Adapter
- Notification Service

---

### Data Flow Summary

```
External Systems → Processors → MSK → Adapters → DocumentDB/S3
                                  ↓
                            Integration Services
                                  ↓
                            API Services → External Systems
                                  ↓
                            Notification Service → Users
```

---

### Key Takeaways

1. **Event-Driven Architecture**: Everything flows through MSK (Kafka)
   - Services publish events to MSK
   - Other services consume events from MSK
   - Decoupled: Services don't talk directly to each other

2. **Data Adapters**: Transform and route data
   - Read from MSK
   - Write to DocumentDB
   - Send to external systems

3. **Data Processors**: Bring external data into NXOP
   - Read from external systems (RabbitMQ, MQ, EventHub)
   - Publish to MSK
   - Bridge external → NXOP

4. **Integration Services**: Orchestrate complex workflows
   - Call multiple services
   - Assemble data from multiple sources
   - Handle multi-step processes

5. **API Services**: Expose data to external consumers
   - Provide HTTPS APIs
   - Query DocumentDB
   - Return data to callers

6. **Specialized Services**: Handle specific workflows
   - Weather forecasts
   - Notifications and alerts

7. **Admin Tools**: Manage and monitor the platform
   - Dashboards and monitoring
   - Schema management
   - Data reconciliation
   - Migration control

---

## Common Questions

### Q: Why so many services? Why not one big application?

**A**: Microservices architecture provides:
- **Scalability**: Scale individual services independently
- **Resilience**: If one service fails, others keep working
- **Flexibility**: Update one service without affecting others
- **Team Autonomy**: Different teams can work on different services
- **Technology Choice**: Use best technology for each service

**Example**: During peak hours, Flight Data Adapter might need 10 instances, but Notification Service only needs 2.

---

### Q: What happens if a service fails?

**A**: Multiple layers of protection:
1. **Retry Logic**: Automatic retries on transient failures
2. **Circuit Breakers**: Stop calling failed services
3. **Fallback**: Use cached data or alternative services
4. **Alerting**: PagerDuty alerts on-call engineer
5. **Auto-Restart**: Kubernetes automatically restarts failed pods
6. **Regional Failover**: Switch to other region if entire region fails

**Example**: If Flight Data Adapter fails:
- MSK keeps messages (won't lose data)
- Kubernetes restarts the service
- Service catches up on missed messages
- Total downtime: < 1 minute

---

### Q: How do services communicate?

**A**: Three main patterns:
1. **Asynchronous (MSK)**: For event-driven communication
   - Producer publishes to MSK
   - Consumer reads from MSK
   - Decoupled: Don't need to know about each other

2. **Synchronous (HTTPS APIs)**: For request-response
   - Caller makes HTTPS request
   - Service responds immediately
   - Used for queries and commands

3. **Message Queues (MQ, RabbitMQ)**: For legacy integration
   - Producer sends to queue
   - Consumer reads from queue
   - Guaranteed delivery

---

### Q: How is data kept consistent?

**A**: Multiple strategies:
1. **Event Sourcing**: All changes published as events
2. **Reconciliation**: Automated tools compare data between systems
3. **Transactions**: Database transactions ensure consistency
4. **Idempotency**: Processing same message multiple times has same effect
5. **Validation**: Schema validation ensures data quality

**Example**: If same flight update processed twice, second update is ignored (idempotent).

---

### Q: What about security?

**A**: Multiple layers:
1. **Authentication**: OAuth 2.0, Ping Identity SSO
2. **Authorization**: RBAC (Role-Based Access Control)
3. **Encryption**: TLS in transit, encryption at rest
4. **Secrets Management**: AWS Secrets Manager, HashiCorp Vault
5. **Network Security**: VPCs, security groups, IP allowlists
6. **Audit Logging**: All actions logged for compliance

---

### Q: How do you monitor 21 services?

**A**: Comprehensive observability:
1. **Metrics**: Dynatrace, CloudWatch (CPU, memory, latency, errors)
2. **Logs**: Mezmo (centralized log aggregation)
3. **Tracing**: Distributed tracing (follow request across services)
4. **Dashboards**: Real-time operational dashboards
5. **Alerting**: PagerDuty (critical alerts to on-call)
6. **SLOs**: Service Level Objectives (target performance)

---

## Glossary for Beginners

**API**: Application Programming Interface - how services talk to each other  
**AMQP**: Advanced Message Queuing Protocol - messaging protocol  
**Avro**: Binary data format (efficient for large volumes)  
**DocumentDB**: MongoDB-compatible database  
**EKS**: Elastic Kubernetes Service - runs containers  
**HTTPS**: Secure web protocol  
**Kafka/MSK**: Message streaming platform  
**Microservice**: Small, independent service doing one thing  
**MQ**: Message Queue - legacy messaging system  
**OAuth 2.0**: Authentication protocol  
**RabbitMQ**: Message broker  
**S3**: Object storage (like a file system)  
**SSO**: Single Sign-On - one login for all systems  
**TLS**: Transport Layer Security - encryption  

---

**Document End**

**Next Steps for New Team Members**:
1. Read this document thoroughly
2. Review the main technical guide (American-Airlines-NXOP-Migration-Phases-Technical-Guide.md)
3. Shadow an experienced team member
4. Start with monitoring dashboards to see services in action
5. Review code for 1-2 services to understand implementation
6. Attend daily standups and ask questions

**Welcome to the NXOP team!**
