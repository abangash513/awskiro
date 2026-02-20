## Slide 1

FOS Modernization -- Foundational Blueprint

Onboarding Materials

December 2025

## Table of Contents {#slide-2}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  1          Program context
  ---------- -------------------------------------------------
  2          Foundational blueprint roadmap and deliverables
  3          NXOP Charter
  3.1        Key principles and architecture
  3.2        Platform capabilities
  3.3        Capability sourcing
  3.4        Integration strategy
  3.5        Approach to optimizers
  3.6        Approach to analytics
  3.7        Production readiness checklists
  3.8        Service catalogue
  4          Roles and responsibilities
  Appendix   FXIP and ASM architectures

## Slide 3

Program context

1

## FOS is the backbone of our airline. It directly or indirectly impacts every team member.  {#slide-4}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Getting this right is not just important---it's essential.
  ------------------------------------------------------------

Flight Operating System (FOS) ecosystem

Non-exhaustive

![](ppt/media/image16.png "Picture 116")

Link to payroll system also included within Crew Pay functionality

Includes tail assignment, flight schedule changes, etc. 

  39 Core capabilities
  ----------------------------------------
  115+  Connected, downline apps
  Tens of Millions Transactions per year
  FAA System of record

![](ppt/media/image17.png "ico-bulb-63")

## Slide 5

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![](ppt/media/image20.jpeg "Picture 1")

- Solving for metal and crew

Limited real-time data connectivity

- Near-real time, Hub-level solvers

- Solving with expensive trade offs

<!-- -->

- Limited outcomes

- Limited cost-guided insights

FOS helped us grow to run the world's largest airline; we are facing new and different challenges than it was designed to address 50+ years ago

Today

## Slide 6

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![](ppt/media/image20.jpeg "Picture 1")

- Solving for itineraries and metal

- Passenger data to support customer experience

- Real-time, network-level solvers

Our Future

- Proactive seat and metal reallocations 

<!-- -->

- Leading customer, team member and operational outcomes

- Cost-influenced decision making

Sunsetting FOS and modernizing our operations will advance us towards our goal of delivering leading customer, team member, and operational outcomes

## The complexity of this modernization will require a phased transition, with first movers beginning in 2027 {#slide-7}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Not an architectural diagram . As of 12/2 -- subject to change

We will work with product teams and experts to design, test, and launch these capabilities, and will provide training and support to prepare for this transition to our new ecosystem

![](ppt/media/image28.png "ico-bulb-63")

2027+

2030+

Legend:

= Capabilities moving out of FOS

## The transition will occur incrementally over time until FOS is fully sunset in 2031 {#slide-8}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

As of 12/2 -- subject to change

- Co-create crew management and aircraft movement control systems

<!-- -->

- Build cloud architecture
- Complete contracting for all systems, including crew mgmt. and aircraft movement control 
- Begin implementation work for all systems

<!-- -->

- Go live of new Crew Pay, Load Planning System, and Takeoff Performance System
- Co-create crew management and aircraft movement control systems

<!-- -->

- Go live of aircraft movement control system 
- Crew and operations  ecosystem integration

Go live of crew management system

Fully sunset FOS

2031

2027

2030

2029

2028

2026

- Peripheral app relaunch
- Parallel run for one year

100%

% of capabilities currently on FOS migrated to the new platform

## Five workstreams will drive forward this modernization {#slide-9}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Architect:

Foundational build

Decommission:

FOS Decom

Assure:

Program assurance

Build: 

Process reimagination & system implementation

![](ppt/media/image51.png "ico-big-data")

- Define the  technical standards , blueprint, and procedures for the program
- Develop   data architecture  and  cloud infrastructure 
- Build foundational technology  (e.g., foundational data layer) required for future state ecosystem and vended solution integration
- 

<!-- -->

- Conduct  FOS discovery  work and  core logic detangling  to inform decommissioning strategy and overall roadmap / sequencing
- D evelop  decommission strategy  and execute transition of capabilities out of FOS
- Ultimately determine how FOS can be  safely unplugged

<!-- -->

- Manage timelines, program risks and dependencies
- Execute long-term governance strategy
- Coordinate with   Regionals  as part of modernization journey

<!-- -->

- Select, customize, and implement  all IOC / Ops and Crew  systems  that are needed to replace FOS functionality 
- Reintegrate existing systems and applications  that will persist in future state to new vended solutions and new foundational data layer

![](ppt/media/image53.png "ico-drone-2")

![](ppt/media/image55.png "ico-flight-connection")

![](ppt/media/image57.png "ico-meeting")

Enable:

Change management and talent alignment

- Drive  change management activities  including the development of key messaging and program structure
- Ensure the right skillsets are available  to achieve organizational goals and deliver against future requirements

![](ppt/media/image59.png "ico-b-comment")

## Slide 10

Foundational blueprint roadmap and deliverables

2

## Recap: 2H 2025 Foundational build milestones In 2H 2025, the Program will begin hands-on-keyboard development of the proposed NXOP architecture, while defining the end-state component design {#slide-11}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

2H 2025 FOS Program milestones 1

Architecture blueprint and foundation build

Q3/25

Q4/25

![](ppt/media/image61.png "ico-big-data")

ASM and FXIP tabletop validation completed

![](ppt/media/image63.png "ico-shape-star")

App migration & system integration frameworks created

![](ppt/media/image63.png "ico-shape-star")

Initial environment standards defined

![](ppt/media/image63.png "ico-shape-star")

Technology squads hired and onboarded

![](ppt/media/image63.png "ico-shape-star")

Begin NXOP build-out in development environment (AWS Control Tower)

![](ppt/media/image63.png "ico-shape-star")

![](ppt/media/image63.png "ico-shape-star")

Begin build-out of FXIP in development environment

![](ppt/media/image63.png "ico-shape-star")

Finish FXIP in dev environment

![](ppt/media/image63.png "ico-shape-star")

1. Exact milestones dependent on resource ramp-up for the Program

Completed milestones

Preliminary

![](ppt/media/image63.png "ico-shape-star")

Begin build-out of ASM in development environment

![](ppt/media/image63.png "ico-shape-star")

Develop foundational environments

## 2026 Foundational build milestones In 2026, Program focus will be on continued build-out of the NXOP, and commencing platform integration configurations for vendor systems to support their onboarding {#slide-12}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Preliminary

2026 FOS Program milestones 1

Q1/26

Q2/26

Q3/26

![](ppt/media/image61.png "ico-big-data")

FXIP and ASM transitioned to prod env. and ready for enterprise use

![](ppt/media/image63.png "ico-shape-star")

Cloud vendor contracting completed (To be confirmed)

![](ppt/media/image63.png "ico-shape-star")

Platform integration configuration with TPS and LPS systems commenced

![](ppt/media/image63.png "ico-shape-star")

Q4/26

![](ppt/media/image65.png "ico-flight-connection")

NXOP ready for integration with systems (in development environment) 

![](ppt/media/image63.png "ico-shape-star")

![](ppt/media/image65.png "ico-flight-connection")

Indicates cross-workstream collaboration w/ Systems workstream

Platform integration configuration with Pay system commenced

![](ppt/media/image63.png "ico-shape-star")

![](ppt/media/image65.png "ico-flight-connection")

Continuous testing of the NXOP platform build-out

![](ppt/media/image63.png "ico-shape-star")

1. Exact milestones dependent on resource ramp-up for the Program

Complete build-out of data  view with support from SaaS supplier

![](ppt/media/image63.png "ico-shape-star")

![](ppt/media/image65.png "ico-flight-connection")

Optimization workloads / strategy defined

![](ppt/media/image63.png "ico-shape-star")

![](ppt/media/image61.png "ico-big-data")

![](ppt/media/image63.png "ico-shape-star")

Finish ASM in dev env.

Vendor NFR evaluations Y1

![](ppt/media/image63.png "ico-shape-star")

## Q1 scorecard milestones Milestone statuses are tracked during weekly leadership team touchpoints {#slide-13}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Milestones                                       Target   Responsible                    Activities
  ------------------------------------------------ -------- ------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Develop FXIP in dev environment                  1/9      Infosys                        Develop 17 DFXIP microservices in dev environment Functionally test FXIP in dev environment
  Full non-prod environment ready                  1/13     ProServe                       Ensure non-prod environment supports application testing (e.g., integration, performance, load, chaos engr., etc.)
  Develop ASM  GraphQL  services in Dev            1/30     AA, Insights                   Develop all  GraphQL  service in the development environment
  Develop FinOps strategy                          2/13     AA                             Ensure budget estimates are reflected in  QuickSights  dashboard Clarify governance around FinOps management for NXOP
  Push FXIP to prod                                3/2      AA, Effectual-OW               Once FXIP is fully tested in non-prod and a hybrid DNS pattern / MSK authentication mechanism are implemented, FXIP will be pushed to the production environment
  Push ASM to prod                                 3/2      AA, Effectual-OW               Once ASM is fully tested in non-prod and a hybrid DNS pattern / MSK authentication mechanism are implemented, ASM will be pushed to the production environment
  Create state of the airline data feeds           3/13     AA                             Ensure data feeds required for operation applications are configured (e.g., Flight, weather, ADL, etc.)
  Initiate preparations for LPS integration        3/31     AA,  ProServe , Effectual-OW   Refine NXOP architecture to accommodate LPS vendor integration
  Initiate preparations for TPS integration        3/31     AA,  ProServe , Effectual-OW   Refine NXOP architecture to accommodate TPS vendor integration
  Initiate preparations for Crew Pay integration   3/31     AA,  ProServe , Effectual-OW   Refine NXOP architecture to accommodate Crew Pay vendor integration

## Q1 deliverables Designed to achieve scorecard milestones {#slide-14}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  ID    Objective / Description                                                                                                                                       Due Date     Acceptance Criteria           Medium            Dependencies                                                 Activities
  ----- ------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------ ----------------------------- ----------------- ------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  FB1   Deploy initial NXOP for FXIP and ASM into production                                                                                                          2026-03-02   AA Approval (Prem, Lakshmi)   PPT, Mural, IaC   AA Product Owner (NXOP), Infosys, AWS Pro Serve              OW and Effectual to drive requirements for production readiness for FXIP and ASM, ensuring go live activities are met (e.g., Chaos Engineering, Performance and Load testing, sufficient functional testing)  OW and Effectual working with existing product and technical teams incorporating their input OW and Effectual + AA deploying to production receiving production data running in parallel with existing product No cutover at this time; this is prep work
  FB2   System implementation impact to NXOP and AA downstream systems (OpsHub, Legacy Connector, etc., dependent) during FOS Decom transition and target end state   2026-03-31   AA Approval (Prem, Lakshmi)   PPT               System Implementation, FOS Decom, OpsHub, Legacy Connector   OW to perform a discovery and work with AA on architecture updates, and plan on the transitionary state given FOS decomm and System Implementation sequence  OW and AA developing a mapping of all applications dependent on FOS data (input and output) and how they are connected (e.g., via OpsHub, Legacy Connector, etc.)     
  FB3   First mover(s) view and impact on NXOP architecture                                                                                                           2026-03-31   AA Approval (Prem, Lakshmi)   PPT, Mural        System Implementation                                        OW and Effectual to advise in architecture discussions (platform & application) OW to create mural diagrams OW to provide inputs and review Guild presentation Effectual to collaborate with AA internal systems and provide Infrastructure-as-code changes for dev, stage / non-prod, and production environments

## Q1 deliverables Designed to achieve scorecard milestones {#slide-15}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  ID    Objective / Description                                                                                                              Due Date       Acceptance Criteria           Medium            Dependencies             Activities
  ----- ------------------------------------------------------------------------------------------------------------------------------------ -------------- ----------------------------- ----------------- ------------------------ ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  FB4   Chaos Engineering advisory and reporting and NXOP architectural changes for Initial Production workloads (FXIP and ASM)              2026-01-31     AA Approval (Lakshmi)         PPT, Mural, IaC   AWS Pro Serve, Infosys   OW and Effectual to advise, guide, monitor, and report on Chaos Engineering exercises, outputs OW and Effectual + AWS Pro Serve to advise and make HA / DR + architectural changes
  FB5   Performance and load testing advisory and reporting and NXOP architectural changes for Initial Production workloads (FXIP and ASM)   2026-01-31     AA Approval (Lakshmi)         PPT, Mural, IaC   AWS Pro Serve, Infosys   OW and Effectual to advise, guide, monitor, and report on performance and load testing exercises, outputs OW and Effectual + AWS Pro Serve to advise and make scalability / elasticity + architectural changes
  FB6   Optimizer NXOP architectural changes                                                                                                 2026-01-31     AA Approval (Prem, Lakshmi)   PPT, Mural, IaC   AA OR Team               OW and Effectual to advise in architectural changes to support real-time, day-of operational workload

