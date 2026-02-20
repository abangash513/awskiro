# Ownership and Governance

## Overview

This document outlines the product management model, governance framework, and operational responsibilities for the NXOP. It defines how teams interact with the platform across three distinct usage patterns and establishes clear accountability for development, maintenance, and operations.

The governance model ensures that platform investments align with enterprise strategy while maintaining team autonomy and operational excellence. This framework supports decision-making for when capabilities should be built **into**, **on top of**, or **outside** the platform.

## Team Structure

The NXOP ecosystem operates with two primary team types, each with distinct roles, responsibilities, and operational models:

### Platform Team

The **Platform Team** is responsible for building, maintaining, and evolving the shared infrastructure and capabilities that enable multiple operational solutions. This team operates as an internal service provider, focusing on creating reusable, scalable, and reliable platform services.

**Core Characteristics:**
- **Product Mindset Model**: Treats other teams as customers and focuses on developer experience
- **Horizontal Responsibility**: Owns capabilities that span across multiple business domains
- **Infrastructure Focus**: Manages underlying compute, data, networking, and security infrastructure when not delegated to the Enterprise or other teams
- **Standards Ownership**: Defines and maintains technical standards, patterns, and best practices based on the Enterprise
- **Long-term Perspective**: Focuses on platform evolution, scalability, and architectural consistency

**Key Responsibilities:**
- Design and implement shared platform capabilities (compute, data, observability, security)
- Provide self-service tools and documentation for Application Teams
- Maintain service level agreements (SLAs) for platform services
- Offer architectural consultation and technical guidance
- Manage platform-wide governance, compliance, and security controls

**Success Metrics:**
- Platform adoption rates across Application Teams
- Developer productivity and satisfaction scores
- Platform reliability and performance metrics
- Time-to-onboard new solutions and teams

### Application Team

**Application Teams** (also referred to as Solution Teams) are responsible for delivering business-specific operational solutions by leveraging platform capabilities and building domain-specific functionality.

**Core Characteristics:**
- **Product Focus**: Owns end-to-end delivery of specific operational solutions (e.g., crew scheduling, flight operations)
- **Vertical Responsibility**: Deep expertise in specific business domains and operational workflows
- **Customer Delivery**: Directly responsible for delivering value to operational end-users
- **Agility Focus**: Optimizes for rapid delivery and iteration within their domain
- **Platform Consumer**: Leverages platform services to accelerate solution delivery

**Key Responsibilities:**
- Develop and maintain business logic for specific operational domains
- Integrate with platform services following established patterns and standards
- Configure solution-specific monitoring, alerting, and operational procedures
- Respond to solution-specific incidents and performance issues
- Ensure compliance with platform standards and enterprise policies

**Success Metrics:**
- Solution delivery velocity and quality
- Operational business outcomes and user satisfaction
- Platform standards compliance rates
- Solution reliability and performance metrics

### Team Interaction Model

**Platform-as-a-Service Relationship:**
- Platform Team provides capabilities as services with clear APIs, Topics, Queues, and SLAs
- Application Teams consume platform services through self-service interfaces
- Regular feedback loops ensure platform evolution meets Application Team needs
- Shared responsibility model for overall system reliability and performance

**Collaboration Patterns:**
- **Consultation**: Platform Team provides architectural guidance for complex integrations
- **Standards Alignment**: Application Teams follow platform standards while maintaining solution autonomy
- **Feedback Loop**: Application Team requirements drive platform capability roadmap
- **Shared Ownership**: Both teams collaborate on cross-cutting concerns like security and compliance

## Platform Usage Patterns

The NXOP supports three primary usage patterns, each with distinct criteria and governance approaches:

### Platform Usage Patterns

The NXOP supports three primary usage patterns, each with distinct criteria and governance approaches:

(Jason: To add explicitly we have the policies and controls in place for each shared or used service)

