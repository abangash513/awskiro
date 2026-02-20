## Slide 1

FOS Sunset -- Foundational Blueprint

Architecture Update

January 22, 2026

## Agenda {#slide-2}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  1   Inform:  Foundational Blueprint Progress Update
  --- -------------------------------------------------------------
  2   Inform:  Data Strategy and Governance
  3   Inform:  FOS Decomm & TDEC MIPS/Resource Utilization Update

Confidential

## Slide 3

Foundational Blueprint Progress Update

1

## Foundational blueprint workstream: recent progress and risks Overall workstream status continues to be green; Production environment, initial systems integration framework, and app migration framework were delivered during the second half of December; There remains risks associated with FXIP development/testing and the cloud provider RFI timelines {#slide-4}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Progress since December:

A

B

Developed initial first mover systems integration framework  to inform Procurement\'s contracting structures on Dec 18., with validation from Business and IT leads

Confidential

C

Developed initial application migration framework  on Dec. 18

Risks:

![](ppt/media/image17.png "ico-check")

![](ppt/media/image17.png "ico-check")

completion of significant deliverable

![](ppt/media/image17.png "ico-check")

![](ppt/media/image17.png "ico-check")

Completed and documented the NXOP production environment  on Dec 30

![](ppt/media/image17.png "ico-check")

## Foundational blueprint workstream upcoming milestones Development of the FXIP in non-prod is delayed due to internal/external dependencies, with timelines pending clarification by 1/23; All other workstream milestones are on track {#slide-5}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

     Upcoming milestone                                  Target date   Status     Notes
  -- --------------------------------------------------- ------------- ---------- ----------------------------------------------------------------------------------------------------
     Develop NXOP integration layer (FXIP) in non-prod   Jan. 9        Delayed    Working with the OpsHub team to establish connectivity for critical data required in NXOP for FXIP
     Full non-prod environment ready                     Jan. 21       Complete   Demo and handover session of the non-production environment done on 1/21
     Develop ASM GraphQL services in dev                 Jan. 30       On track   AA networking team is developing infrastructure to connect with FAA data feeds to prevent delays
     Develops FinOps strategy                            Feb. 13       On track   No blockers; AA FinOps team has been engaged
     Identify Crew Pay data dependencies                 Feb. 20       On track   No blockers; Initial discovery sessions have started
     Push FXIP to prod                                   Mar. 2        On track   No blockers; prod go-live timelines include a cushion for development delays
     Push ASM to prod                                    Mar. 2        On track   No blockers; prod go-live timelines include a cushion for development delays

A

B

C

D

E

F

Confidential

G

## Slide 6

Data strategy and governance

2

## NXOP Data Strategy & Governance How are we approaching data strategy, governance, and modelling standards to ensure alignment between NXOP, legacy platforms, new applications, and vended solutions?   {#slide-7}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Confidential

Draft

Discussion Topics (not exhaustive)

- Who will be accountable for defining NXOP data strategy, governance, ownership, data quality, and other foundational principles ?
- Who will be accountable for defining the business data model, data catalogue and metadata management, and technical stewardship?
- How will vendor solution data structures influence NXOP?
- How will NXOP standards align with broader enterprise data strategy?
- What is the approach to ensuring NXOP accommodates legacy data models while enabling innovation and improvement?
- What guiding principles and standards will inform NXOP data impacts to downstream systems? Who is responsible for ensuring compliance?
- What are the business/functional requirements for data (e.g., historical data retention, snapshots, privacy and regulatory compliance, data residency, data lineage tracking, etc.)?
- What are the non-functional requirements (e.g., security controls, compliance controls, latency, availability, velocity, etc.) that need to be adhered to?
- Who is responsible for ensuring data standards compliance (E.g. Transactional workloads, day-of optimizers, long-term analytics)?
- How should "data products" be considered in the context of NXOP?
- How do we ensure AI-readiness of NXOP data?
- 

As FXIP prepares for its transition to a production environment, and data integration with the first AA systems is set to commence, it is imperative to formalize a data strategy and governance framework.

- 

Now is the right time to revisit this discussion

- The NXOP team discussed Data Management as a persistent theme during PI Planning
- The systems implementation workstream has started to discuss data requests from the first movers
- 

How do we want to proceed

- Lakshmi Lanka, Kevin Keyes, and Oliver Wyman have agreed to coordinate multiple working sessions in the upcoming weeks to clarify current state and expand on existing methods and resource requirements