## Q1 deliverables Designed to achieve scorecard milestones {#slide-16}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  ID     Objective / Description                                                   Due Date       Acceptance Criteria           Medium                                Dependencies                                              Activities
  ------ ------------------------------------------------------------------------- -------------- ----------------------------- ------------------------------------- --------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  FB7    NXOP Data model advisory and impact to NXOP                               2026-03-31     AA Approval (Lakshmi)         PPT, Mural, Excel (data dictionary)   System Implementation, Various AA business domain teams   OW to provide technical considerations to the overall data model developed by AA business domain experts for first mover(s) to optimize for real-time consumption and storage of data  
  FB8    NXOP FinOps maturity improvement for optimizer execution                  2026-03-31     AA Approval (Lakshmi)         PPT, Mural                            AA Product Owner (NXOP)                                   OW and Effectual improving on the FinOps model to forecast optimizer runs for the purpose of estimation OW and Effectual to provide quota limitation and impact to optimizers
  FB9    NXOP Operations Analytical architecture                                   2026-03-31     AA Approval (Prem, Lakshmi)   PPT, Mural, IaC                       AA Enterprise Data Platform                               OW working with AA Enterprise Data Platform to align on operations analytical engine that fits into the Enterprise Data Platform ecosystem OW to create mural diagrams for architecture changes 
  FB10   Perspective on AI Agents incorporated into NXOP analytical architecture   2026-01-31     AA Approval (Lakshmi, Prem)   PPT, Mural                                                                                      OW to provide a recommendation on NXOP architecture enhancements to support AI Agents for analytics
  FB11   Continuation of RFI Support                                               2026-01-31                                   Word, PPT                                                                                       OW to provide advisory on RFI including response review aligning to the goals of the program, non-functional requirements, etc.

## Slide 17

NXOP Charter

3

## Slide 18

NXOP Charter: Key principles and architecture

3.1

## Next Gen Ops Platform charter: Purpose & guiding principles The Next Gen Ops Platform charter defines what the purpose, scope, and capabilities of the platform to ensure an efficient and safe operational environment {#slide-19}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Purpose:  To deliver a resilient, intelligent, and real-time digital platform that enables airline operations teams to proactively manage, optimize, and recover flight and crew Operations ---ultimately improving efficiency, safety, and customer experience; this is the state of the Airline for decision making workloads within operations

Platform Design:  Support real-time capabilities, a composable architecture, digital twin grounding, and human operator decision-making

Resiliency:  Ensure resilience by requiring all AA developed applications and vendor solutions to meet AA standards

System Tiering:  Right-size systems for speed of delivery and cost based on criticality (i.e., best effort, essential, critical)

Open Platform:  The platform is part of the overall Enterprise Data Strategy and is open for other systems to utilize data and key services

Safety & Compliance:  Remain compliance with regulations set forth by FAA and IATA

Evolvability:  Maintain ability to adapt the platform charter and architecture based on evolving demands and requirements

Unified Data Fabric:  Govern and secure a single source of truth for operational real-time data

![](ppt/media/image67.png "ico-magnifier")

Next Gen Ops Platform Guiding Principles

1

2

3

4

Confidential

Preliminary

5

6

7

## NXOP Platform Scope The Next Gen Ops Platform will be real-time data platform leveraged to define the state of the airline for operations {#slide-20}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

ILLUSTRATIVE

Confidential

- 

In Scope

Out of Scope

Common data processing

A unified layer that performs data aggregation, enrichment, and analysis across diverse sources

End-user-facing operations apps not built on the platform

Applications that operate independently of the NXOP infrastructure

Marketing/loyalty systems, etc.

Systems focused on customer engagement and commercial systems that do not require operational insight

Observability / telemetry

Mechanisms to monitor system performance and behavior through metrics, logs, and tracing

Optimizers

Algorithms that enhance operational efficiency by applying machine learning and analytics to real-time data

Short-term history

Systems that manage and analyze recent data trends to support immediate operational insights

Real-time data pipelines

Systems that enable continuous processing and transfer of data to support immediate decision making

Decision support systems

Tools that analyze data and present actionable information to aid in decision-making

Integration with IOC

Seamless coordination of data inputs, monitoring tools, and control mechanisms for operational performance

Shared APIs

Common interfaces that allow various applications and systems to communicate and exchange data

Auditable Data

Data that can be retrieved in the event of an audit

Analytics / Insights

Data used for historical what-happened, why something happened analytics and long term decisions

## NXOP principles: Data persistence Data persistence principes help support  a resilient, intelligent, and real-time digital platform that enables airline operations teams to proactively manage, optimize, and recover flight, crew, aircraft, and ground operations {#slide-21}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  \#   Principle
  ---- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  1    Complexity comes from lack of standards and controls, not the number of data persistence stores
  2    NXOP will strive to have no more than 1 data persistence store for each type of data (e.g., document, relational, object, etc.) 
  3    NXOP will ground in having a standard for data persistence and then manage by exception (as needed) to mitigate risk of proliferation of solutions
  4    NXOP will, to the extent possible based on available tooling and integration options, seek to avoid tight couplings between data consumers and data providers
  5    This NXOP architecture is "software" and can be changed with the key being the architecture is loosely coupled (with AppSync, MSK and Flink particularly) allowing for the database to change or have multiple as necessary
  6    Further definition of the NXOP charter will support AA colleague's building into the platform and building on top of the platform
  7    An exception process will be developed to evaluate potential application architecture's leveraging NXOP that do not follow the established standards / patterns

Maybe bring this up after slide 3? Can bring unified data fabric into this and get rid of it from slide 3

## Next Gen Ops Platform charter: Product arc informed by FOS The Next Gen Ops Platform (NXOP) will replace FOS as the state of the airline for operations and will incorporate current FOS dimensions across Ops and Crew; NXOP will also be designed to integrate with data from other systems {#slide-22}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Before day of operation

Day of operation (pre-flight)

Day of ops.(during flight)

Post-flight

NXOP will include a data repository for the operational state of the airline at any given time to support an FAA approved system of record

- In addition to representing current FOS dimensions in NXOP design, system administration will be required to consolidate data from other AA and external systems (e.g., maintenance, flight schedule, aircraft data, customer data, etc.)
- FOS is currently  being decommissioned (with some applications moving to vendors), and NXOP will serve as the replacement product

Operations

Crew

Confidential

Dimensions currently covered by FOS:

Preliminary and non-exhaustive

## Potential scope of integrations for the NXOP Ecosystem {#slide-23}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

- Currently, there are over 100-LAA & 70-LUS interfaces to and from FOS  (PSS, Flight Hub, AirOps, Weather, Bidding, Crew Phone Systems etc.) 
- 
- However, many of the interfaces are different, adding to the overall  integration complexity (SCEPTRE, JMOCA, Parts360)

Confidential

Preliminary and non-exhaustive

Note: as of 2015

## Proposed evaluation approach: Key considerations Technology selection for the Next Gen Ops Platform will require evaluation across key criteria to ensure that anything used within the platform will be able to support the current and future needs of the airline {#slide-24}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

- Operational workloads with various velocity and latency requirements

<!-- -->

- Real-time \< 250 milliseconds
- Near real-time \< 5 second
- High \> 5 seconds

<!-- -->

- Uptime availability of 99.999%
- Recovery Point Objective of 0
- Recovery Time Objective of \< 5 minutes
- Data consistency strong (not eventually consistent) for a majority of workloads
- Consumer defined data retrieval
- 

Context:

- Cost is optimized and considered an important driver in selecting infrastructures and services

Assumptions: 

- Anticipated product workload of 2027+
- 20 -- 30 TB / month processing
- Data ingestion and processing only

- \~20-30 TB of data per month
- \~70+ MM source payloads a day
- Data enrichment equivalent to \~500+ MM payloads a day
- Mix of near- and long-term data retention requirements

![Cloud Computing outline](ppt/media/image98.png "Graphic 19")

NFRs 1

Cost

Data 

Metrics

![](ppt/media/image100.png "Graphic 20")

1. Non-functional requirements

![](ppt/media/image102.png "ico-control-panel")

Confidential

## Next Gen Ops Platform: Preliminary design architecture Platform will have streamlined interfaces with outside systems (incl. vendor SaaS solutions and other AA systems) via the integration layer; it will also facilitate all operations capabilities such as real-time analytics and decision support {#slide-25}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Preliminary

Monitoring and observability

Integration layer

6

AA Application-tier and consumers

1

Operational Data: Hot data tier

Data Lakehouse 2

Operational analytics and ML

Live data streams and events

9

10

7

8

11

1. Architecture allows for future incorporation of IoT when opportunity identified \| 2. Existing data lake

Confidential

    Outside of NXOP border

  \#   Service area description / purpose
  ---- --------------------------------------------------------------------------------------------------------------------------------------
       Application Tier: Receive real time data streams with access to powerful query and AI capabilities to power business applications
       Event Streaming: Robust, low latency data integration across data sources involved in FOS program 
       API Integration: Secure data exchange between AA internal and external systems, using industry standard API patterns
       Messaging Integration: Accept real-time data feeds, from external systems, using industry standard messaging and data protocols
       Batch file uploads: As needed external (vendor) integration (i.e. upload static records data and/or end of day data)
       Integration: Robust, low-latency data  integration across variety  of  data sources
       Hot Data: Persistence  services  for full  coverage of data use cases and data caching
       Data Lakehouse: L ong-term  data storage and cross-domain business analytics
       Live Data: Real-time data feeds for AA intraday processing 
       Operational analytics & ML: real-time analytics / optimizers for business functions, with tight integration  with the hot  data tier
       Monitor, manage, govern, and visualize the platform, including operational metrics, analytics models, backup and recovery

1

2

3

4

5

6

7

8

9

10

11

Event Streaming

2

API Integration

3

Queue Integration

4

File Integration

5

![](ppt/media/image105.png "Picture 1")

![](ppt/media/image106.png "American Airlines")

The integration layer connects the Next Gen Ops Platform to Third Party and AA systems

## Next Gen Ops Platform: Initial component model An initial component model for the Next Gen Operations Platform describes interactions between third party apps, the integration layer, data layer, and application layer on an AWS architecture {#slide-26}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Confidential

Preliminary and non-exhaustive

![](ppt/media/image108.png "Picture 6")

## Next Gen Ops Platform charter: Additional platform tenets As FOS Sunset strategy matures, the Next Gen Ops Platform charter will evolve to reflect key tenets {#slide-27}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Preliminary

Confidential

Confidential

## Slide 28

NXOP Charter: Platform capabilities

3.2

## Platform capabilities (1/2) Core capabilities that the platform will provide, which are solving for customer needs, crew needs, integrated applications, and decision and operational workloads {#slide-29}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Category                                                               Description                                                                                    Capability Highlights
  ---------------------------------------------------------------------- ---------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------
  Real-time Processing Layer                                             Key integration 3 rd  party and internal processing layer for high-performance and available   Event bus (MSK) Stream processing (Flink) Hot path and warm path support
  State of the Airline for decision making workloads within operations   Point in time operational state of the Airline                                                 AppSync (on-demand and subscription) DynamoDB
  Observability & Telemetry                                              Detect, diagnose, and prevent customer-impacting issues in real-time                           Unified event log Distributed tracing Failure correlation Intelligent alerting
  Optimizers                                                             Optimize operational planning and resources of the Airline                                     ECS DynamoDB Sagemaker
  Decision Support                                                       Provide IOC with timely, data-driven insights and predictive recommendations                   AI/ML for delay prediction What-if scenario planning Constraint-based scheduling

ILLUSTRATIVE

Confidential

## Platform capabilities (2/2) Capabilities are segmented by critical, essential, and best effort tiers, each defined by different NFRs that can be appropriately supported by AWS tools {#slide-30}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Confidential

Platform NFRs by Tier

Applicable Tooling, Configuration and Cost

Vital

EKS (Integration Layer)

MSK

Managed Flink

DocumentDB

API Gateway

S3

99.999% uptime

RPO: \< 15 minutes

Latency \< 100ms P95

Page load time \< 2s Realtime updates

RTO: 0 seconds

Encryption during transport and at rest

Observability: full metrics, tracing, logs, dashboard

Tuned for cost-performance balance

Critical

DocumentDB

99.9% uptime

RPO: \< 1 hour

Latency \< 1000ms P95

Page load time: \< 4s Near  realtime  updates

RTO: \< 2 hours

Encryption during transport and at rest

Observability: logs + metrics

Balance between cost and performance

Discretionary

99.5% uptime

RPO: \< 12  hours

Latency \< 5 seconds P95

Page load time \< 10s Manual refresh tolerated

RTO: \< 24 hours

Encryption during transport

Observability: basic logs

Bias for cost over performance

Configuration: Single-region, Single-AZ

ILLUSTRATIVE

Configuration: Multi-region, Multi-AZ

Cost: High

Configuration: Single-region, Multi-AZ

Cost: Medium

Cost: Low

EKS

EKS

## Slide 31

NXOP Charter: Capability sourcing

3.3

## Capability Sourcing Approach to determining which platform capabilities and applications should be developed by AA vs. bought from a third-party vendor {#slide-32}

                                                                                           Capability Sourcing Option                                                                                                                                           
  -------------------------- ------------------------------ ------------------------------ ---------------------------------------------- ------------------------------------------------------------------------ -------------------------------------------- ------------------------------------------------------------------------------
                                                                                           Vendor SaaS                                    AWS-Native                                                               AA Existing                                  AA New
  Sourcing Decision Factor   Time to market                 Time to market                 Faster if vendor provides 90%+ of needs        Fastest for AWS-Native services after approvals                          Fastest if solution provides 90%+ of needs   Slowest to start, but can build 25% of features in an MVP relatively quickly
                             Longevity                      Longevity                      Vendor lifespan and product investment         Typically, AWS backs services and gives sufficient time if deprecating   Based on internal capabilities               Can be designed for future adaptability
                             Customization                  Customization                  Limited autonomy for customization             Seamless within AWS ecosystem                                            Requires alignment and coordination          High opportunity to fit for specific requirements
                             Integration Effort             Integration Effort             High                                           Medium-High                                                              Medium                                       Low
                             NFR Alignment                  NFR Alignment                  Must ensure vendor can support Critical Tier   Select services meet Critical Tier                                       Autonomy to design for Critical Tier         Autonomy to design for Critical Tier
                             Vendor lock-in risk            Vendor lock-in risk            High if not diversified                        Medium if single-cloud                                                   None                                         None
                             Regulatory / Safe Compliance   Regulatory / Safe Compliance   Ensured by vendor                              Ensured by AWS                                                           AA is responsible                            AA is responsible

