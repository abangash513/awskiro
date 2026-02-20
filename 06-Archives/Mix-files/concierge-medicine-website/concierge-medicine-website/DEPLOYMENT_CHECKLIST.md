# AWS Deployment Checklist

## Pre-Deployment Setup

### AWS Account Configuration
- [ ] AWS Account created and verified
- [ ] AWS CLI installed and configured with credentials
- [ ] IAM user/role with appropriate permissions created
- [ ] AWS region selected (default: us-east-1)

### Local Environment
- [ ] Docker installed and running
- [ ] Node.js 18+ installed
- [ ] Git installed
- [ ] Project cloned to local machine

### Environment Variables
- [ ] `.env.production` file created with all required values
- [ ] Database credentials generated and stored securely
- [ ] JWT secret generated (minimum 32 characters)
- [ ] Encryption key generated (64 hex characters)
- [ ] All API keys obtained:
  - [ ] Stripe API keys
  - [ ] Twilio credentials
  - [ ] SendGrid API key
  - [ ] Agora credentials
  - [ ] AWS credentials

## AWS Infrastructure Setup

### S3 Buckets
- [ ] Medical records bucket created
- [ ] Encryption enabled on bucket
- [ ] Public access blocked
- [ ] Versioning enabled
- [ ] Lifecycle policies configured

### RDS PostgreSQL
- [ ] Database instance created
- [ ] Multi-AZ enabled
- [ ] Automated backups configured (30 days)
- [ ] Security group configured
- [ ] Database initialized with schema
- [ ] Backup tested

### ElastiCache Redis
- [ ] Redis cluster created
- [ ] Security group configured
- [ ] Backup enabled
- [ ] Connection tested

### ECR Repository
- [ ] ECR repository created
- [ ] Repository policy configured
- [ ] Lifecycle policy set (keep last 10 images)

### VPC & Networking
- [ ] VPC created or selected
- [ ] Subnets configured (at least 2 in different AZs)
- [ ] Security groups created:
  - [ ] ALB security group
  - [ ] ECS security group
  - [ ] RDS security group
  - [ ] Redis security group
- [ ] Security group rules configured
- [ ] NAT Gateway configured (if needed)

### IAM Roles & Policies
- [ ] ECS Task Execution Role created
- [ ] ECS Task Role created
- [ ] S3 access policy attached
- [ ] Secrets Manager access policy attached
- [ ] CloudWatch Logs policy attached

### Secrets Manager
- [ ] Database credentials stored
- [ ] API keys stored
- [ ] Encryption keys stored
- [ ] Access policies configured

## Application Deployment

### Docker Image
- [ ] Dockerfile created and tested locally
- [ ] Docker image builds successfully
- [ ] Docker image tested locally
- [ ] Docker image pushed to ECR

### ECS Setup
- [ ] ECS cluster created
- [ ] Task definition created
- [ ] Task definition references correct Docker image
- [ ] Environment variables configured
- [ ] Secrets properly referenced
- [ ] CloudWatch Logs configured

### Load Balancer
- [ ] Application Load Balancer created
- [ ] Target group created
- [ ] Health check configured
- [ ] Listener rules configured
- [ ] SSL/TLS certificate configured (if using HTTPS)

### ECS Service
- [ ] ECS service created
- [ ] Service linked to load balancer
- [ ] Desired count set (minimum 2 for HA)
- [ ] Auto-scaling configured
- [ ] Service is running and healthy

## Monitoring & Logging

### CloudWatch
- [ ] Log group created
- [ ] Log retention configured
- [ ] Alarms created:
  - [ ] CPU utilization alarm
  - [ ] Memory utilization alarm
  - [ ] ALB target health alarm
  - [ ] RDS CPU alarm
  - [ ] RDS storage alarm

### Application Monitoring
- [ ] Application logs accessible
- [ ] Error tracking configured
- [ ] Performance metrics visible
- [ ] Database query logs enabled

## Security Verification

### Network Security
- [ ] Security groups follow least privilege principle
- [ ] VPC Flow Logs enabled
- [ ] NACLs configured
- [ ] No public database access

### Data Security
- [ ] RDS encryption enabled
- [ ] S3 encryption enabled
- [ ] Secrets Manager encryption enabled
- [ ] TLS 1.2+ enforced
- [ ] Database backups encrypted

### Access Control
- [ ] IAM policies follow least privilege
- [ ] MFA enabled for AWS account
- [ ] API authentication working
- [ ] Authorization checks in place

### Compliance
- [ ] HIPAA compliance measures in place
- [ ] Audit logging enabled
- [ ] Data retention policies configured
- [ ] Backup and disaster recovery tested

## Testing

### Connectivity Tests
- [ ] ALB is accessible
- [ ] Backend API responds to health check
- [ ] Database connection working
- [ ] Redis connection working
- [ ] S3 access working

### Application Tests
- [ ] User registration working
- [ ] User login working
- [ ] Patient profile creation working
- [ ] Appointment booking working
- [ ] Medical records upload working
- [ ] Messaging working
- [ ] Payment processing working

### Load Testing
- [ ] Load test performed
- [ ] Auto-scaling triggered correctly
- [ ] Performance acceptable
- [ ] No errors under load

## Post-Deployment

### Documentation
- [ ] Deployment documented
- [ ] Architecture diagram created
- [ ] Runbooks created for common tasks
- [ ] Troubleshooting guide created

### Monitoring Setup
- [ ] Team notified of deployment
- [ ] On-call rotation configured
- [ ] Escalation procedures documented
- [ ] Incident response plan ready

### Backup & Disaster Recovery
- [ ] Backup schedule verified
- [ ] Backup restoration tested
- [ ] Disaster recovery plan documented
- [ ] RTO/RPO targets defined

### Performance Optimization
- [ ] CloudFront configured for static content
- [ ] Database query optimization completed
- [ ] Caching strategy implemented
- [ ] CDN configured

## Maintenance Schedule

### Daily
- [ ] Monitor CloudWatch dashboards
- [ ] Check application logs for errors
- [ ] Verify backup completion

### Weekly
- [ ] Review security logs
- [ ] Check cost reports
- [ ] Verify auto-scaling behavior

### Monthly
- [ ] Security audit
- [ ] Performance review
- [ ] Backup restoration test
- [ ] Dependency updates check

### Quarterly
- [ ] Disaster recovery drill
- [ ] Security assessment
- [ ] Capacity planning review
- [ ] Cost optimization review

## Rollback Plan

In case of deployment issues:

1. [ ] Identify the issue
2. [ ] Check CloudWatch logs
3. [ ] Revert to previous task definition:
   ```bash
   aws ecs update-service \
     --cluster concierge-medicine-cluster \
     --service concierge-medicine-backend \
     --task-definition concierge-medicine-backend:PREVIOUS_VERSION \
     --force-new-deployment
   ```
4. [ ] Verify service stability
5. [ ] Investigate root cause
6. [ ] Fix and redeploy

## Support Contacts

- AWS Support: https://console.aws.amazon.com/support
- Application Support: support@concierge-medicine.com
- On-Call Engineer: [Contact Info]

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Approved By:** _______________
**Notes:** _______________