Are there other questions we need to answer?

## NXOP Data Model Strategy & Governance For discussion    {#slide-8}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Confidential

Draft

- Build a governed,  canonical  domain data model as the single source of semantic truth for operations.
- Use  data contracts + schema registries + APIs  to guarantee integration between legacy, new, and vendor systems.
- Establish a formal  data governance and product model  (roles, workflows, standards) to guide intentional evolution.
- Deliver this through an incremental program: design canonical model → implement interoperability layer (APIs, adapters) → migrate & validate → operate & evolve with metrics.

NXOP

Flights

Crew

?

?

Load

?

FOS

Legacy Solutions

Custom Solutions

Vendor Solutions

Legacy Integrations

Future Integrations

![Gears outline](ppt/media/image20.png "Graphic 66")

Legacy Integrations

![Gears outline](ppt/media/image20.png "Graphic 68")

OpsHub

Transformation

Layer

## Proposed data ownership The program must establish clear accountability by designating owners for each data area. This will enhance transparency, streamline decision-making, and promote collaboration, driving our objectives forward. {#slide-9}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Confidential

Draft

  Data area                  Responsible Teams / Org                                      
  -------------------------- ------------------------------------------------------------ ---------------------------------
                             Option 1 -- Align with enterprise tool set                   Option 2 -- Autonomous tool set
  Data product               Ops planning & performance  Airline operations technology    
  Data model                 Ops planning & performance  Airline operations technology    
  Data movement              Ops planning & performance  Airline operations technology    
  Data lake pipeline         Data Engineering, Automation, & Analytics                    Airline operations technology 
  Data lake infrastructure   Data Engineering, Automation, & Analytics                    Airline operations technology 

## Slide 10

FOS Decomm & TDEC MIPS/Resource Utilization Update

3

## Flight Milestones -- Path to Green {#slide-11}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Status   
  -------- --

  ID   Feature/Activity Title                                          Team     Target Date   Status     Risks   Dependencies         Comments
  ---- --------------------------------------------------------------- -------- ------------- ---------- ------- -------------------- ---------------------------------------------------------------------------
  1    Confirm and refine TPS/LPS discovery target dates               FOS      1/23/26       On track                                Analysis to provide estimated discovery timeline in progress
  2    Identify dependencies on capabilities  external  to FOS (TPS)   OpsHub   1/31/26       On Track                                Co-Pilot will be utilized​; Analysis in progress
  3    Identify dependencies on capabilities  external  to FOS (LPS)   OpsHub   1/31/26       On track                                Co-Pilot will be utilized​; Analysis in progress
  4    Create migration strategy for TPS capability                    FOS      1/31/26       On Track           Vendor selection\*   Analysis in progress; may depend on vendor selection
  5    Create migration strategy for LPS capability                    FOS      2/28/26       On Track           Vendor selection\*   Dependent on vendor selection
  6    Identify dependencies on capabilities  internal  to FOS         FOS      3/31/26\*     On Track                                Discovery underway; dates to be adjusted based on estimates provided 1/23
  7    Identify the data elements to patch back to FOS (TPS)           FOS      3/31/26\*     On Track           Vendor selection\*   Will evolve as discovery of capabilities internal to FOS is completed.
  8    Identify the data elements to patch back to FOS (LPS)           FOS      3/31/26\*     On track           Vendor selection\*   Will evolve as discovery of capabilities internal to FOS is completed.

\* Indicates dates subject to change based on high-level estimates; Refined estimates targeted 1/23