ILLUSTRATIVE

Confidential

Approach

- When determining where a capability is sourced from, we are deliberate in our choices
- NXOP is to chosen based on best fit for purpose, speed to value, operational risk, and total cost of ownership; Choices include a third party vendor, AWS native services, AA existing solution, and a newly developed capability
- We ensure the capability meets the tier's NFRs, speed-to-market or differentiation, integration simplicity, and long-term maintainability

## Slide 33

NXOP Charter: Integration strategy

3.4

## Integration Strategy Approach to compiling AA and external systems across various points of integration to ensure an efficient platform {#slide-34}

  Category                  Description                                                                                                      Capability Highlights
  ------------------------- ---------------------------------------------------------------------------------------------------------------- ----------------------------------
  API (REST)                REST APIs for Third Party Integration                                                                            API Gateway
  API (GraphQL)             GraphQL endpoint for internal applications providing sufficient projection, mutation, and subscription support   AppSync
  Event Streaming (Kafka)   Event streaming support for real-time asynchronous data integration                                              Amazon Managed Service for Kafka

ILLUSTRATIVE

Confidential

Integration Strategy Guidelines

- NXOP will have a clearly defined ingress and egress integration layer
- The platform will provide modern facilities for synchronous and asynchronous workloads, high volume and throughput, and real-time data processing with sufficient back pressure support

## Next Gen Ops Core: Integration patterns Platform supports a variety of vendor integration patterns in order of preference: event streaming, API, queue, file integration {#slide-35}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Preliminary

Event streaming

Bi-directional integration supported

Core owns and manages the event streaming service

Vendor binds to the platform's event streaming service as a producer or consumer

Event carries full state including unique id and event creation date

JSON Payload

API

Bi-directional supported

REST integration or  GraphQL  preferred

Vendor makes API calls handling HTTP Status Codes

Vendor ensures error handling with exponential backoff and retry

Core makes API calls handling HTTP Status Codes

Core ensures error handling with exponential backoff and retry

JSON Payload

Queue

Bi-directional supported

Vendor owns and manages queues

Vendor publishes messages to queues

Message carries full state including unique id and message creation date

JSON Payload

File Integration

Ingress into platform only

Platform sets up file landing zone

Vendor transmits file using SFTP

Confidential

Most preferred

Least preferred

## Next Gen Ops Core: Preliminary integration design Platform will have streamlined interfaces with outside systems via the integration layer {#slide-36}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Preliminary

Queue Integration

1

File Integration

3

API Integration

7

Event Streaming

11

![](ppt/media/image105.png "Picture 1")

![](ppt/media/image106.png "American Airlines")

The integration layer connects the Next Gen Ops Platform to SaaS and AA systems

Confidential

  \#   Service area description / purpose
  ---- -----------------------------------------------------------------------------------------------------------
       Queue: Integration layer can connect to a vendor provided queue(s)
       Queue: Queue  processor will bind to queue(s) and store into the database
       File: Batch files are uploaded by vendor
       File: File intake validates the file and persists it into the Distributed File Storage
       File: Used as a landing zone for files and long term storage of original file
       File: File handler processes the file and persists the data into the database
       API: Vendor initiates an API request handled status codes with retry 
       API: API ingestion processes the API request and publishes an event to the Event Streaming 
       API: Event streaming stores the event for immediate processing decoupling the API call
       API: Stream processor processes events that originated from an API call persisting data into the database
       Event streaming: Vendor binds to event streaming service as a producer
       Event streaming: Stream processor processes events persisting data into the database

1

2

3

4

5

6

7

8

9

10

11

12

Integration layer

API ingestion

Event streaming

Publishes Events

Queue processor

File intake

Storage layer

File handler

Operational State of the Airline

Distributed File Storage

Stream processor

2

4

6

5

8

9

10

12

## Technical considerations for first mover system integrations Each first mover system's vendor contract will need to reflect AA's preferred deployment model, vendor connectivity, and integration method to ensure alignment with NFRs and the Next Gen Ops Platform (NXOP) design {#slide-37}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Purpose:  where does a vendor system reside and who manages / operates it

Options:

SaaS:  Fully vendor-hosted and vendor-operated single-tenant software service accessed over the internet

Licensed and managed by AA:  Fully vendor developed software that is hosted and maintained  by AA

Co-build:  Vendor system is deployed into AA ecosystem, and is co-managed by Vendor and AA

Purpose:   how does vendor data move and support open telemetry / distributed tracing

Options:

Hybrid:  Data is exchanged with other vended systems and NXOP, depending on use case

Centralized:  Data processed by the vended system passes through NXOP, esp. for real-time day-of operations

Point-to-point:  Vendor-to-vendor data connectivity allowed

Purpose:  how the vendor system communicates with the Next Gen Ops Platform

Options: 

Events / Kafka:  Real-time message streaming service connecting vendor to AA

APIs:  Secure exchange between AA and vendors, using standard API patterns 

Queues:  Async exchange from vendor to ensure reliable chronological processing 

Files:  As needed vendor integration (e.g., upload static records data or EOD data)

Deployment Model

AA will need to identify a preferred deployment model, vendor connectivity, and integration method for each system:

![](ppt/media/image109.png "ico-system-update")

A

B

C

A

B

C

D

A

A1

Preliminary

Confidential

A2

## Vendor connectivity Vendor systems will have connections to NXOP and other relevant systems -- whether the vendor systems flows data to NXOP or other systems is informed by specific use cases {#slide-38}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Full Vendor system connectivity

- Connections exist between vended system, other vended systems, and NXOP

<!-- -->

- Combination of "centralized" and "point-to-point" connectivity

<!-- -->

- Vended system integration with NXOP is  use-case  driven

<!-- -->

- real-time day-of operations data
- transparency, auditability
- downstream internal systems
- 

True centralized connectivity  ( Everything flows through NXOP)

Pros

- Data is completely auditable, tracked, candidate for history
- Data can be more easily sent to internal / external systems

Cons

- Expands NXOP scope beyond real-time, day-of operations
- Increased NXOP load, cost
- Larger blast radius in the event of an NXOP issue

True point-to-point connectivity  ( Independent of NXOP)

Pros

- Quick data delivery between systems
- Low burden on NXOP management and dev teams

Cons

- Limited AA control over point-to-point interactions
- Required adherence to some non-AA standards

Applies to all Vendors

Vendors leverage centralized vs. point-to-point connectivity depending on use case

NXOP

Audit trail

## Approach to first mover systems Where will the vended systems reside, NXOP's involvement in the connectivity of vended systems, and how will they integrate with NXOP {#slide-39}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

             Deployment Model                                                                                                                                                                                                                                                                                      Vendor Connectivity                                                           Integration Method  (in order of preference)
  ---------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
  TPS        SaaS (single tenant)                                                                                                                                                                                                                                                                                  Hybrid                                                                        Eventing, APIs, queues
  LPS        SaaS (single tenant)                                                                                                                                                                                                                                                                                  Hybrid                                                                        Eventing, APIs, queues
  Crew Pay   SaaS (single tenant)                                                                                                                                                                                                                                                                                  Hybrid                                                                        Eventing, APIs, file
  CMS        Co-build                                                                                                                                                                                                                                                                                              Hybrid                                                                        Eventing, APIs
  AMCS       Co-build                                                                                                                                                                                                                                                                                              Hybrid                                                                        Eventing, APIs
  Notes      SaaS:  single tenant is possible; Vendor NFRs have been demonstrated to fulfill airline needs; Vendor can fulfill support requirements (RPO, RTO, etc.) associated with each system Co-build:  some features required are AA-specific, therefore systems should be co-managed between vendor and AA   Extent of vendor connectivity with other vendors / NXOP depends on use case   Crew Pay requires files communicating with payroll systems Queues are vendor hosted Preferred integration method should be aligned to vendor-managed infrastructure

First mover deployment models, vendor connectivity, and integration methods:

Preliminary

Confidential

Table populated by non-functional teams

Note: additional decisions regarding deployment models, vendor connectivity, and integration methods will be made once vendors have been onboarded

## Current State Capabilities under discussion Before capabilities are migrated from FOS to NXOP as SaaS or AA AWS solutions, several data connections need to be further clarified to ensure airline operations are not placed at risk by the transition {#slide-40}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Ops Hub

Legacy Connector

FOS

FOS Capabilities

C1

C2

C3

Ops Hub applications

1

3

2

Connections of current state capabilities

Discussion topics

     What is the legacy connector? 
  -- --------------------------------------------------------------------
     What applications rely on the legacy connector?
     Does Ops Hub connect to the legacy connector? 
     Do current capabilities depend on OpsHub?
     What additional upstream/downstream systems need to be considered?

1

2

3

4

5

Legend:

Existing connection

For discussion

Illustrative

Preliminary

Confidential

4

5

## Vendor transition states There are three ways that vendors could be integrated into AA's Operations ecosystem while the transition from FOS to NXOP is underway {#slide-41}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Connect to FOS through NXOP and  OpsHub

Pros

Accelerated access to cutting edge cloud tech for Operations

Enables rapid maturation of NXOP as a platform

Leverages existing Ops Hub topics whenever possible

Cons

Increased complexity for interfacing with FOS

Increased dependency on early stage NXOP

Connect directly to  OpsHub , without connection to NXOP

Pros

Reduced complexity when interfacing with FOS

Access to support from well-defined  OpsHub  teams

Fewer moving parts between Vendor System and FOS

Cons

Extraneous downstream effort to rewire systems to NXOP in the future

Integration conforms to dated standards

Connect to FOS through NXOP only

Pros

Accelerated access to cutting edge cloud tech for Operations

Enables rapid maturation of NXOP as a platform

Fewer moving parts between Vendor System and FOS (i.e., bypass  OpsHub )

Cons

Increased dependency on early stage FOS

NXOP -\>  OpsHub  data flows may need to be set up in the future

NXOP

Vendor System

Ops Hub

FOS

Transformation layer (NXOP -\> Ops Hub)

Transformation layer (NXOP -\> FOS)

1

2

3

Illustrative

Preliminary

Confidential

## Connect to FOS through NXOP Vendor systems would integrate directly with NXOP {#slide-42}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

NXOP

Ops Hub

Legacy Connector

FOS

FOS Capabilities

C1

C2

C3

Ops Hub applications

New Capabilities (SaaS, AA AWS, etc.)

C1

C2

C3

1

2

- Potential FOS    NXOP transition state

Discussion topics

     What capabilities of the vendor system can integrate directly with NXOP\'s new data model?
  -- -------------------------------------------------------------------------------------------------------------------
     Can capabilities exchange data between each other directly, or do they need to rely on a central layer like NXOP?
     What transformations/conversions from NXOP -\> Ops Hub data model are needed?
     

1

2

Transformation layer (NXOP -\> Ops Hub)

Legend:

Existing connection

For discussion

Future TPS, LPS, and Crew Pay solutions represented here

Illustrative

Preliminary

Confidential

Apps may depend on capability data

1

3

3

## Connect directly to Ops Hub, without connection to NXOP Vendors bypass NXOP and connect directly to Ops Hub, which in turn connects to FOS and NXOP {#slide-43}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

NXOP

Ops Hub

Legacy Connector

FOS

FOS Capabilities

C1

C2

C3

Ops Hub applications

New Capabilities (SaaS, AA AWS, etc.)

C1

C2

C3

2

- Potential FOS    NXOP transition state

Discussion topics

     What circumstances would force us to by-pass NXOP and have vendor systems connect to Ops Hub? 
  -- -----------------------------------------------------------------------------------------------------
     Does the new vendor system need to send/receive specific data that has to use FOS legacy connector?

1

2

Transformation layer (NXOP -\> Ops Hub)

Legend:

Existing connection

For discussion

Future TPS, LPS, and Crew Pay solutions represented here

Illustrative

Preliminary

Confidential

Apps may depend on capability data

1

2

## Connect to FOS through NXOP only Vendors integrate directly with NXOP, and NXOP integrates directly to FOS without going through Ops Hub {#slide-44}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

NXOP

Ops Hub

Legacy Connector

FOS

Ops Hub applications

New Capabilities (SaaS, AA AWS, etc.)

C1

C2

C3

- Potential FOS    NXOP transition state

Discussion topics

     What circumstances will force us to have direct connection between NXOP to FOS, bypassing Ops Hub? (latency, performance, etc.?)
  -- ----------------------------------------------------------------------------------------------------------------------------------
     Is there a performance impact for OpsHub dependent applications?

1

2

Transformation layer (NXOP -\> FOS)

Legend:

Existing connection

For discussion

Future TPS, LPS, and Crew Pay solutions represented here

Illustrative

Preliminary

Confidential

Apps may depend on capability data

3

1

2