| Pattern | Criteria | Governance | Examples |
|---------|----------|------------|----------|
| **Building INTO the Platform** | Shared capabilities serving two or more operational solutions | Platform Architecture Board approval required | • Real-time flight status processing<br>• Crew scheduling optimization engine<br>• Aircraft maintenance prediction models<br>• Weather data aggregation and analysis<br>• Common alerting and notification services |
| **Building ON TOP of the Platform** | Solutions leveraging one or more shared platform services | Self-service with platform standards compliance | • Solution-specific dashboards using platform data services<br>• Custom operational workflows using platform compute capabilities<br>• Integration applications using platform messaging services<br>• Reporting applications using platform observability stack |
| **Building OUTSIDE the Platform** | Solutions that don't meet the criteria for the first two patterns | Full team autonomy with enterprise architecture alignment | • Proof-of-concept applications<br>• Solution-specific infrastructure with unique requirements<br>• Vendor solutions with incompatible architectures<br>• Legacy system integrations with specific compliance needs |

#### Example Usage

A solution may require that NXOP modifies or adds a new capability (to the benefit of NXOP and solutions using it), while also leveraging an existing capability (such as managed data processing), and can still have infrastructure outside of NXOP (such as a bespoke data product to satisfy its workload requirements).

Take ASM as a solution that would leverage NXOP's data processing capabilities and data exposure capability via well-defined API contract and perhaps needs modification to meet a functional requirement. A request would be made for building into the platform while building on top of the data processing layer and deploying compute code. Outside of NXOP, ASM would have a web application that interfaces with the well-defined API contact capability.

## Request and Decision Framework

### Platform Enhancement Requests

#### 1. Intake Process
1. **Submission**: Submit request via Platform Enhancement Request (PER) template
2. **Initial Screening**: Platform team conducts feasibility assessment (5 business days)
3. **Architecture Review**: Platform Architecture Board evaluation (2 weeks)
4. **Decision**: Approval/rejection with rationale and timeline

#### 2. Evaluation Criteria
- **Strategic Alignment**: Supports 2+ operational solutions
- **Technical Feasibility**: Compatible with platform architecture
- **Resource Impact**: Development effort and ongoing maintenance costs
- **Business Value**: Quantifiable operational improvement
- **Risk Assessment**: Security, compliance, and operational risks

#### 3. Priority Framework
- **P0 - Critical**: Safety, compliance, or major operational disruption
- **P1 - High**: Direct operational efficiency gains for multiple solutions
- **P2 - Medium**: Operational improvements or developer experience enhancements
- **P3 - Low**: Nice-to-have features or optimizations

## Team Responsibilities

### Platform Team Responsibilities

#### Development and Maintenance
- **Platform Services**: Design, develop, and maintain core platform capabilities
- **Infrastructure**: Manage underlying infrastructure, scaling, and capacity planning
- **Standards**: Define and evolve technical standards and patterns
- **Documentation**: Maintain comprehensive platform documentation and onboarding guides

#### Support and Enablement
- **Developer Experience**: Provide tooling, templates, and self-service capabilities
- **Training**: Conduct platform onboarding and ongoing education
- **Consultation**: Architecture guidance for Application Teams
- **SLA Management**: Monitor and maintain platform service level agreements

#### Governance
- **Change Management**: Review and approve platform-wide changes
- **Security**: Implement and maintain security controls and monitoring
- **Compliance**: Ensure platform meets regulatory and enterprise requirements
- **Cost Optimization**: Monitor and optimize platform operational costs

### Application Team Responsibilities

#### Development
- **Application Logic**: Develop and maintain solution-specific business logic
- **Integration**: Implement proper integration patterns with platform services
- **Testing**: Comprehensive testing including platform integration scenarios
- **Documentation**: Maintain solution documentation and runbooks

#### Operations
- **Deployment**: Execute deployments following platform deployment patterns
- **Monitoring**: Configure solution-specific monitoring and alerting
- **Incident Response**: Respond to solution-specific incidents
- **Performance**: Monitor and optimize solution performance

#### Compliance
- **Standards Adherence**: Follow platform standards and patterns
- **Security**: Implement solution-level security controls
- **Data Governance**: Comply with data management and privacy policies
- **Change Management**: Follow platform change management processes

## Platform Capability Usage Guidelines

### Compute Platform (Amazon EKS)

#### When to Use
- Operational workloads requiring containerized deployment
- Applications needing auto-scaling and high availability
- Services requiring service mesh capabilities
- Workloads needing platform observability integration

#### Application Team Responsibilities
- **Application Packaging**: Create and maintain container images following platform standards
- **Resource Management**: Define appropriate resource requests and limits
- **Health Checks**: Implement proper liveness, readiness, and startup probes
- **Configuration**: Use platform-approved configuration management patterns