## Crew Pay Milestones -- Path to Green {#slide-12}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

  Status   
  -------- --

  ID   Feature/Activity Title                                                      Team                 Target Date   Status          Risks                                               Dependencies   Comments
  ---- --------------------------------------------------------------------------- -------------------- ------------- --------------- --------------------------------------------------- -------------- --------------------------------------------------------------------
  1    Identify the data elements in FCRM                                          FOS                  12/19/25      Complete                                                                           Completed on 12/17​
  2    Confirm and refine Crew Pay discovery target dates                          FOS                  1/31/26       On track                                                                           Commitment to provide refined dates by 1/31 as of 1/13
  3    Confirm and refine Crew Pay discovery target dates after vendor selection   FOS                  TBD           Not started                                                                        
  4    Identify the FOS source record of FCRM identified fields                    FOS                  2/10/26\*     On track                                                                           Kicked off identification as of 1/13
  5    Identify Crew Comp Excel macros                                             Crew Pay BU          2/10/26\*     On track                                                                           List of processes identified and gathering details.
  6    Identify 3 rd  party reports for Crew Comp                                  Crew Pay BU          3/24/26\*     Not Started                                                                        Dependent on other teams to provide info​
  7    Ops/Crew Hub & External Apps dependency plan                                OpsHub  /  CrewHub   3/31/26\*     On track        FOS-09-00 -- many teams that need to be consulted                  Completed 2 of 3 sessions with Ops/Crew Hub consumers
  8    Identify Crew Comp mid-range apps impact                                    Crew Pay Mid-range   4/7/26\*      On track                                                                           Template to gather information is finalized. Kicked off as of 1/13
  9    Identify applications that have a dependency on FCRM                        Crew Pay / DE        4/7/26\*      Not Started                                                                        
  10   FOS displays/command catalog complete with disposition draft                FOS                  5/26/26\*     Not Started                                                                        
  11   Identify the data element gaps in Crew/Ops Hub and FCRM feed                OpsHub  /  CrewHub   5/26/26\*     Not Started                                                                        
  12   Any impact to non-pay processes within FOS                                  FOS                  7/14/26\*     Not  S tarted                                                                      Pramod due diligence complete; Need DXC deep dive
  13   FOS Screen Scraping (external to Crew Comp)                                 FOS                  8/11/26\*     Not Started                                                                        Smaller effort; dependent on other teams

\* Indicates dates subject to change based on high-level estimates; Refined estimates targeted 1/31

Priority Note:  Split Duties and FOS Decomm are both running in parallel; Team members from 3+ Squads will contribute to Crew Pay Discovery activities in Release 1.

## TDEC MIPS/Resource Utilization -  update for reference Our ongoing approach is to focus on our two guiding principles:  Be as non-disruptive as possible  and  avoid capital costs  {#slide-13}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Progress to date: 

AA experts have engaged IBM and DXC in parallel to provide options to address our capacity risk and mitigate the need to invest approximately \$10 million in funds to establish a new testing environment. 

This week, the IBM engagement has resulted in the following approaches:

- 
- 
- 

Proposed next steps :

- The engagement with IBM will be compared to DXC log analysis and choose the best approach 

<!-- -->

- Options 2 is not aligned with the approach that AA is willing to consider
- 

<!-- -->

- We will continue our parallel engagement with DXC, as we have been doing over the past months

<!-- -->

- We will review DXC's current monitoring process to ensure it achieves the same level of insight as Approach 1 from IBM

  1   Mainframe Capacity & MIPS Optimization   -- IBM will review the server logs to identify high usage areas in TDEC
  --- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  2   Leverage IBM's AI tools to review the identified segments  -- Based on the results from Option 1, IBM will then use their AI tools to review the areas consuming the most resources and provide suggestions

## Slide 14

Appendix Material

A

## FOS  Decomm  Recent Progress {#slide-15}

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Crew Pay

-  Completed the identification of FCRM data elements 
-  Finalized template to capture the Crew comp mid-range and BU owned excel macros 
-  Kicked off identification of Crew Comp mid-range apps and the FOS source record of FCRM
-  PI planning complete on 1/14; priority & workload assigned to multiple squads dedicated to FOS discovery work
-  Completed all three working sessions with 90 potentially dependent product teams for the "Ops/Crew Hub & External Apps dependency plan" milestone
-  Continued to refine initial target dates for 11 Crew Pay milestones - on track for 1/31 validation

Flight

-  Identified 21 systems  so far  dependent on LPS data and held dependency analysis / working sessions on week of 1/12

<!-- -->

- Engaged external owners dependent on LPS data, results utilized in requirements and migration planning
- TPS external dependencies are much more contained than LPS; continued analysis in progress for completion 1/31

<!-- -->

-  Continued hands-on code analysis to determine full decommissioning and design for LPS & TPS

<!-- -->

- Analysis/discovery includes TPF code review of all potentially impacted systems; discovery is in progress for ACARS, FOS Cargo, DECS, FIMI, OASIS, TPS, WSS, XP/XML

<!-- -->

- TPS / LPS Initial Migration Strategy document is complete; final review to be complete by 1/31
- Continued to refine initial target dates for discovery -- on track for 1/23 validation 

## Slide 16