## Slide 45

NXOP Charter: Approach to optimizers

3.5

## NXOP workload categorizations A workload category is chosen based on data latency, availability / uptime, and use case {#slide-46}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

                1. Co-located optimizers                                                 2. Common services                                                              3. Domain-specific optimizers                                                Operations state of the airline                                                               Analytics and business aggregation
  ------------- ------------------------------------------------------------------------ ------------------------------------------------------------------------------- ---------------------------------------------------------------------------- --------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------
                                                                                                                                                                                                                                                                                                                                                    
  Description   Optimizers closest to the vendor solution;  Always Running & on-demand   NXOP optimizers for day-of, real-time  decisions;  Always running & on-demand   Machine Learning Models and Advanced Algorithms;  On-demand & demand-based   Storage and processing of data containing the now and near operational state of the airline   Data is 100% business accessible as a self-service  NXOP facilitates data availability and enables data aggregation
  Use Cases     Flight planning Open time optimizations Real-time UI Dashboards          Ground coordination ETD Real-time UI Dashboards                                 Airline Slot Manager Route optimization Trip Trading                         Canonicalized AA data models Connect external and internal systems to NXOP                    What-if analysis Long term planning Exploratory data science Model / solver creation
  NFR Req'      Real-time 1 99.999% uptime RTO \< 5min RPO \~ 0min                       Real-time 1 99.999% uptime RTO \< 5min RPO \~ 0min                              Near real-time 1 99.99% uptime                                               Real-time 1 99.999% uptime RTO \< 5min RPO \~ 0min                                            High latency 1 99.9% uptime

Confidential

Draft

      Next Gen Ops Platform

      Enterprise data platform

Optimizers -- focus of subsequent pages

      Other

Location key:

1. Real-time response \< 250 milliseconds, Near  real-time response \<  5 seconds, High  latency response \>  5 seconds

Data models

Analytics

## Optimizer classification/NXOP Scope There are 3 high-level classifications of optimizers:  co-located optimizers, common services, domain-specific optimizers {#slide-47}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

              Co-located optimizers                                                                                                                                                  Common services                                                                                                                                                                      Domain-specific optimizers
  ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------- -- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -- -------------------------------------------------------------------------------------------------------
                                                                                                                                                                                                                                                                                                                                                                         
  Criteria   Location:  Closest to system of record NXOP relationship:  NXOP is singular distribution channel for Optimizer outcomes from Vendor products / SOR                     Location:  NXOP NXOP relationship:   Inherits NXOP SLAs Output of this common service is critical to upline and downline workloads                                                   Location:  Outside NXOP / app portfolio based NXOP relationship:  independent of NXOP 
             Scenarios:  Optimizer is embedded (with a vendor, CAE / Wipro ) Optimizer built by AA and deployed within the Vendor platform with the standard set of interfaces      Scenarios:  Optimizer is integrated within NXOP that utilizes data primarily from the NXOP domain, supplemented by additional data from other domains as required (maintenance)      Scenarios:  Optimizer functions as a black box, with NXOP as the  bi-directional  data movement layer
  Examples   RAS, Open Time Coverage                                                                                                                                                DOTC, ETD                                                                                                                                                                            Palantir, Internal IDO workloads (e.g., ASM, HEAT), Look Ahead
                                                                                                                                                                                                                                                                                                                                                                         

![](ppt/media/image125.png "ico-path-unite")

![Head with gears with solid fill](ppt/media/image127.png "Graphic 68")

![Abacus outline](ppt/media/image129.png "Graphic 71")

 Estimated 90% of AA optimizers

 Estimated 10% of AA optimizers

1A

1B

2A

3A

Confidential

Draft

## Real-time Operational Ecosystem {#slide-48}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Confidential

Draft