#### Platform Team Responsibilities  
- **Cluster Management**: Maintain EKS clusters, node groups, and networking
- **Security**: Manage RBAC, network policies, and security scanning
- **Monitoring**: Provide cluster-level observability and alerting
- **Standards**: Maintain deployment templates and best practices

#### Compliance Requirements
- Use approved base images from platform-managed registry
- Follow resource tagging standards for cost allocation
- Implement required security contexts and policies
- Configure logging to platform-managed aggregation services

#### Deployment Responsibilities (RACI Matrix)

| Activity | Application Team | Platform Team | Description |
|----------|---------------|---------------|-------------|
| **Pipeline Creation & Configuration** | R/A | C | Application Team creates and maintains deployment pipelines using platform-provided templates and standards |
| **Pipeline Infrastructure & Templates** | I | R/A | Platform team provides and maintains CI/CD infrastructure, base templates, and deployment tools |
| **Application Build Process** | R/A | C | Application Team defines build steps, dependencies, and artifact creation within platform guidelines |
| **Security Scanning Integration** | R | A | Application Team configures required security scans; platform team enforces scanning policies |
| **Environment Promotion** | R/A | C | Application Team manages promotion through environments following platform-defined gates |
| **Deployment Strategy Selection** | R/A | C | Application Team chooses appropriate deployment strategy (canary, blue/green, rolling) based on workload needs |
| **Canary Configuration** | R | A | Application Team defines canary parameters (traffic %, success criteria); platform team provides tooling |
| **Blue/Green Setup** | R | A | Application Team configures blue/green parameters; platform team maintains switching infrastructure |
| **Pre-deployment Testing** | R/A | I | Application Team implements and maintains pre-deployment test suites |
| **Deployment Execution** | R | A | Application Team triggers deployments; platform team ensures deployment infrastructure availability |
| **Deployment Monitoring** | R | A | Application Team monitors application-specific deployment metrics; platform team monitors platform deployment health |
| **Rollback Decisions** | R/A | C | Application Team makes rollback decisions based on application health and business impact |
| **Rollback Execution** | R | A | Application Team initiates rollback; platform team ensures rollback mechanisms function correctly |
| **Post-deployment Verification** | R/A | C | Application Team validates deployment success through health checks and functional testing |
| **Deployment Alerting Configuration** | R | A | Application Team configures application-specific deployment alerts using platform alerting infrastructure |
| **Deployment Failure Investigation** | R | A | Application Team investigates application-level failures; platform team investigates platform-level issues |
| **Pipeline Maintenance** | R/A | C | Application Team maintains solution-specific pipeline logic; platform team maintains base infrastructure |
| **Deployment Metrics & Reporting** | R | A | Application Team defines success metrics; platform team provides deployment analytics infrastructure |

**RACI Legend:**
- **R** = Responsible (does the work)
- **A** = Accountable (ensures completion)  
- **C** = Consulted (provides input)
- **I** = Informed (kept updated)

#### Application Team Responsibilities
- **Pipeline Definition**: Create and maintain deployment pipelines using platform templates
- **Build Configuration**: Define build steps, test execution, and artifact packaging
- **Deployment Strategy**: Select and configure appropriate deployment patterns (canary, blue/green)
- **Success Criteria**: Define health checks, success metrics, and rollback triggers
- **Environment Management**: Configure environment-specific parameters and promotion gates
- **Monitoring Integration**: Implement application-level deployment monitoring and alerting
- **Incident Response**: Respond to deployment failures and coordinate rollbacks when needed

#### Platform Team Responsibilities
- **Pipeline Infrastructure**: Maintain CI/CD infrastructure, runners, and deployment tools
- **Template Management**: Provide and update deployment pipeline templates and patterns
- **Deployment Tooling**: Manage canary, blue/green, and progressive delivery tooling
- **Security Integration**: Enforce security scanning, compliance checks, and approval gates
- **Infrastructure Monitoring**: Monitor deployment infrastructure health and performance
- **Standards Enforcement**: Ensure deployments follow platform security and compliance standards
- **Troubleshooting Support**: Assist with platform-level deployment issues and optimization

