# KPass Setup Checklist

## Prerequisites

### Access Requirements
- **AAD Group Membership**: Must be part of `AAD_NXOP_NONPROD` to:
  - View cluster on Rancher UI
  - Deploy to target NXOP cluster from Runway UI
- **Mezmo Access**: Request access to:
  - `AA_TNT_KaaS_Rancher_NonProd`
  - `AA_TNT_KaaS_Rancher_Prod`
- **Support Channel**: Request access to `NXOP-KPaaS-AWS-Support` from Amit or Praveen

## Required Files / Structure

### Kubernetes Configuration
- `k8s/dev/webapp.yml` - Development environment configuration

### GitHub Workflows
- `.github/workflows/ci.yml` - Continuous Integration pipeline
- `.github/workflows/cd.yml` - Continuous Deployment pipeline
- `.github/workflows/lower-env-deployment.yml` - Lower environment deployment workflow
- `.github/workflows/prod-deployment.yml` - Prod deployment workflow

**[DTE-Reusable Workflows](https://github.com/AAInternal/dte-reusable-workflows/)** - Documentation on DTE Reusable Workflows

### Application Files
- `Dockerfile` - Container image definition
- `catalog-info.yml` - Service catalog metadata
- `README.md` - Project documentation

## Deployment & Tools

### Runway Portal
- **[Create/Import UI](https://developer.aa.com/create?filters%5Btags%5D=certified)** - Landing page for selecting and deploying Runway templates to KPaaS clusters
- **[Creating Application Guide](https://developer.aa.com/docs/default/component/runway/getting-started/userguides/create-a-app/)** - Documentation for onboarding an application using Runway templates
- **[Importing Existing Application Guide](https://developer.aa.com/docs/default/component/runway/guides/onboarding-to-runway/#1-import-an-application-into-runway)** - Documentation for importing an existing application to Runway
- **[WebApp Spec](https://developer.aa.com/docs/default/component/runway/getting-started/userguides/webapp/)** - Complete WebApp specification documentation
- **[Manage Rancher Project & Namespace](https://developer.aa.com/infrastructure/rancher)** - Manage resource quota for Rancher Project/Namespace

### KPass NonProd Environment
- **[Rancher UI](https://master-nprke.ok8s.aa.com/)** - View K8s resources deployed on target NXOP cluster
- **Important**: Secrets must be created in Rancher before deployment

### ArgoCD Setup
- Austin and team will handle ArgoCD creation for microservices
- **Prerequisite**: All files from the checklist above must be completed first

### Monitoring & Observability
- **[Mezmo Logs](https://app.mezmo.com/da95da5409/logs/view)** - Enterprise logging aggregator service
- **[Dynatrace (NonProd)](https://aa-nonprod.live.dynatrace.com/)** - Enterprise APM tool

## Setup Steps

1. Verify AAD group membership (`AAD_NXOP_NONPROD`)
2. Request access to Mezmo and support channel
3. Create all required files and directory structure
4. Create necessary secrets in Rancher
5. Deploy using Runway UI
6. Test deployment configuration
7. Notify Austin for ArgoCD setup
8. Verify logs in Mezmo
9. Monitor application in Dynatrace
