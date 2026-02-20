## Slide 1

\[Graphic: other: http://schemas.openxmlformats.org/presentationml/2006/ole\]

Foundational build

Follow-ups from Jan. 22 nd  foundational build working session

## Slide 2

Product team alignment with foundational build

1

## Slide 3

## Slide 4

Data governance

2

## NXOP Data Strategy & Governance How are we approaching data strategy, governance, and modelling standards to ensure alignment between NXOP, legacy platforms, new applications, and vended solutions?   {#slide-5}

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

From 1/22 VP meeting

## NXOP Data Model Strategy & Governance For discussion    {#slide-6}

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

![Gears outline](ppt/media/image16.png "Graphic 66")

Legacy Integrations

![Gears outline](ppt/media/image16.png "Graphic 68")

OpsHub

Transformation

Layer

From 1/22 VP meeting

## Proposed data ownership The program must establish clear accountability by designating owners for each data area. This will enhance transparency, streamline decision-making, and promote collaboration, driving our objectives forward. {#slide-7}

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

From 1/22 VP meeting

## Slide 8

NXOP data scope

3

## Slide 9

## Slide 10