#### Compliance Requirements
- Use platform-approved deployment templates and patterns
- Implement required security scans and approval gates
- Follow environment promotion and change management processes
- Configure deployment logging for audit and compliance purposes
- Maintain deployment artifacts according to retention policies


### Observability Platform

#### When to Use
- Applications requiring centralized logging, metrics, and tracing
- Operational dashboards and alerting needs
- Performance monitoring and troubleshooting
- Compliance and audit trail requirements

#### Application Team Responsibilities
- **Instrumentation**: Implement application-level metrics, logs, and traces
- **Dashboard Creation**: Build solution-specific operational dashboards
- **Alert Configuration**: Define and maintain solution-specific alerts
- **Incident Response**: Use observability data for troubleshooting

#### Platform Team Responsibilities
- **Infrastructure**: Maintain observability infrastructure (Prometheus, Grafana, ELK stack)
- **Data Retention**: Manage data retention policies and storage optimization
- **Access Control**: Implement role-based access to observability data
- **Integration**: Provide SDKs and libraries for easy instrumentation

#### Compliance Requirements
- Log sensitive data in accordance with data classification policies
- Use structured logging formats for consistency
- Configure appropriate log levels for different environments
- Implement distributed tracing for complex operational workflows

### Data Platform

#### When to Use
- Real-time operational data processing needs
- Historical data analysis and reporting
- Data sharing across multiple solutions
- ML/AI model training and inference

#### Application Team Responsibilities
- **Data Contracts**: Define and maintain data schemas and contracts
- **Quality**: Implement data validation and quality checks
- **Lineage**: Document data sources and transformations
- **Access Patterns**: Optimize data access for performance

#### Platform Team Responsibilities
- **Infrastructure**: Manage data storage, processing, and streaming infrastructure
- **Governance**: Implement data governance policies and access controls
- **Pipeline Management**: Provide data pipeline orchestration and monitoring
- **Security**: Encrypt data at rest and in transit

#### Compliance Requirements
- Classify data according to enterprise data classification policy
- Implement appropriate retention and deletion policies
- Ensure data residency requirements are met
- Maintain audit trails for data access and modifications

## Governance Bodies

### Platform Architecture Board
**Purpose**: Strategic oversight and architectural governance
**Members**: Chief Architect, Platform Lead, Security Lead, 2 Solution Architects
**Cadence**: Bi-weekly
**Responsibilities**:
- Approve major platform enhancements
- Review architectural decisions
- Resolve cross-team technical disputes
- Align platform roadmap with business strategy

### Platform Operations Council
**Purpose**: Operational excellence and incident management
**Members**: Platform SRE Lead, Application Team Leads, Operations Manager
**Cadence**: Weekly
**Responsibilities**:
- Review platform performance and reliability
- Coordinate incident response across teams
- Optimize operational procedures
- Plan maintenance and capacity changes

### Standards Working Group
**Purpose**: Technical standards and developer experience
**Members**: Platform Engineers, Solution Engineers, DevOps Engineers
**Cadence**: Monthly
**Responsibilities**:
- Develop and maintain technical standards
- Review and approve new tools and technologies
- Improve developer experience and productivity
- Share best practices and lessons learned

## Exception Management

### Exception Request Process
1. **Documentation**: Complete exception request template with business justification
2. **Review**: Platform Architecture Board assessment
3. **Approval**: Chief Architect approval for architectural exceptions
4. **Monitoring**: Track exception usage and impact
5. **Review Cycle**: Annual review of all active exceptions

### Exception Categories
- **Architectural**: Deviation from standard platform patterns
- **Security**: Alternative security implementations
- **Compliance**: Different regulatory compliance approaches
- **Technology**: Use of non-standard tools or technologies

### Exception Criteria
- Clear business or technical justification
- Risk assessment and mitigation plan
- Defined expiration date or review cycle
- Commitment to future alignment path

## Change Management

### Platform Changes
TBD

### Communication Strategy
- Monthly platform newsletter with updates and best practices
- Quarterly architecture review meetings
- Annual platform strategy sessions
- Real-time notifications for breaking changes or incidents

### Version Management
- Semantic versioning for all platform services
- Backward compatibility guarantees for major versions
- Deprecation notices with 6-month minimum timeline
- Clear migration paths for breaking changes