## Criteria for real-time common services Requirements are specific to NXOP {#slide-49}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Criteria                   Target                                                                                                                                          Description
  -------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------
  Availability               99.999%                                                                                                                                         Ensuring high-availability leveraging multi-AZ, multi-region in AWS
  RTO                        \< 5 minutes                                                                                                                                    Auto-healing, auto-recovery, limited manual intervention
  RPO                        Near-zero                                                                                                                                       Engineering with streaming-first principle
  Real-time latency          \< 250  ms                                                                                                                                      Streaming-first +  KPaaS  + Flink
  Solver domain              Day-of operations                                                                                                                               The optimizer is required to run day-of to solve for the customer, metal, crew, etc.
  Degree of reuse            For multi-downstream workloads                                                                                                                  The output of the optimizer is required for various applications
  Data gravity / proximity   Real-time operational datasets                                                                                                                  Optimizer needs to be closest to the operational dataset for performance
  Compute intensity          Scalable, isolated KPaaS managed compute pools                                                                                                  Optimizer requires burst compute
  Cost optimization          FinOps controlled quotas with forecast based on optimizer execution                                                                             Optimizer will take into account forecasted cost runs
  Data domain alignment      Operational data required                                                                                                                       NXOP plans to have 100% of the operational data as required
  Operational Ownership      NXOP owns data model NXOP owns data performance KPaaS  compute scale (driven by NXOP req's) Optimizer team owns compute algorithm performance   Clear high-level breakdown of ownership

Use case category:  Real-time operational day-of workloads and services

Confidential

Draft

## Slide 50

NXOP Charter: Approach to analytics

3.6

## Analytics ecosystem and NXOP The analytical platform is a tool for data scientists to create machine learning models that are deployed and execute on a real-time platform (i.e., NXOP) {#slide-51}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

1. OSOTA: Operations state of the Airline

Ops Analytics Lakehouse

OSOTA 1

ML Model Deploy

Data Scientists

Ops Business Analysts

Decision Making Team

![](ppt/media/image131.png "ico-multiple-11")

![](ppt/media/image131.png "ico-multiple-11")

![](ppt/media/image131.png "ico-multiple-11")

  Decision required:  is this group aligned on the relationship between NXOP and the analytics ecosystem?
  ---------------------------------------------------------------------------------------------------------

Data Scientists are exploring data and safely experimenting, creating different ML Models

ML Models are deployed to NXOP to be co-located near operational data

Decision-Making team via the Decision-Making platform leverages the output of the ML Models

Business Analysts are exploring data to make informed decisions on future workloads and informing business strategy

1

2

3

4

1

2

3

4

## Federated Data Lake Federated hub and node model {#slide-52}

Ops Data model is owned by Next Gen Operations

Data model is  immutable ,  versioned , and  backwards compatible  maintaining a  contract lifecycle  between each node and the Enterprise Data Platform

Enterprise Data Platform

NXOP

Integration

Ops Analytics

Baggage

Integration

Customer

Integration

Multi-domain Airline Analytics

LPS

Crew

AMCS

LPS

The Enterprise Data Platform team will govern and manage the central and node infrastructure of the federated model

Nodes must

Be responsible for their bounded domain

Be the source of domain data

Propagate data to the EDP and other nodes as determined by NFRs

Request non-domain data via EDP or other Nodes

Node integration layer

Temporarily caching non-domain data

Confidential

Illustrative

Realtime

Gold-level data product

The Enterprise Data Platform (EDP)

Node with integration layer

Analytics Toolchain

Capability / App / Service / etc.

## Enterprise Data Platform (Databricks) considerations Recommendation:   Approve  Enterprise Data Platform (Databricks)  only for NXOP  exploratory analytics and Machine Learning model creation   with strict criteria {#slide-53}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Considerations

Fit-for-purpose:  Databricks excels in handling  unknown or variable workloads ,  but does not meet the  low-latency, high-resilience  NFRs  essential for NXOP core services

Cost:   Databricks is empirically most costly on projects where cost of compute was compared -- realities can vary based in implementation

DevOps compatibility:  Interactive notebooks and monolithic jobs in Databricks conflict with NXOP's  fine-grained Java/ SpringBoot  CI/CD model ; large-scale workforce re-tooling is not recommended

Data freshness:  Business requirements for data latency (e.g., 10 min vs 1 s) must be clearly defined; Databricks is viable only if  lakehouse  ingestion meets these target SLAs

Decision criteria checklist (if all met):

Latency requirement  ≥ 10 minutes  and resiliency is non-critical

Estimated Databricks cost  ≤ 20% of business value delivered

Workload is isolated from core microservices and can run within the Unity Catalog sandbox

Databricks vs NXOP Bespoke Approach

  Dimension              Databricks                                                    NXOP Bespoke
  ---------------------- ------------------------------------------------------------- -------------------------------------------------------------------
  Capability             Flexible  lakehouse ,  MLFlow , Unity Catalog                 Fit-for-purpose Composable cloud-native services & micro-services
  Cost                   Pay-per-cluster; 1.5--50× higher                              Optimized AWS; \<1--10% reference
  Latency                Best-effort; seconds to minutes 1                             Sub-second, highly resilient
  Availability           Cannot meet 5 nines, upgrade deployment leading to downtime   Cannot go down -- 5 nines as a minimum target
  DevOps Compatibility   Notebook-centric, monolithic DABs                             Fine-grained CI/CD,  SpringBoot ,

Recommendation

Maintain NXOP's architecture for core services; enable Databricks for exploratory and ML work when justified

1. Recent release may improve latency capability

Confidential

## NXOP and Enterprise Data Platform data strategy NXOP development is currently underway with several rounds of tabletop exercises having identified workloads that could eventually land in Databricks {#slide-54}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Supportive of centralized data management that includes ops + commercial + miscellaneous

Historical based "time-travel" workloads including aggregation, analytics, and insights

Ability to run discovery against the data using well-defined data science notebooks to improve solver algorithms

Current NXOP architecture provides ease of integration shipping NXOP operational data into the Enterprise Data Strategy Data lake

Azure Data lake ways of working and scaling to include NXOP workloads or other workloads are unclear

Using Azure Data lake risks NXOP delivery timelines due to unclear understanding of data products and how they tie to the data strategy

NXOP requires improved governance, ownership definition, success metrics, and ways of working to move at speed

Unclear how cost is determined and who is responsible for FinOps, especially given the two cloud providers and ingress / egress costs

Risk of single-point-of-failure for NXOP in Databricks as the operational backbone of the airline

Databricks' new real-time streaming offer is relatively novel and still needs to demonstrate an SLA of 5 9s

  NXOP can subscribe to the Enterprise Data Strategy when ready and leverage tooling to further improve itself for specific data workloads separate from real-time operational data workloads
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Confidential

## Slide 55

NXOP Charter: Production Readiness Checklists

3.7

## Production readiness As workloads are being prepared and implemented onto the platform, we need to ensure their readiness to not impact other systems {#slide-56}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Production readiness is divided into two major categories:

Business

![](ppt/media/image139.png "ico-shirt-business")

- Responsibility and accountability of the NXOP technical team is to ensure technical qualities are met starting with architectural discussions and modifications as well as a review and sign-off on the quality of build, release, and implementation

<!-- -->

- Responsibility and accountability of the product owners to ensure that the business is ready to receive the changes, and understands and signs-off on the risk of deploying and releasing into production

<!-- -->

- This includes validating and verifying that the workload meets specifications

## Technical production readiness checklist (1/2) Governance, architectural quality, and application quality {#slide-57}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Architecture/Guild approval

Enterprise data connectivity approval

API / data model approval

No Single Point of Failures (SPOF), normal fail-over/fail-back tested

HA / DR scenarios executed and 100% successful

Demonstration of meeting RTO and RPO

Environment parity between stage and prod

80%+ code coverage for unit testing

End-to-end automated testing complete for 80% of critical test cases

Implemented in build / release pipelines SCA, and SAST demonstrating 0 high / critical security vulnerabilities

Implemented in build / release pipelines code quality scanning demonstrating 0 high / critical defects

Meets all end-to-end security guidelines such as TLS 1.3 w/ strong ciphers

Performance & load testing complete demonstrating scalability to at least 2n peak load

Chaos engineering testing complete

1. Governance

2. Architectural Quality

3. Application Quality

## Technical production readiness checklist (2/2) Build and release engineering, operational, and financial and operational planning {#slide-58}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Zero-downtime deployment tested and demonstrated

CI / CD pipelines fully automated

Infrastructure-as-code for \> 95% of all service provisioning and configuration

Infrastructure and Application Scaling is automated

100% automation for application-level configuration

Runbooks created & approved

On-call rotations defined

Health checks implemented

Observability dashboards created

Synthetic monitors established

Alerts created, configured, and tested

Rollback mechanisms created, configured, and tested

FinOps quotas and alerts created, and tested

Workload costs established

4. Build & Release Engineering

5. Operational

6. Financial & Operational Planning 

## Business production readiness checklist Business processes and financial and operational planning {#slide-59}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Business owner approval

Product owner approval

Sign-off of User Acceptance Testing

Risk Acceptance sign-off

Communication plan approved

User documentation approved

Training is established and ready to start

Support Structure / Customer Care Model established

Service Now queues created and configured

FinOps established with business considerations and workload costs

Budget allocated and approved

Capacity planning completed for the next 12-months with a checkpoint at 6-months

1. Business Support

2. Financial & Operational Planning 

## Slide 60

NXOP Charter: Service Catalogue

3.8

## Service Catalogue: Proposed outcomes and decisions A standardized Service Catalogue of services and service patterns is critical to effectively deliver on capabilities of the Next Gen Ops Platform {#slide-61}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Proposed outcomes

  1      A well-defined  standard set of service patterns  mapped to functionalities to be implemented across the Next Gen Ops Platform 
  --- -- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  2      A  governance process  and activities designed to facilitated the transition from current state to a target state Service Catalogue
  3      A  "managed by exception" approach  to the Service Catalogue that enables use of non-standard services and patterns if they unlock meaningful incremental business value
  4      Tabletop- and "hands on keyboard"-based approaches  to Service Catalogue creation

Decisions to be made to achieve outcomes

![](ppt/media/image141.png "ico-components")

![](ppt/media/image143.png "ico-white-house")

![](ppt/media/image36.png "ico-unlocked")

  1   Does Program leadership want to pursue a standardized Service Catalogue?
  --- ----------------------------------------------------------------------------------------------------------------------------
  2   Does Program leadership approve of the proposed governance structure to support transition to the target state?
  3   Does Program leadership want to pursue a "managed by exception" approach to the Service Catalogue?
  4   Does Program leadership agree with the core set of proposed activities to develop a standard set of services and patterns?

![](ppt/media/image145.png "ico-table")

## Current state: Service selection / deployment AA currently takes a fragmented approach to selecting services and technologies for its applications with inconsistent decision-makers {#slide-62}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Current state approach to service selection /deployment

Benefits and drawbacks of the current state approach

  1      Individual teams have autonomy to select services, patterns, and technologies for the applications they are supporting
  --- -- ------------------------------------------------------------------------------------------------------------------------
  2      Architecture guilds and review boards approve of teams' proposed architectures
  3      Service selection guidelines exist, are suggestive and are not routinely enforced

  Benefits    Developers have freedom of choice in service architecture Enables possibility for selection of best-in-class, fit-for-purpose services for each use case
  ----------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Drawbacks   Administrative overhead attributed to approval of individual service selections across use cases Operational complexity created by inconsistencies in service patterns used throughout the platform Approvals are gates to architecture implementation, potentially lengthening development timelines Use of non-standard catalogue can create supportability challenges as skills to maintain technology may not exist beyond team that chose it  Increased security risk -- potential for more vulnerabilities created by additional touchpoints across several developer teams

![](ppt/media/image147.png "ico-meeting")

![](ppt/media/image149.png "ico-law")

![](ppt/media/image151.png "ico-bullet-list-69")

## Proposed target state: Service Catalogue In place of a fragmented approach to service selection / deployment, AA could consider a standardized Service Catalogue of services and patterns mapped to Next Gen Ops Platform functionalities and capabilities {#slide-63}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

The Service Catalogue initiative includes 3 types of content...

...and includes benefits and drawbacks for consideration prior to implementation

  1      Service patterns to be used for most Next Gen Ops Platform applications and capabilities
  --- -- ------------------------------------------------------------------------------------------
  2      Documented rationales for service pattern selection
  3      Path to exceptions to standardized services and patterns

![](ppt/media/image141.png "ico-components")

![](ppt/media/image154.png "ico-document-2")

![](ppt/media/image156.png "ico-folder-check")

  Benefits    Common set of service patterns enable product managers to leverage a standard toolkit under an automated governance system Expedited development of future applications given pre-defined set of service options and less board approvals required Flexibility for teams to manage exceptions if meaningful incremental business value is unlocked, with central control maintained by the Program
  ----------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Drawbacks   Limited "universe of options" to a pre-defined catalogue Requires structured governance and associated forums, resources, etc. to build and align on a Service Catalogue

Teams use the Service Catalogue to make service, pattern, and technology decisions 

## Enablers for the Service Catalogue Creation of the Service Catalogue will require a bespoke governance process and upfront work though tabletop exercises {#slide-64}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Service Catalogue Enablers

     Governance   A transitionary governance process prioritizing collaboration alleviates several challenges: Coordinating cross-team alignment on inclusions to the Service Catalogue Managing exceptions to the standardized Service Catalogue Governance processes will give the Program central, automated control over Service Catalogue administration, but still involve teams' perspectives during Service Catalogue creation
  -- ------------ ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     Tabletops    Sessions for identification and validation of AWS managed services selected to support applications on the Next Gen Ops Platform Make initial decisions on inclusions to the Service Catalogue Set precedent for collaborative approach between teams and leadership Initial work is underway for  FlightKeys  / FXIP and ASM tabletops and preparations for  FlightKeys  / FXIP implementation

![](ppt/media/image158.png "ico-white-house")

![](ppt/media/image160.png "ico-settings")

## Service Catalogue enabler: Governance Governance for the Service Catalogue should enable the Program to maintain central control over the Service Catalogue while engaging teams in a collaborative decision-making processes {#slide-65}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Service Catalogue governance strategy

Use case identification

(e.g., FlightKeys/FXIP, ASM)

Generate a new Service Pattern

Identify & justify Service Pattern exception

Use an existing Service Pattern

Functional Requirements

Non-Functional Requirements

Service Catalogue

L3/4 Solution Architects

- Tabletop sessions
- "Hands on keyboard" builds

L5  Sol'n  Architects

Directors

L3/4 Solution Architects (consulted)

- Review committee meetings

VP / Senior Director 1

- The Guild

Responsible

Gov. Forums

![](ppt/media/image162.png "ico-account")

![](ppt/media/image164.png "ico-a-chat")

Preliminary

or

or

1. See appendix for " Senior Director -- AWS Cloud Architect " role description and responsibilities

Need to verify: Only leave middle in if this is how they do it now

Perform service selection and... 

Prioritize for business value & FOS sunset timeline

Identify inputs for service selection

Graduate collections of service patterns to Products

1

2

3

4

## Service Catalogue: Approach to exception management Exceptions management processes are used to evaluate service patterns not actively included in the Service Catalogue {#slide-66}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

There are three scenarios where an exception can be escalated for review by the Guild:

  Scenario                                                                                                                                                   Exception management approach
  ---------- ----------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
  A          A product 1  does not meet a requirement(s), and no alternate service pattern exists in the Service Catalogue to help meet the requirement(s)   Use a service pattern that is not in the Service Catalogue to meet the requirement(s) Add the new service pattern to the Service Catalogue if approved by the Guild
  B          A product does not meet a requirement(s), but provides meaningful incremental business value                                                    Use the product as is if incremental business value outweighs the cost of not meeting a requirement(s)
  C          A product meets all requirements, and an alternate service pattern exists that would add meaningful incremental business value                  Use the product with the alternate service pattern Add the new service pattern to the Service Catalogue if approved by the Guild

  Exceptions will be evaluated against functional and non-functional requirements provided by individual product teams
  ----------------------------------------------------------------------------------------------------------------------

1. See Appendix for descriptions of products, service patterns, and services

## Slide 67

Roles and responsibilities

4

## Responsibilities are codified for groups at all levels of the program, organized by workstream {#slide-68}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Executive Oversight / Sponsors

Program Leadership

Program Owners

Workstream Leads  (on following slide)

Core team

Program Steering

COO

David Seymour

CIO

Ganesh Jayaram

VP, Ops Planning & Performance

Anne Moroni

VP, Airline Ops Technology

Arnaud Mathieu

MD, NextGen Ops -- Business

Angela Lorenzen

MD, NextGen Ops -- IT

Chai Kommidi

SVP, Flight Operations & IOC

JC Gulbranson

SVP, Finance & Corp. Dev

Meghan Montana

VP, Finance

Kevin Richter

SVP, Chief Procurement Officer

Dan Bartel

SVP, Corporate Comptroller

Angie Owens

VP, FP&A

Anne Bernath

VP, IOC

Jessica Tyler

VP, Ops Planning & Performance

Anne Moroni

VP, Airline Ops Technology

Arnaud Mathieu

VP, IOC

Jessica Tyler

Dir. Finance 

Ngoc-Yen Wiseman

Dir. Procurement

Angie Stoy

Corp. Comm 

Ethan Klapper

Foundational build

FOS decom

Process reimagination & system implementation

Program assurance

MD, NextGen Ops -- Business

Angela Lorenzen

MD, NextGen Ops -- IT

Chai Kommidi

![](ppt/media/image51.png "ico-big-data")

![](ppt/media/image53.png "ico-drone-2")

![](ppt/media/image55.png "ico-flight-connection")

![](ppt/media/image57.png "ico-meeting")

Change management and talent alignment

![](ppt/media/image59.png "ico-b-comment")

VP, Finance

Kevin Richter

## These workstream have clearly defined leads, from the business and IT {#slide-69}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Legend:

Foundational build

FOS  d ecom

Program assurance

Systems  impl . & process reimagination

Change management and talent alignment

Core AA Working Team

IT Workstream Lead 1

Business Workstream Lead 1

Angela Hudson

TBD

TBD

Lakshmi Lanka

Prem Vijayan

Christina Jenkins (Ops)

Roger Jarboe

Indicates primary lead / single point of contact for the workstream

Praveen Chand

Srikanth Patel

Keith Curtis (Crew)

![](ppt/media/image167.png "ico-big-data")

![](ppt/media/image169.png "ico-drone-2")

![](ppt/media/image171.png "ico-flight-connection")

![](ppt/media/image173.png "ico-meeting")

![](ppt/media/image175.png "ico-b-comment")

Sameera  Papulla  (Ops)

Pramod Kumar (Crew Pay)

Christina Jenkins (Ops)

Keith Curtis (Crew)

Sameera  Papulla  (Ops)

Pramod Kumar (Crew Pay)

## Foundational Build workstream overview and org chart {#slide-70}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Workstream Leads

IT Program Owner

Chai Kommidi

Chief Architect for NXOP

Prem Vijayan

![American Airlines Logo, symbol, meaning, history, PNG, brand](ppt/media/image177.png "Picture 4")

Foundational Build Lead

Lakshmi Lanka

Architect -- Platform

Praveen Chand

Architect -- Real Time Data Service

Amit Sahay

Architect -- Integration Layer

Abhishek Hegde

Service Arch. & Build Manager

Pablo Suarez

Integration Layer Manager

Venkata Ranga

Architect -- Base Engineering

Lee Meador

Business Program  Owner

Angela Lorenzen

Project Manager  --  Foundational  B uild, Business

Srikanth Patel

Product Owner

Siva Kommireddy

Scrum Master

Kristen Bond

Product Manager

Sravan Akinapally

3 rd  Party Squads

Infosys, Insights, ProServe

Partners

Jason Lombardo,  Chris DeBrusk,

James Lefevre

Workstream Lead

James Lefevre

Workstream Execution Team

Kuba Lipowski

![](ppt/media/image178.png "DTP_CompanyLogo_112")

Establish the cloud capabilities, services, and resources needed to effectively meet NextGen performance, security, resilience, redundancy, data, and cost needs

Mandate

CTH Service & Arch. Build Engineer

Multiple Engineers

CTH Integration Layer Engineer

Multiple Engineers

Tech / Business SMEs

Effectual

Multiple Roles

Technical/BU SMEs

Sarma Palli

Roger Dunn

## Foundational Build workstream overview and org chart {#slide-71}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Workstream Leads

IT Program Owner

Chai Kommidi

Chief Architect for NXOP

Prem Vijayan

![American Airlines Logo, symbol, meaning, history, PNG, brand](ppt/media/image177.png "Picture 4")

Foundational Build Lead

Lakshmi Lanka

Architect -- Platform

Praveen Chand

Architect -- Real Time Data Service

Amit Sahay

Architect -- Integration Layer

Abhishek Hegde

Service Arch. & Build Manager

Pablo Suarez

Integration Layer Manager

Venkata Ranga

Architect -- Base Engineering

Lee Meador

Business Program  Owner

Angela Lorenzen

Project Manager  --  Foundational  B uild, Business

Srikanth Patel

Product Owner

Siva Kommireddy

Scrum Master

Kristen Bond

Product Manager

Sravan Akinapally

3 rd  Party Squads

Infosys, Insights, ProServe

Partners

Jason Lombardo,  Chris DeBrusk,

James Lefevre

Workstream Lead

James Lefevre

Workstream Execution Team

Kuba Lipowski

![](ppt/media/image178.png "DTP_CompanyLogo_112")

Establish the cloud capabilities, services, and resources needed to effectively meet NextGen performance, security, resilience, redundancy, data, and cost needs

Mandate

CTH Service & Arch. Build Engineer

Multiple Engineers

CTH Integration Layer Engineer

Multiple Engineers

Tech / Business SMEs

Effectual

Multiple Roles

Technical/BU SMEs

Sarma Palli

Roger Dunn

## Foundational Build responsibilities across the program (1/3) {#slide-72}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Foundational Build  Item                                  Oliver Wyman Responsibility                                                                                                                                                      American Responsibility (incl. Infosys/Proserv)                                                                                                                                                   Shared Responsibility
  --------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------
  Design cloud architecture and principles                  Draft initial environment standards Draft end state component diagrams Advise on FinOps best practices Provide support in refinement of regulatory and compliance requirements   Discover what standards exist and are in place today Validate initial environment standards and append as necessary Refine and validate end state component diagrams Develop approach to FinOps   Challenge, review, and align on initial standards and end state component diagrams Identify risks and potential mitigation strategies
  Design application migration strategy                     Draft initial app migration strategy                                                                                                                                             Provide criteria and context for app migration strategy (incl. list of apps to be migrated)                                                                                                       Review, challenge, and iterate app migration strategy Monitor key dependencies along the critical path 
  Design integration patterns for consumers and producers   Propose NXOP integration patterns to integrate vended solutions Identify benefits and drawbacks associated with different integration patterns                                   Provide feedback to proposed integration patterns Select potential consumers and producers (i.e., vendors)                                                                                        Review, challenge, and iterate integration patterns
  Design cutover strategy                                   Develop transition and end state architectures to describe cutover Develop timeline for cutover Flag key risks and watchpoints inherent to cutover strategy                      Provide context and feedback to proposed cutover strategies Involve relevant stakeholders to provide input for cutover strategy                                                                   Review, challenge, and iterate cutover strategy Monitor key dependencies along the critical path

Preliminary

## Foundational Build responsibilities across the program (2/3)  {#slide-73}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Foundational Build  Item                                     Oliver Wyman Responsibility                                                                                                                                                                                                                                       American Responsibility (incl. Infosys/Proserv)                                                                                                                                                                          Shared Responsibility
  ------------------------------------------------------------ ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Implement cloud architecture                                 Provision and build dev environment Provide support to staging / non-prod environment as needed Provision and build the prod environment Draft architectures for FXIP and ASM on AWS Provide technical support for transition of components to prod environment   Set up networking infrastructure for all environments Provision and build the staging / non-prod environment Develop FXIP and ASM in AWS environments Move ASM and FXIP to production environment                        Align on environment requirements Challenge assumptions and propose adjustments as needed Perform hands on keyboard work to implement cloud architectures Identify risks and mitigate appropriately
  Implement integration patterns for consumers and producers   Provide clarity and guidance on integration pattern implementation as needed Refine integration patterns as needed Provide clarity and guidance on migration strategy as needed Refine application migration strategy as needed                                   Implement integration patterns Refine existing architecture as needed to accommodate integrations with consumers and producers Proactively raise risks and blockers Execute application migration strategy as designed   Address risk and blockers to maintain integration implementation timelines Identify, monitor, and address risks and blockers to maintain migration timelines Track progress against application migration timeline
  Execute cutover strategy                                     Provide clarity and guidance on cutover strategy execution as needed Provide support to refine cutover strategy as needed                                                                                                                                         Execute cutover based on agreed upon cutover strategy Proactively raise risks and blockers during cutover process Refine cutover strategy as needed                                                                      Address risks and blockers to maintain cutover timelines Track progress against cutover timeline

Preliminary

## Foundational Build responsibilities across the program (3/3)  {#slide-74}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Foundational Build  Item                                                       Oliver Wyman Responsibility                                                                                 American Responsibility (incl. Infosys/Proserv)                                                                                                                                                                                                                                      Shared Responsibility
  ------------------------------------------------------------------------------ ----------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Systems requirements gathering & validation                                    Structure approach to vendor NFR evaluations Draft initial system implementation strategy                   Engage vendors to obtain NFRs Provide criteria and context for system implementation strategy Narrow and select vendors for integration                                                                                                                                              Assess vendor NFRs against AA NFRs Review, challenge, and iterate system implementation strategy Identify risks and potential mitigation strategies Execute system implementation strategy
  Develop testing strategy                                                       Provide input on testing best practices based on prior implementation experience and industry expertise     Develop a program-wide testing strategy  Provide required business and IT scenarios which require testing Provide input on historic testing strategies and approach                                                                                                                  Review, challenge, and align on the program-wide testing strategy Develop testing timeline  Work cross-functionally across workstreams to ensure timeline aligns with program
  Functional testing                                                             Help synthesize and communicate testing results                                                             Execute functional tests Report out on outputs of tests                                                                                                                                                                                                                              Adress risks and blockers to maintain testing timelines
  Non-functional testing                                                         Conduct some non-functional tests to support AA as needed Help synthesize and communicate testing results   Conduct chaos engineering, integration, performance, and load tests Communicate any revisions that need to be made to architectures / infrastructure if tests fails Report out on outputs of tests                                                                                   Address risks and blockers to maintain testing timelines
  Workstream management (Tooling, risk, action items, decision log management)   Maintain program tooling (update current statuses and mitigation plans)                                     Log program risks, action items, and decisions, as identified within tooling suite and update status accordingly  Provide updates on program roadmap activities and status within selected tooling suite  Own broader change request process and flag proposed changes to timeline   Actively identify and track risks Escalate risks to leadership as needed according to outlined governance framework

Preliminary

## High level RACI role definitions The FB workstream's RACI matrix applies to several roles across AA and OW {#slide-75}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

                      Role Title           Role Description                                                                                     Example
  ------------------- -------------------- ---------------------------------------------------------------------------------------------------- ------------------------------------
  American Airlines   Program Owner        Provide oversight for delivery of key architectural milestones                                       Chai Kommidi, Angela Lorenzen
                      Workstream Lead      Coordinate execution of key architectural milestones                                                 Lakshmi Lanka
                      Tech / Bus SME       Provide technical context and input to key decisions                                                 Amit Sahay, Abhishek Hegde
                      Infosys / Insight    Execute on specific topics / pieces of work                                                          Arun Patil, Rahul Jain
                      ProServe             AWS SME / best practices, execute on specific topics / pieces of work                                Ram Kanikannan, Param Vaidyanathan
                      Steering Committee   Provide high-level direction for NXOP                                                                Anne Moroni, Jessica Tyler
  Oliver Wyman        Partner              Provide guidance on Program's high priority decisions                                                Chris DeBrusk, Jason Lombardo
                      Workstream Leads     Work with AA workstream lead to plan milestone execution, raise risks, issues, strategic alignment   James Lefevre, Kuba Lipowski
                      Tech / Bus SME       Supplement the broader team with outside-in perspectives                                             Sarma Palli, Roger Dunn
                      Effectual            Provide guidance and execute on specific topics / pieces of work                                     Nick Schoenbaechler, Garrett Stoll

Preliminary

## Foundational Build RACI Matrix {#slide-76}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

                                                               American                                                                                              Oliver Wyman                                      
  ------------------------------------------------------------ ---------------- ------------------ --------------- ------------------- ---------- ------------------ -------------- ------------------ --------------- -----------
                                                               Program Owners   Workstream Leads   Tech/Bus SMEs   Infosys / Insight   ProServe   Program Steering   Partners       Workstream Leads   Tech/Bus SMEs   Effectual
  Design cloud architecture and principles                     A                C                  R               I                   I          I                  C              C                  R               C
  Design application migration strategy                        A                C                  R               C                   C          I                  I              R                  R               C
  Design integration patterns for consumers and producers      A                C                  R               C                   C          I                  I              R                  C               C
  Design cutover strategy                                      A                C                  R               I                   I          I                  C              C                  R               C
  Implement cloud architecture                                 A                C                  R               R                   R          I                  I              C                  C               R
  Implement integration patterns for consumers and producers   A                C                  C               R                   C          I                  I              I                  C               C
  Execute cutover strategy                                     A                C                  C               R                   I          I                  I              C                  C               I
  Systems requirements gathering & validation                  A                C                  R               I                   I          I                  I              C                  R               C
  Functional testing                                           R / A            I                  C               R                   I          I                  I              C                  C               I
  Non-functional testing                                       A                R                  R               R                   R          I                  I              C                  C               R
  Workstream management                                        A                R                  C               C                   C          I                  I              R                  C               C

Preliminary

Note: RACI definitions are as follows: R (Responsible): Charged with executing and delivering the task; A (Accountable): Ensures timely delivery to the required quality; C (Consulted): Provides input and opinions; I (Informed): Receives updates about the activity

## Foundational Build Role Descriptions (1/10) {#slide-77}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Chief Architect -- NextGen Ops Platform (Workstream Lead)                                                                                                                                                                                     Foundational Build Lead  (Workstream Lead)
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Prem Vijayan                                                                                                                                                                                                                                  Lakshmi Lanka
  Principal technical authority for the next‑gen flight operations platform across Crew and IOC/Ops, aligning architecture decisions to the Program's 7‑year roadmap and enterprise priorities                                                  Lead the Services & Platform Build workstream day to day, working with AA and with third‑party resources, sequencing milestones, and serving as the primary point for risk and issue escalation within the workstream 
  Participate in Program governance forums, ensuring architectural decisions, standards, risks, and dependencies are transparently surfaced for timely decision‑making                                                                          Partner with data architecture to enable the enterprise data model across services, ensuring functional and nonfunctional requirements are supported and interoperable 
  Partner with Program Owners to bridge Business/IT perspectives, translating strategic direction into executable architectural roadmaps and design choices                                                                                     Drive the services architecture managers, architects, and squads in their execution, managing development progress to stay on track and prioritizing big risks
  Define cloud deployment standards aligned to AA's cloud strategy (e.g., single vs. multi‑cloud; use of advanced cloud services) as a key input to solution design, nonfunctional requirements, and vendor evaluation criteria                 Contribute technical scope, estimates, and sequencing to the Program plan and funding drawdowns, ensuring services and platform feasibility and alignment with the Program roadmap 
  Ensure the next‑generation operations platform is future‑proof and scalable with AA's growth, while addressing FOS limitations and positioning the airline for improved reliability, security, and change efficiency                          Lead problem solving and risk mitigation efforts for services and platform build work, guiding squads on design decisions, resolving blockers, and translating work blocks into actionable user stories, epics, and features for development
  Review systems architecture to ensure alignment with NXOP architectural principles, objectives, and requirements, proactively identifying gaps and driving remediation                                                                        Implement resilience, observability, and disaster recovery patterns in the platform to mitigate current fail‑forward only limitations and reduce operational risk 
  Establish and enforce program cloud standards and non‑functional gating criteria across both integrations and base engineering (e.g., single vs. multi‑cloud, resilience targets), and certify readiness before vendor evaluations proceed    Identify and assess change requests and risks; review relevant documentation and escalate issues through proper governance forums and drive remediation
                                                                                                                                                                                                                                                

## Foundational Build Role Descriptions (2/10) {#slide-78}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Architect -- Platform                                                                                                                                                                                                                                          Architect -- Base Engineering
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Praveen Chand                                                                                                                                                                                                                                                  Lee Meador 
  Orchestrate the end‑to‑end integration and platform readiness lifecycle, converting mid‑level/refined integration designs and cloud standards into executable release trains and gated milestones                                                              Own day-to-day base engineering architecture guidance; direct squads on platform foundations (cloud landing zone, networking, IAM), ensuring designs are implementable and aligned to program standards and target state
  Own platform foundation readiness: landing zones, network segmentation, secrets/encryption, audit controls; publish readiness scorecards and evidence for governance checkpoints and funding drawdown submissions                                              Manage development progress and focus; keep squads moving toward agreed milestones; proactively unblock; enforce sprint quality gates; challenge decisions that diverge from standards or jeopardize timelines
  Define and run API lifecycle governance (versioning, backward compatibility, deprecation rules, contract testing) to keep vendor/platform options aligned with the integration blueprint and data model framework                                              Build and govern the integration-ready platform layer (runtime, API gateway, messaging, service mesh) to support the program's integration layer deliverables and vendor evaluations
  Lead technical due‑diligence and proofs of technology for integration pathways and platform services; map nonfunctional requirements and evaluation criteria to outcomes, documenting recommendations for adoption or redesign tied to near‑term milestones    Stand up DevSecOps toolchains: CI/CD pipelines, artifact management, automated testing gates (functional, performance, security), infrastructure-as-code baselines, and environment parity across dev/test/stage/prod
  Specify and enforce performance, capacity, and resilience policies (autoscaling envelopes, flow‑control/back‑pressure, multi‑region topologies) as acceptance criteria for integration releases against milestone timelines                                    Drive documentation quality: publish standards, reference architectures, platform service catalogs, environment matrices, and runbooks; keep artifacts discoverable and current as designs evolve
  Coordinate with system implementation timelines to ensure alignment throughout build process                                                                                                                                                                   Provide architectural inputs and evidence into governance artifacts (Board‑ready plan, expanded roadmap and cost estimate,), demonstrating readiness of platform foundations and de‑risking of downstream implementation

## Foundational Build Role Descriptions (3/10) {#slide-79}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Scrum Master                                                                                                                                                                                Architect -- Integration Layer
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Kristen Bond                                                                                                                                                                                Abhishek Hegde
  Manage the integration squad's day to day, coordinating AA and third‑party engineers, tracking delivery against near‑term milestones, and ensuring alignment with overall Program roadmap   Serve as design authority for the integration layer; set service and contracts, messaging patterns, and resiliency principles the squads must implement 
  Translate program priorities into a clear backlog; develop stories with precise acceptance criteria and non-functional expectations tied to integration stage gates                         Publish and maintain cloud-aligned integration standards and nonfunctional requirements that guide design choices and vendor evaluations 
  Enforce adoption of program standards (cloud deployment, security, resilience) across integration deliverables; verify compliance as part of ready-to-release checks                        Align integration designs to the future-state data model framework and domain specifics for Crew and IOC/Ops, ensuring consistent payloads, mappings, lineage, and stewardship touchpoints 
  Orchestrate test environments and test data readiness (synthetic/masked/parity rules) for integration validation; monitor results and drive remediation to closure                          Direct squads on design implementation details (idempotency, error handling, back-pressure, retries, observability) to meet the integration standards and stage gates 
  Provide hands-on problem solving for complex interface defects, data contract mismatches, and resiliency gaps; escalate only when options are exhausted, with recommended paths             Guide proofs of technology for integration approaches; assess platform fit against the integration blueprint and standards; document recommendations and implications for delivery sequencing 
  Identify and report cross-workstream risks and dependencies; resolve within-workstream issues and escalate unresolved risks/issues to Program Owners with recommended strategies            Provide architecture inputs to governance artifacts demonstrating integration design maturity and readiness for downstream implementation 

## Foundational Build Role Descriptions (4/10) {#slide-80}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Architect -- Real Time Data Service                                                                                                                              Project Manager -- Foundational Build, Business
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Amit Sahay                                                                                                                                                       Srikanth Patel
  Serve as design authority for the real time data platform; set service and contracts, messaging patterns, and resiliency principles the squads must implement    Coordinate the foundational build workstream with Program governance, preparing leadership/steering materials and ensuring decisions, risks, and dependencies are captured and communicated through the governance forums
  Publish and maintain cloud-aligned real time data streaming standards and nonfunctional requirements that guide design choices and vendor evaluations            Maintain Program tooling alongside associated statuses across foundational build deliverables
  Direct squads on design implementation details (idempotency, error handling, back-pressure, retries, observability) to meet the real time data standards         Drive cross‑workstream dependency management to ensure foundational inputs unblock vendor evaluation and sequencing
  Guide proofs of technology for real time data approaches; document recommendations and implications for delivery sequencing                                      Operate risk, action items, and decision log within tooling for foundational build, with clear mitigation options and timely escalations
  Provide architecture inputs to governance artifacts demonstrating real time data service design maturity and readiness for downstream implementation             Managing of activities, deliverables and dependencies to ensure timely delivery of work items (e.g., user stories, features, epics, etc.)

## Foundational Build Role Descriptions (5/10) {#slide-81}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Service Arch. & Build Manager                                                                                                                                                              Integration Layer Manager
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Pablo Suarez                                                                                                                                                                               Venkata Ranga
  Define service architecture standards, patterns and guardrails to ensure Next Gen Ops Platform consistency and vendor compatibility                                                        Set the integration layer vision and design principles so all systems follow a consistent approach 
  Own service configuration and provisioning for chosen platform components ensuring deployments meet performance, resiliency and cost targets                                               Own the integration governance framework, establish security requirements, schema/version control, and expectations to ensure integrations are reliable, auditable and maintainable 
  Validate vendor and third‑party service fits by leading fit/gap assessments for first‑mover systems and quantify integration effort and risks                                              Resolve integration dependencies and blockers, ensuring milestones for Foundational Build, Systems Implementation and Decommissioning remain on track 
  Mitigate technical and test‑environment risks by owning escalation, proposing pragmatic trade‑offs (including additional test capacity if required), and escalating risks to leadership    Define test scenarios, data needs, and environment capacity within the integration layer across dev, staging, and prod; escalate provisioning or procurement when testing constraints threaten timelines 
  Lead the contract-to-hire engineers ensuring deadlines are met, progress documented, and risks are actively tracked and mitigated                                                          Lead the contract-to-hire engineers ensuring deadlines are met, progress documented, and risks are actively tracked and mitigated   

## Foundational Build Role Descriptions (6/10) {#slide-82}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  CTH Integration Layer Engineer                                                                                                                                                                                         CTH Service & Arch. Build Engineer
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------
  Multiple Roles                                                                                                                                                                                                         Multiple Roles
  Aid in the design of the integration layer architecture to ensure the platform can ingest and transform data from multiple apps, systems and other cloud providers                                                     Select and validate service configurations against AA use‑cases to optimize performance, resiliency, and cost 
  Design and build the integration layer for NextGen Ops platform that focuses on scalability, capacity, and that can accelerate workstream delivery                                                                     Configure cloud services and platform components to meet the NextGen Ops Platform standards and support vendor systems programming 
  Implement secure, scalable cloud integration infrastructure aligned to NextGen Ops Platform foundational standards and cloud vendor requirements                                                                       Integrate configured services with the integration layer, vendor systems  and existing enterprise systems to enable end‑to‑end functionality 
  Validate vendor and third‑party system integration approaches and estimate/own the integration work effort                                                                                                             Test and validate service deployments with use‑case proof‑outs and vendor on‑boarding activities; identify environment capacity needs and surface testing gaps
  Mitigate operational risk by defining integration test plans, participating in FOS discovery/patching activities, and ensuring test environments and capacity needs for integrations are identified and provisioned    

## Foundational Build Role Descriptions (7/10) {#slide-83}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Product Owner                                                                                                                                                                         Product Manager
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Siva Kommireddy                                                                                                                                                                       Sravan Akinapally ​
  Serve as an intermediary between teams working to develop the Next Gen Ops Platform and other AA teams, particularly shared services teams (e.g., Kubernetes Platform as a Service)   Operate with the Product Owner as an intermediary between teams working to develop the NextGen Ops Platform and other AA teams
  Proactively identify key risks and dependencies between the NextGen Ops Platform and other parts of the enterprise to ensure on time delivery of key milestones and activities        Track all identified risks and dependencies between the NextGen Ops Platform and other workstreams as per standards outlined by Program governance and help to escalate risks as needed
  Support NextGen Ops Platform development with sufficient compute resourcing                                                                                                           Support NextGen Ops Platform development with sufficient compute resourcing
                                                                                                                                                                                        
                                                                                                                                                                                        
                                                                                                                                                                                        

## Foundational Build Role Descriptions (8/10) {#slide-84}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  3 rd  Party Development Squads -- Infosys, Project Manager                                                                                                                                                                                                                      3 rd  Party Development Squads -- Infosys, Architect
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Rahul Jain                                                                                                                                                                                                                                                                      Kranthi Parameshwar, Arun Patil
  Lead end‑to‑end delivery of the integration layer services for Flight Execution Platform (FXIP), coordinating Infosys squads to implement Application Programming Interface (APIs), streaming, and messaging components that connect Flight Keys to the NextGen Ops Platform    Execute Flight Execution Platform (FXIP) architecture, integration patterns, message schemas that FXIP will use to ingest Flight Keys flight plans and publish data to the NextGen Ops Platform 
  Manage FXIP build‑out schedule and translate program milestones into an integrated FXIP delivery plan, track progress against the Program build‑out timeline, and drive corrective actions to keep programming on schedule                                                      Define data model & transformation rules for flight plan data derived from Flight Keys and the transformation/mapping rules FXIP must apply so downstream systems receive consistent information 
  Coordinate cross‑workstream dependencies and act as the primary liaison for Infosys with other teams to align interfaces, and resolve handoffs that impact FXIP and the integration layer                                                                                       Define environment requirements so FXIP integration layer and validate test capacity needs with Program leads to avoid bottlenecks 
  Optimize resource allocation for integrations, allocate Infosys engineers and architects to the highest‑impact FXIP work blocks; surface staffing risks to Program leadership and coordinate flexible third‑party support as needed                                             Specify authorization, encryption, resiliency for the FXIP integration layer that meet operational Service Level Agreements (SLAs) and reduce FOS risk during cutover 
  Track technical and schedule risks specific to FXIP and the integration layer, escalate unresolved issues, and manage Infosys vendor deliverables to ensure adherence to the Program's governance                                                                               Work on cross‑workstream technical alignment with Infosys and other vendors on Foundational Build to sequence interface delivery, resolve integration gaps, and ensure FXIP timelines align with vendor selections and the broader Next Gen Ops Platform build‑out 
                                                                                                                                                                                                                                                                                  

## Foundational Build Role Descriptions (9/10) {#slide-85}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  3 rd  Party Development Squads -- Infosys, Engineer                                                                                                                                                                                                                                                3 rd  Party Development Squads -- ProServe
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Ignacio Davalos Lopez, Kalpana Beerakayala                                                                                                                                                                                                                                                         Ram Kanikannan
  Code the mapping, enrichment, and logic that creates the FXIP integration layer and implement the Application Programming Interface (APIs) that pull Flightkeys flight plans into Flight Execution Platform (FXIP) and ensure reliable ingestion at expected volume within the integration layer   Design and implement cloud platform for the Next Gen Ops platform, create cloud foundation on Amazon Web Services (AWS) so that downstream systems have a secure, scalable hosting environment aligned to program standards 
  Help to configure dev, staging, and prod environments for the FXIP integration layer ensuring environment parity, appropriate capacity, and secure access controls                                                                                                                                 Provision staging environment to ensure environment parity and reliable deployments for integration components 
  Develop tests, schema validation and automated unit/integration tests so that Flight Keys to FXIP interactions are verifiable and version‑safe                                                                                                                                                     Implement AWS patterns for high availability, autoscaling, and disaster recovery to meet operational guidelines and reduce risk during parallel runs and final cutover 
  Instrument monitoring, logging, resiliency checkpoints, and alerting for latency and error rates so the team can measure integration layer performance                                                                                                                                             Lead design and execution of cloud tests; size and validate test environments to address the documented testing capacity risk (T‑DEC/VPARS) and avoid schedule impacts 
                                                                                                                                                                                                                                                                                                     Provide structured training, runbooks, and hands‑on workshops for American Airlines engineering on AWS best practices, operational procedures, and cloud native testing so AA can sustain and operate the platform 

## Foundational Build Role Descriptions (10/10) {#slide-86}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  3 rd  Party Squads - Insight
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Insight
  Build the integration layer in accordance with the initial and refined mid‑level future‑state architecture designs, ensuring reliable ingress/egress for diverse applications, systems, and data sources
  Ensure interoperability and decoupling from FOS by designing integration patterns that respect the FAA‑certified system‑of‑record constraints and the broad set of downline connectivity requirements
  Collaborate tightly with FOS Decommissioning, and Systems Implementation workstreams to unblock dependencies, validate handoffs, and maintain alignment to shared standards and integration patterns
  Produce and maintain technical documentation and evidence required by governance forums to substantiate milestone progress

## Foundational Build -- OW Support: Role Descriptions (1/3) {#slide-87}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Partners                                                                                                                                                                                                                                                                           Technical SMEs
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Jason Lombardo,  Chris DeBrusk ,  James Lefevre                                                                                                                                                                                                                                    Sarma Palli / Roger Dunn
  Structure the build of the Next Gen Ops Platform and guide key architectural decisions, ensuring the platform foundation, services, and patterns are ready to support upcoming systems implementation activities                                                                   Define the NXOP cloud target architecture and service blueprint to meet Program and broader AA needs, by working with affiliated 3 rd  party stakeholders (ProServe) and workstream leads
  Guide development and publication of the full set of platform standards ahead of implementation, review/adapt and develop DevOps, UI/UX, and Security standards to govern how teams build on the platform                                                                          Finalize cloud commercial terms and support SLAs (commitments on capacity, pricing, reserved instances, enterprise support, and ramp‑up credits) 
  Advise on and execute cloud vendor engagement and negotiations, complete cloud provider contracting/procurement, align stakeholders, and memorialize rationales for AWS service usage to enable efficient, governed build-out                                                      Specify non‑functional requirements within NXOP and validate vendor proposals against those criteria
  Conduct base engineering to stand up the managed service infrastructure; commence infrastructure build-out; run architecture tabletop exercises; and lead functional, performance, and security testing to validate the foundation before scale-up and hand‑off to system builds   Facilitate execution of cloud provisioning and environment delivery plan (dev/test/staging/prod templates), to ensure cloud environments are built early, tested, and operationalized ahead of engineering needs and implementation 
  Collaborate with 3rd‑party engineering support (e.g., Effectual) for effective guidance and execution, select/onboard partners, define scope/roles, and ensure knowledge transfer and upskilling of AA squads while maintaining tight delivery control                             Define testing capacity, performance benchmarking, and failover validation approaches in the cloud to mitigate testing‑environment risks called out for the program 
  Deliver early migration patterns and exemplars, define a comprehensive app migration strategy (maintain/rehost/refactor), and capture reusable integration and pre‑production patterns for downstream builds                                                                       Coach and certify AA cloud engineering leads on AWS best practices, runbook creation, cost governance, and operational run‑the‑business processes to embed sustainable cloud capability post‑transition

## Foundational Build -- OW Support: Role Descriptions (2/3) {#slide-88}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Workstream Lead                                                                                                                                                                                          Workstream Execution Team 
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  James Lefevre                                                                                                                                                                                            Kuba Lipowski
  Own the capture and governance of requirements and development outcomes from cross‑functional sessions , ensure decisions, owners, and actions are recorded, tracked, and closed                         Actively support foundational build tasks by meticulously documenting requirements and developments during collaborative project sessions, ensuring nothing falls through the cracks
  Drive adoption of cloud and operational best practices across the squad and adjacent teams, produce recommendations, standards, and trade‑off guidance for performance, resiliency, security and cost    Dive into best practices in cloud technologies and operational processes, providing key insights that inform strategic decisions and streamline project execution
  Lead evaluation of existing flight‑operations processes, identify modernization gaps or remediation needs, and prioritize recommendations for Systems workstream engagement                              Evaluate existing flight operating processes to identify areas for enhancement or remediation within the modernization effort
  Coordinate stakeholder feedback on design iterations; consolidate input, escalate conflicting requirements, and translate decisions into actionable changes for engineers and vendors                    Proactively collect and consolidate feedback from stakeholders on design iterations, vital for refining and enhancing cloud solutions that meet operational needs
  Assess technical risks and emergent design challenges, recommend pragmatic mitigations (including trade‑offs), and surface these to Workstream leads with decision options and impact analysis           Maintain comprehensive and organized documentation of architectural designs, processes, and decisions, creating a valuable resource for future reference and accountability throughout the project lifecycle
                                                                                                                                                                                                           Conduct thorough evaluations of emerging technical challenges within the system design, proactively suggesting innovative solutions to keep the Program on track
                                                                                                                                                                                                           Collaborate in the preparation of polished presentations and detailed reports for leadership, ensuring that all materials are clear, relevant, and impactful for high-stakes discussions

## Foundational Build -- OW Support: Role Descriptions (3/3) {#slide-89}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Effectual
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Multiple Roles
  Provide hands‑on cloud migration & implementation support for the integration layer by executing cloud deployments, platform configuration and early proof‑outs to validate architecture and use cases
  Accelerate platform build activities by tracking progress and expediting deliverables with other 3 rd  party vendors and AA
  Support environment readiness & testing needs to help provision and stabilize test/dev environments that underpin vendor onboarding and integration activities
  Augment AA teams with cloud migration expertise and deliverables to accelerate knowledge transfer into internal MSS and reduce ramp time during the contract‑to‑hire conversion

## Q1 scorecard milestones Milestone statuses are tracked during weekly leadership team touchpoints {#slide-90}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Milestones                                       Target   Responsible                    Activities
  ------------------------------------------------ -------- ------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Develop FXIP in dev environment                  1/9      Infosys                        Develop 17 DFXIP microservices in dev environment Functionally test FXIP in dev environment
  Full non-prod environment ready                  1/13     ProServe                       Ensure non-prod environment supports application testing (e.g., integration, performance, load, chaos engr., etc.)
  Develop ASM  GraphQL  services in Dev            1/30     AA, Insights                   Develop all  GraphQL  service in the development environment
  Develop FinOps strategy                          2/13     AA                             Ensure budget estimates are reflected in  QuickSights  dashboard Clarify governance around FinOps management for NXOP
  Push FXIP to prod                                3/2      AA, Effectual-OW               Once FXIP is fully tested in non-prod and a hybrid DNS pattern / MSK authentication mechanism are implemented, FXIP will be pushed to the production environment
  Push ASM to prod                                 3/2      AA, Effectual-OW               Once ASM is fully tested in non-prod and a hybrid DNS pattern / MSK authentication mechanism are implemented, ASM will be pushed to the production environment
  Create state of the airline data feeds           3/13     AA                             Ensure data feeds required for operation applications are configured (e.g., Flight, weather, ADL, etc.)
  Initiate preparations for LPS integration        3/31     AA,  ProServe , Effectual-OW   Refine NXOP architecture to accommodate LPS vendor integration
  Initiate preparations for TPS integration        3/31     AA,  ProServe , Effectual-OW   Refine NXOP architecture to accommodate TPS vendor integration
  Initiate preparations for Crew Pay integration   3/31     AA,  ProServe , Effectual-OW   Refine NXOP architecture to accommodate Crew Pay vendor integration

## Slide 91

Appendix

## Definitions of ASM and FXIP ASM and FXIP are two distinct applications that support flight operations and are the focus of tabletop exercises {#slide-92}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Airline Slot Manager (ASM)

Flight Execution Integration Platform (FXIP)

- FAA allows AA 5 minutes to confirm slots required following delivery of the FAA Aggregate Demand List (ADL) file
- ASM is an AA-developed, Azure-based slot management tool to confirm slot availability by comparing the number of FAA slots with number of AA-required slots 
- Current compute requirements are limited, but potential future requirements to expand to integrate ATC Advisor into solution

<!-- -->

- FXIP was formally known as SOAR; functionally the same

<!-- -->

- Part of  Flight Planning System that provides dispatchers and pilots with flight plans

<!-- -->

- The Flight Planning System includes 3 components:

<!-- -->

- FlightKeys  5D Flight Planning application is a SaaS solution
- Cyberjet   Flight Management System is a SaaS solution
- Integration components deployed in Azure enable the communication between the two SaaS solutions and AA systems

<!-- -->

- FXIP is an integration components that brokers messages between  FlightKeys  and the AA-built  OpsHub

Pre-read

Confidential

## Slide 93

FXIP architectures

A.1

## FXIP architecture: Current state FXIP is currently in Azure, with a BCP instance in AWS {#slide-94}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A computer screen shot of a diagram

AI-generated content may be incorrect.](ppt/media/image181.png "Picture 13")

