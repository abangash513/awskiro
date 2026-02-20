# NXOP (Next Gen Operations Platform) Wiki

## Overview

This document defines the comprehensive standards and guidelines for NXOP (Next Gen Operations Platform) projects within American Airlines.

## Product Details

- **Archer Application Name**: Next Gen Operations Platform
- **App Short Name**: OpsPlatNxt
- **Squad 360**: 4721023
- **Criticality**: Discretionary (Vital after Go Live)

### Contacts

- **Application Owner**: Lakshmi Narayana Lanka (lakshmi.lanka@aa.com)
- **Architect**: Praveen Chand (praveen.chand@aa.com)

---

## NXOP Repository List

📖 **[Complete NXOP Repository List](docs/nxop-repo-list.md)**

## CI/CD Pipelines

- 📖 **[DTE Reusable Workflows](docs/CICD.md)** - Taxiway pipelines for Java/Maven/SpringBoot applications
- 📖 **[MSF Pipeline for Apache Flink Applications](docs/msf-pipeline.md)** - Reusable workflows for Flink streaming applications

## Repository Creation Instructions

### Naming Convention

All NXOP repositories must follow the standardized naming convention:

- **Format**: `nxop-<service-name>`

- **Example**: `nxop-flight-tracker`, `nxop-crew-management`, `nxop-maintenance-api`

### Repository Setup Process

#### Step 1: Create Repository

1. Create a new repository in AAInternal with the `nxop-` prefix
2. Follow the naming convention: `nxop-<app-name>`
3. Ensure repository name is clear and descriptive

#### Step 2: Add Administrator

1. Add **Praveen Chand** (`praveen-ynwa`) as repository administrator
2. Grant full admin permissions for repository management

#### Step 3: Enterprise Compliance Setup