Confidential

## FXIP architecture: Phase 1a -- NXOP platform setup First, and integration layer and data layer are deployed in an AA AWS account {#slide-95}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A screenshot of a computer program

AI-generated content may be incorrect.](ppt/media/image182.png "Picture 11")

Confidential

## FXIP architecture: Phase 1b -- FXIP  Flightkeys  / CCI connector deployed in NXOP The integration layer is linked to the data layer {#slide-96}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software

AI-generated content may be incorrect.](ppt/media/image183.png "Picture 9")

Confidential

## FXIP architecture: Phase 1c -- FXIP proxy services deployed Proxy service are deployed in the NXOP integration layer {#slide-97}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a server

AI-generated content may be incorrect.](ppt/media/image184.png "Picture 7")

Confidential

## FXIP transition to NXOP FXIP cutover to NXOP can be achieved by adopting a low-risk path to production {#slide-98}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Objective

Seamless  cutover to AWS while maintaining Azure hot-standby  for production resilience

Achieve strict  RPO/RTO targets  before production switch to ensure parity and performance

Embed  rollback rehearsals  in every phase to mitigate risks and validate recovery

Ensure  minimal impact to down-stream systems

Transition summary

Dev environment ingests training/simulation/mock feeds via single EKS cluster in us-east-1