1. Navigate to the [NXOP Admin Workflow](https://github.com/AAInternal/nxop-admin-workflow/actions/workflows/setup-repo.yaml)
2. Run the **Setup Repo** workflow
3. **Purpose**: Ensures compliance with AA Enterprise Guidelines
4. **What it configures**:
   - Required branch protection rules
   - Security policies and scanning
   - Standard workflow templates
   - Required files and documentation templates
   - Enterprise governance settings

#### Step 4: Verification

After running the admin workflow, verify the following are configured:

- [ ] Branch protection rules enabled on `main` branch
- [ ] Required status checks configured
- [ ] Security scanning enabled (CodeQL, Dependabot)
- [ ] Standard workflow files present
- [ ] Required documentation templates added
- [ ] Compliance policies applied

### Important Notes

- **Always run the admin workflow** - This is mandatory for all NXOP repositories
- **Repository naming is enforced** - Non-compliant names may be rejected
- **Admin access required** - Praveen Chand must have admin access for governance oversight
- **Enterprise compliance** - The setup workflow ensures adherence to AA security and governance standards

## Table of Contents

- [Platform Charter](##platform-charter)
- [Repository Creation Instructions](#repository-creation-instructions)
- [Technology Stack](#technology-stack)
- [Cloud Infrastructure](#cloud-infrastructure)
- [Development Framework](#development-framework)
- [Architecture Patterns](#architecture-patterns)
- [Documentation Standards](#documentation-standards)
- [Branching Strategy](#branching-strategy)
- [Coding Standards](#coding-standards)
- [Testing Standards](#testing-standards)
- [Security Standards](#security-standards)
- [Deployment Standards](#deployment-standards)
- [Monitoring and Observability](#monitoring-and-observability)
- [Data Management](#data-management)
- [API Standards](#api-standards)
- [Performance Standards](#performance-standards)
- [Compliance and Governance](#compliance-and-governance)
- [Naming Conventions](#naming-conventions)
- [Tagging](#tagging)

---

## Platform Charter

Please click [here](/docs/charter/_charter.md) for detailed view of the charter including vision, mission statement, principles, scope, platform responsibilities, app / system level responsibities, and more

## Technology Stack

### Primary Technologies

- **Cloud Platform**: AWS (Amazon Web Services)
- **Container Orchestration**: Amazon EKS (Elastic Kubernetes Service)
- **Message Streaming**: Amazon MSK (Managed Streaming for Apache Kafka)
- **Microservices Framework**:
- **Programming Languages**:
  - Primary: TBD
  - Secondary: TBD
- **Database Technologies**: DocumentDB
- **API Framework**: TBD

### Support Technologies

- **CI/CD Platform**: GitHub Actions
- **Infrastructure as Code**: Terraform
- **Service Mesh**: TBD
- **API Gateway**: TBD
- **Load Balancing**: AWS Elastic Load Balancers (Application Load Balancers and Network Load Balancers)

> **Note**: Technology decisions are being finalized. This section will be updated as decisions are made.

---

## Cloud Infrastructure

### AWS Services Standards

#### Core Services

- **Compute**: Amazon EKS for containerized workloads
- **Messaging**: Amazon MSK for event streaming
- **Storage**: S3 (Object Storage)
- **Database**: DocumentDB
- **Networking**: AWS VPC and AWS Transit Gateway

#### Multi-Region Strategy

- **Primary Region**: us-east-1
- **Secondary Region**: us-west-2
- **Disaster Recovery**: TBD
- **Data Replication**: TBD

#### Environment Strategy

- **Development**: dev (aa-aws-nxop-dev)
- **Testing/Staging**: non-prod (aa-aws-nxop-nonprod)
- **Production**: prod
- **Sandbox**: poc (aa-aws-nxop-poc)

> **Note**: Specific AWS service configurations and region strategies are under review.

---

## Development Framework

### Application Architecture

- **Pattern**: TBD
- **Communication**: TBD
- **State Management**: TBD
- **Configuration Management**: TBD

### Development Lifecycle

- **Planning**: TBD
- **Development**: TBD
- **Testing**: TBD
- **Deployment**: TBD
- **Monitoring**: TBD

---

## Architecture Patterns

### System Architecture Patterns

- **Microservices Architecture**: TBD
- **Event-Driven Architecture**: TBD
- **Domain-Driven Design**: TBD
- **CQRS (Command Query Responsibility Segregation)**: TBD
- **Event Sourcing**: TBD

### Integration Patterns

- **API-First Design**: TBD
- **Event Streaming**: TBD
- **Circuit Breaker**: TBD
- **Bulkhead**: TBD
- **Retry Patterns**: TBD

### Data Patterns

- **Data Lake**: TBD
- **Data Mesh**: TBD
- **CDC (Change Data Capture)**: TBD
- **CQRS**: TBD

---

## Documentation Standards

### Required Documentation

- **README.md**: Project overview, setup, and usage
- **API Documentation**: OpenAPI/Swagger specifications
- **Architecture Decision Records (ADRs)**: TBD format
- **Runbooks**: Operational procedures
- **Disaster Recovery Plans**: TBD

### Documentation Tools

- **Documentation Platform**: TBD
- **API Documentation**: TBD (Swagger/Postman)
- **Diagram Tools**: Mermaid (for flowcharts, diagrams, and architecture visuals)
- **Code Documentation**: TBD

### Standards

- **Language**: English
- **Format**: Markdown for technical docs
- **Version Control**: All docs in Git
- **Review Process**: TBD
- **Update Frequency**: TBD

---

## Branching Strategy

NXOP projects follow a **fork-based development workflow** that ensures code quality and collaborative efficiency.

### Key Workflow Elements

- **Fork-based Development**: Individual developer forks with pull requests to main repository
- **Flexible Branching**: Optional feature branches based on complexity and team preference
- **Automated Release**: Main branch merges trigger release candidates
- **Version Tagging**: Production deployments create semantic version tags

For complete details including Mermaid diagrams, workflow steps, naming conventions, and troubleshooting guides, see:

📖 **[Complete Branching Strategy Guide](docs/branching-strategy.md)**

### Quick Reference

- **Main Repository**: `AAInternal/nxop-wiki`
- **Developer Workflow**: Fork → Develop → Pull Request → Review → Merge
- **Branch Options**: Fork main (simple changes) or feature branches (complex work)
- **Commit Format**: Conventional Commits specification
- **Protection Rules**: Required reviews and status checks on main branch

---

## Coding Standards

### General Principles

- **Code Style**: TBD (language-specific guides)
- **Linting Tools**: TBD
- **Formatting Tools**: TBD
- **IDE Configuration**: TBD

### Language-Specific Standards

#### Java

- **Style Guide**: [Google Java Style Guide](docs/java-coding-standards.md)
- **Framework**: TBD (Spring Boot)
- **Build Tool**: Maven - [Complete Setup Guide](docs/maven-setup.md)
- **IDE Setup**: [IntelliJ IDEA Configuration Guide](docs/java-coding-standards.md#setting-up-intellij-idea-with-google-java-style-guide)
- **Repository Access**: [Maven Configuration for AA Repositories](docs/maven-setup.md#getting-your-access-token)

### Code Quality Standards

- **Code Coverage**: TBD minimum percentage
- **Cyclomatic Complexity**: TBD maximum
- **Technical Debt**: TBD management strategy
- **Code Review**: TBD process and checklist

---

## Testing Standards

### Testing Strategy

- **Unit Testing**: TBD framework and coverage requirements
- **Integration Testing**: TBD approach
- **End-to-End Testing**: TBD framework
- **Performance Testing**: TBD tools and benchmarks
- **Security Testing**: TBD (SAST/DAST)

### Test Automation

- **CI/CD Integration**: TBD
- **Test Data Management**: TBD
- **Test Environment**: TBD
- **Parallel Testing**: TBD

### Quality Gates

- **Code Coverage**: TBD minimum threshold
- **Test Pass Rate**: TBD minimum threshold
- **Performance Benchmarks**: TBD
- **Security Scan**: TBD pass criteria

---

## Security Standards

**[NXOP Infrastructure Security Overview](docs/nxop-security.md)** - Comprehensive security practices and controls

### Security Framework

- **Security Model**: TBD (Zero Trust)
- **Identity Management**: AWS IAM & IAM Identity Center
- **Secrets Management**: AWS Secrets Manager
- **Encryption**: KMS (at-rest), ACM (in-transit)

### Security Practices

- **Vulnerability Scanning**: TBD tools and frequency
- **Penetration Testing**: TBD schedule
- **Security Training**: TBD requirements
- **Incident Response**: TBD procedures

### Compliance Requirements

- **Aviation Regulations**: TBD
- **Data Protection**: TBD
- **Industry Standards**: TBD
- **Audit Requirements**: TBD

---

## Deployment Standards

### Container Standards

- **Container Runtime**: TBD (Docker/containerd)
- **Image Registry**: CloudSmith
- **Base Images**: TBD approved list
- **Security Scanning**: TBD tools

### Kubernetes Standards

- **Cluster Configuration**: TBD
- **Namespace Strategy**: TBD
- **Resource Limits**: TBD
- **Network Policies**: TBD
- **RBAC**: TBD

### Deployment Patterns

- **Blue-Green Deployment**: TBD
- **Canary Deployment**: TBD
- **Rolling Updates**: TBD
- **Rollback Strategy**: TBD

---

## Monitoring and Observability

### Monitoring Stack

- **Metrics**: TBD (CloudWatch/Prometheus)
- **Logging**: TBD (ELK Stack/CloudWatch Logs)
- **Tracing**: TBD (X-Ray/Jaeger)
- **Alerting**: TBD (CloudWatch Alarms/PagerDuty)

### Observability Standards

- **SLIs (Service Level Indicators)**: TBD
- **SLOs (Service Level Objectives)**: TBD
- **Error Budgets**: TBD
- **Dashboards**: TBD (Grafana/CloudWatch)

### Logging Standards

- **Log Format**: TBD (JSON/Structured)
- **Log Levels**: TBD
- **Sensitive Data**: TBD (masking/redaction)
- **Retention Policy**: TBD

---

## Data Management

### Data Architecture

- **Data Lake**: TBD (S3-based)
- **Data Warehouse**: TBD (Redshift/Iceberg)
- **Real-time Processing**: TBD (Kinesis/MSK)
- **Batch Processing**: TBD (EMR/Glue)

### Data Standards

- **Data Formats**: TBD (JSON/Avro/Parquet)
- **Schema Management**: TBD (Schema Registry)
- **Data Lineage**: TBD tools
- **Data Quality**: TBD monitoring

### Data Governance

- **Data Classification**: TBD
- **Access Controls**: TBD
- **Data Retention**: TBD policies
- **Privacy Protection**: TBD (PII handling)

---

## API Standards

### API Design

- **Style**: TBD (REST/GraphQL/gRPC)
- **Versioning**: TBD strategy
- **Authentication**: TBD (OAuth2/JWT)
- **Rate Limiting**: TBD

### API Documentation

- **Specification**: TBD (OpenAPI 3.0)
- **Documentation Tool**: TBD
- **Testing**: TBD (Postman/Newman)
- **Mocking**: TBD

### API Gateway

- **Gateway Solution**: TBD (AWS API Gateway)
- **Traffic Management**: TBD
- **Security Policies**: TBD
- **Analytics**: TBD

---

## Performance Standards

### Performance Requirements

- **Response Time**: TBD SLAs
- **Throughput**: TBD requirements
- **Availability**: TBD (99.999%)
- **Scalability**: TBD (horizontal/vertical)

### Performance Testing

- **Load Testing**: TBD tools and scenarios
- **Stress Testing**: TBD
- **Capacity Planning**: TBD
- **Performance Monitoring**: TBD

### Optimization Guidelines

- **Caching Strategy**: TBD
- **Database Optimization**: TBD
- **Code Optimization**: TBD
- **Infrastructure Optimization**: TBD

---

## Compliance and Governance

### Project Governance

- **Project Structure**: TBD
- **Decision Making**: TBD (ADRs)
- **Change Management**: TBD
- **Risk Management**: TBD

### Compliance Framework

- **Regulatory Compliance**: TBD (aviation specific)
- **Internal Policies**: TBD
- **Audit Trail**: TBD
- **Reporting**: TBD

### Quality Assurance

- **Code Quality Gates**: TBD
- **Security Gates**: TBD
- **Performance Gates**: TBD
- **Compliance Checks**: TBD

---

## Naming Conventions

Names should generally use lowercase alphanumeric characters, with hyphens separating octets and underscores separating words in Functions / Applications as much as practical.

Note: For NXOP, the `aot-` prefix is to be used.

### Verticals

AOT - Airline Operations Technologies  
Commercial  
Workplace Technologies  
Data, Analytics, & Innovation  

### Single Letter Environments

|Environment|Abbreviation|
|---|---:|
|poc|s|
|dev|d|
|nonprod (stage)|n|
|prod|p|

## Region Short Names

|Region|Abbreviation|
|---|---:|
|us-east-1|use1|
|us-east-2|use2|
|us-west-1|usw1|
|us-west-2|usw2|
|eu-west-1|euw1|
|eu-west-2|euw2|
|eu-west-3|euw3|
|eu-central-1|euc1|
|ap-southeast-1|apse1|
|ap-southeast-2|apse2|
|ap-northeast-1|apne1|
|ap-northeast-2|apne2|
|ca-central-1|cac1|
|sa-east-1|sae1|

#### Naming resources not specified in the below list should generally follow the naming convention of Vertical, Region Short Name, Environment Abbreviation, Platform or Application, Identifier (optional)  

`[vertical]-[region_short_name]-[env_abbr]-[platform_or_app]-[identifier]`

#### Examples

S3:  
`aot-usw2-d-nxop-s3_bucket_name`  
`aot-use2-n-fxip-s3_bucket_name`  
`aot-use1-s-asm-s3_bucket_name`  
`aot-usw2-p-nxop-s3_bucket_name`  

ECR:  
`aot-usw2-d-nxop-ecr-rest_api_name`

Kubernetes:  
`aot-use1-d-nxop-k8s_cluster_name`  

Kubernetes Deployment:  
`aot-use1-d-nxop-k8s_app_name`

### The use of service abbreviations as a suffix/prefix makes sense for some apps and not for others  

|Category|Service/Entity|Example|
|---|---|---|
|Compute|EC2|`aot-d-us-east-1-msk`|
|Compute|EC2 AMI|`aot-usw2-d-nxop-adl_ami_2025_11_05_a`|
|Compute|Kinesis|`aot-usw2-d-nxop-stream_adl`|
|Compute|Kinesis Analytics App|`aot-usw2-d-nxop-k_analytics`|
|Compute|MSK Cluster|`aot-d-us-east-1-msk`|
|Containers|ECR Registry|`aot-usw2-d-nxop-image_name`|
|Identity|IAM Policy|`fxip-d-jump-msk-policy`|
|Identity|IAM Role|`aot-d-developer-jump-instance-role`|
|Network|CloudWatch Event Rule|`aot-usw2-d-nxop-cw_rule_adl`|
|Network|CloudWatch Log Group|`aot-usw2-d-nxop-cwl_adl`|
|Network|Load Balancer|`aot-d-msk-nlb`|
|Network|Route Table|`aot-d-us-east-1-primary-rt`|
|Network|Security Group|`aot-d-rabbit-mq-sg`|
|Network|Subnet|`aot-d-data-us-east-1b`|
|Network|VPC Endpoint|`aot-d-us-east-1-s3-vpce`|
|Resource Group|Glue Job|`aot-d-use1-fxip-flight-events-etl`|
|Resource Group|Glue Schema Registry|`aot-d-use1-fxip-gr`|
|Resource Group|Glue Schema|`aot-d-use1-fxip-schema1`|
|Security|Systems Manager Parameter|`aot-usw2-d-nxop-adl_gha_user`|
|Security|Secrets Manager Secret|`/fxip/dev/credentials/fxip-docdb-fda`|
|Security|KMS Alias|`aot-d-s3-cmk`|
|Storage|S3|`us-east-1-aot-d-fxip`|
|Storage|DocDB Cluster|`nxop-aot-d-use1-docdb`|

## Tagging

## AA Mandatory Tags

AA follows consistent organization-wide tagging standards to align with multi-cloud strategies, which facilitates accurate cost allocation, budgeting, and spend optimization across cloud platforms.

| Tag | Description |
| ----------- | ----------- |
| `aa-app-shortname` | This tag references the Archer Short Name. GaaS team will be updating the application shortnames based on the onboarding of the aws account creation |
| `aa-sdlc-environment`       | This tag is used to define the SDLC environment in azure. Choose the appropriate from the following **dev/test/stage/prod/nonprod/poc** |

## Additional NXOP Mandatory Tags

| Tag | Description |
|------|-------------|  
| `deployed-by` | System or person deploying the infrastructure |
| `division` | Division responsible for the application |
| `owner` | Owner of the application |
| `project` | Project name |
| `repo-url` | URL of the infrastructure code repository |
| `confidentiality` | The confidentiality level of the resource (e.g. Public, Internal, Confidential, Restricted, Highly Restricted) |
| `classification` | Regulatory classification of the resource (e.g. NONE, PII, PHI, PCI, MNPI, HIPAA, or GDPR) |
## Getting Started

### Prerequisites

- TBD

### Development Setup

- TBD

### Contributing

- TBD

### Support

- TBD

---

## Appendices

### Appendix A: Decision Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| TBD | AWS as cloud platform | TBD | ✅ Approved |
| TBD | EKS for container orchestration | TBD | ✅ Approved |
| TBD | MSK for message streaming | TBD | ✅ Approved |

### Appendix B: Glossary

- **NXOP**: Next Gen Operations Platform
- **EKS**: Amazon Elastic Kubernetes Service
- **MSK**: Amazon Managed Streaming for Apache Kafka
- **MSF**: TBD - Definition needed

### Appendix C: References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.4 | 2025-11-06 | NXOP Team | Added KPaaS integration details |
| 1.0.3 | 2025-08-19 | NXOP Team | Added comprehensive Maven setup guide with Cloudsmith authentication, moved branching strategy to separate document, created modular documentation structure |
| 1.0.2 | 2025-08-19 | NXOP Team | Added comprehensive Java coding standards document, IntelliJ IDEA setup guide, Google Java Style Guide integration |
| 1.0.1 | 2025-08-19 | NXOP Team | Added fork-based branching strategy with Mermaid diagrams, clarified optional feature branch usage, updated diagram tools to Mermaid |
| 1.0.0 | 2025-08-14 | NXOP Team | Initial version with placeholder content |

---

**Note**: This document is a living standard and will be updated as decisions are made and implementations progress. All TBD items should be addressed during the respective planning phases of NXOP projects.

For questions or suggestions regarding these standards, please contact the NXOP Architecture Team.

---

## TechRadar Request Tracing

TechRadar Request Tracing [TechRadar Request Tracing](docs/techradar-request-tracing.md).