Determine which tools can be re-used from FXIP, and which need to be newly developed to achieve the following...

Simulate/mock  Flightkeys  messages  using Amazon MQ

Simulate/mock  API integrations  with  Flightkeys

Simulate/mock publishing messages  to/from Azure  OpsHub   EventHubs

Simulate/mock publishing messages  to/from On-Prem  OpsHub

Simulate/mock API interactions with  Azure/On-Prem Applications

Parity verification tool  between new services in AWS and existing services in Azure

Stage environment replicates production dual-region topology (us-east-1, us-west-2) and consumes  Flightkeys  staging queue

Explicit acceptance gates enforce promotions ( Dev→Stage→Prod ) with message parity =0% and MSK replicator lag p95 ≤ 10 seconds

Stage operations rehearsals validate business flows and observability controls

Weekly regional fail-over / fail-back, rollback drills to Azure to ensure operational readiness in stage

Comprehensive operational procedures, playbooks / runbooks, and incident response plans address cutover challenges and mitigate risk

Preliminary

## Evolution of testing and validation capabilities by environment Promotions from dev to stage to prod result in increasingly sophisticated tests that ultimately ensure a successful cutover {#slide-99}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Focused on  functional readiness  and  rollback rehearsals  for in-region failure

Uses  training / simulation / mock feeds only

Runs on single EKS KPAAS cluster  in us-east-1 region

Incorporates MSK with NLB and Route53  for traffic management

Utilizes Mock / Simulation tool   for development testing (or Dev  EventHubs , if available)

Parity verification tool  verifies parity between EventHub and MSK messages / schemas

Focused on  end-to-end functional integration, performance  and  resilience

Validates cutover readiness  through   operations rehearsals with automated tooling and rollback drills with  regional fail-over / fail-back testing

Runs on dual EKS KPAAS clusters  in us-east-1 and us-west-2 regions

Uses MSK bi-directional replication  to synchronize identical raw message topics to us-west-2

Integrates  Flightkeys  staging queue  for realistic input validation

Integration testing  with Stage on-prem  OpsHub  and Stage  EventHubs  for downstream systems in Azure

Achieves  parity target of = 0%  with existing services

Chaos testing  by injecting failures at each level (i.e., NXOP component, AWS service, availability zone, region)

Fully tested and verified capabilities for  operational resilience  and  performance

Consumes  Flightkeys  prod  queue  after:

Stage testing and validation completion

Approval for controlled promotion to prod

Operates full dual-region, multi-AZ stack ; publishes to / from   Azure  EventHubs  and on-prem  OpsHub

Retains Azure hot-standby  as fallback to ensure continuity in case of rollback

Sustains all KPIs consistently  for at least 30 days post-cutover with no Sev-1 incidents

Tested and verified tooling  for monitoring and observability

Playbooks and runbooks  for operational and incident management

Verified regional fail-over / fail-back   methodology  to mitigate risks

Preliminary

1. Development

2. Stage

3. Production

## Dev phases Dev phases are designed to validate functional requirements and prove equivalency before promotion to stage {#slide-100}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Dev phase & key tasks

Success criteria & KPIs for promotion of Dev → Stage 

- 24-hour data parity = 0% vs existing baseline in Azure
- 100% schema compatibility with baseline for messages and APIs
- API success rate ≥ 99.9%
- p95 latency within +10%
- Replicator lag p95 ≤ 15 seconds (if enabled)
- All component rollback steps completed in under 30 minutes
- Zero data loss during component rollback
- Security scans show zero critical CVEs

Preliminary

Dev phase 0: Readiness

- All NXOP Infrastructure and components deployed
- Mock services, parity verification services developed
- Schemas imported into AWS Glue Schema Registry

Dev phase 1:  Flightkeys  integrations

- Flightkeys  Mocked by Amazon MQ with EKS consuming and ingesting into MSK
- NXOP API Services testing using Mocks of  Flightkeys  APIs

Dev phase 2 :  OpsHub  Azure integrations

- Publishing  to/from  OpsHub  tested using Mocks of  OpsHub  services/feeds

Dev phase 3:  OpsHub  on-prem integrations

- Publishing to/from on-prem tested using Mocks of on-prem services/feeds

## Stage Phases Stage phases are designed to validate end-to-end integration, performance, and resilience before promotion to production {#slide-101}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Stage phases & key tasks

Success criteria & KPIs for promotion of Stage → Prod

- 7-day parity run comparing Stage environment against Production with Parity Δ ≤ 0% vs production
- Data delta  \<  0.1% for data consistency
- API success rate ≥ 99.9%
- p95 latency Δ ≤ 5% vs production 
- MSK Replicator lag p95 ≤ 15 seconds
- Up-stream and downstream systems integrations validated with end-to-end performance Δ ≤ 0.5% vs production
- Weekly fail-over / fail-back drills/tests complete within RPO / RTO KPIs
- Rollback to Azure tests complete within RPO / RTO KPIs
- Chaos / resiliency tests complete within RPO / RTO KPIs
- Operational procedures, playbooks / runbooks, incident response plans verified and signed off
- Operational Data hydration verified and signed off

Preliminary

Stage phase 0: Readiness

- All NXOP components deployed in us-east-1 and us-west-2 regions
- Route 53 health checks, DNS cut-over/failover services deployed
- Load Testing using Synthetic/Simulated data is done 

Stage phase 1:  Flightkeys  /  OpsHub  Azure & on-prem integrations

- Flightkeys  staging queue ingested via NXOP services into MSK
- Publishing to/from  OpsHubs  tested using Azure Stage environment
- Publishing to/from on-prem tested using on-prem stage environment

Stage phase 2 : Regional fail-over / fail-back testing

- Flightkeys  staging queue fail-over to west region testing
- NXOP regional fail-over, recovery and fail-back testing of NXOP

Stage phase 3: Rollback and resilience testing

- Test fail-back to Azure for rollback testing
- Chaos testing 

## FXIP architecture: Phase 1d -- Prepare for cutover of FXIP The new infrastructure in the AA AWS account is connected to  Flightkeys  and on-prem data  centers {#slide-102}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a computer program

AI-generated content may be incorrect.](ppt/media/image185.png "Picture 5")

Confidential

## FXIP architecture: Phase 1e -- FXIP live in NXOP Newly developed AWS infrastructure becomes the primary instance of FXIP {#slide-103}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software application

AI-generated content may be incorrect.](ppt/media/image186.png "Picture 3")

Confidential

## Slide 104

ASM architectures

A.2

## ASM Architecture: Current state {#slide-105}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a computer program

AI-generated content may be incorrect.](ppt/media/image187.png "Picture 17")

## ASM Architecture: Phase 2a -- NXOP platform setup for ASM {#slide-106}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software application

AI-generated content may be incorrect.](ppt/media/image188.png "Picture 16")

## ASM Architecture: Phase 2b -- NXOP integration layer is live {#slide-107}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software application

AI-generated content may be incorrect.](ppt/media/image189.png "Picture 14")

## ASM Architecture: Phase 2c -- ASM Flink jobs deployed in NXOP {#slide-108}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software system

AI-generated content may be incorrect.](ppt/media/image190.png "Picture 12")

## ASM Architecture: Phase 2d -- Solvers deployed in AWS {#slide-109}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software application

AI-generated content may be incorrect.](ppt/media/image191.png "Picture 10")

## ASM Architecture: Phase 2d -- ASM web app deployed in AWS {#slide-110}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A screenshot of a computer

AI-generated content may be incorrect.](ppt/media/image192.png "Picture 8")

## ASM Architecture: Phase 2e -- ASM live in AWS {#slide-111}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software application

AI-generated content may be incorrect.](ppt/media/image193.png "Picture 6")

## ASM Architecture: Phase 2e -- ASM live in AWS (read replica) {#slide-112}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

![A diagram of a software application

AI-generated content may be incorrect.](ppt/media/image194.png "Picture 2")

## Slide 113
