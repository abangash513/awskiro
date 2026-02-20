# WAFOps - 30 Well-Architected HRI Checks

## 🔒 Security Pillar (11 checks)

1. **Public S3 Buckets** - Detects S3 buckets with public access
2. **Unencrypted EBS Volumes** - Finds EBS volumes without encryption
3. **Unencrypted RDS Instances** - Identifies RDS instances without encryption
4. **Root Account MFA** - Checks if root account has MFA enabled
5. **IAM Users Without MFA** - Finds IAM users missing MFA
6. **IAM Access Keys > 90 Days** - Identifies old access keys
7. **CloudTrail Multi-Region** - Verifies CloudTrail logging across regions
8. **GuardDuty Enabled** - Checks if GuardDuty is active
9. **S3 Block Public Access** - Verifies account-level S3 public access blocking
10. **KMS CMK Usage** - Checks for customer-managed encryption keys
11. **Security Hub Findings** - Reviews critical Security Hub findings

## ⚡ Reliability Pillar (6 checks)

12. **AWS Config Enabled** - Verifies Config service is active
13. **CloudWatch Alarms** - Checks for monitoring on critical resources
14. **Backup Solutions** - Verifies backup plans for critical resources
15. **Single-AZ RDS** - Identifies RDS instances in single availability zone
16. **VPC Flow Logs** - Checks if VPC Flow Logs are enabled
17. **Auto Scaling Groups** - Verifies ASG health checks and scaling policies

## 🚀 Performance Efficiency Pillar (4 checks)

18. **Idle EC2 Instances** - Detects instances with low CPU utilization
19. **Over-provisioned EC2** - Uses Compute Optimizer recommendations
20. **Lambda High Timeout/Errors** - Identifies problematic Lambda functions
21. **Legacy Instance Types** - Finds old generation instances (t2, m3, c3)

## 💰 Cost Optimization Pillar (6 checks)

22. **Idle EC2 (Low CPU)** - Identifies underutilized instances
23. **GP2 to GP3 Migration** - Finds volumes that should migrate to gp3
24. **Savings Plan Coverage** - Calculates Savings Plan utilization
25. **RDS Reserved Instance Coverage** - Checks RDS RI utilization
26. **Unattached EBS Volumes** - Finds volumes not attached to instances
27. **Idle Load Balancers/EIPs** - Identifies unused ALB/ELB/Elastic IPs

## 🌱 Sustainability Pillar (3 checks)

28. **Old-Generation Instances** - Identifies inefficient instance families
29. **Non-GP3 Volumes** - Finds volumes not using efficient gp3 type
30. **Outdated RDS Classes** - Identifies old RDS instance classes

## ⚙️ Operational Excellence Pillar (0 checks currently)

*Note: Operational Excellence checks are planned for future releases*

---

## Current Implementation Status

### ✅ Fully Implemented (11 checks)
- All Security checks (1-11)
- Basic versions of other pillar checks

### ⏳ Simplified Implementation (19 checks)
- Reliability, Performance, Cost, and Sustainability checks are implemented in simplified form
- Full implementation planned for Phase 2

### 📊 Current Findings in Your Account (750299845580)

**Security Issues Found:**
1. ✅ Public S3 Bucket (elasticbeanstalk bucket)
2. ✅ IAM User Without MFA (AAIDemo)
3. ✅ IAM Access Key 788 Days Old (CRITICAL)
4. ✅ CloudTrail Multi-Region Not Enabled
5. ✅ GuardDuty Not Enabled (us-west-2)

**Other Pillars:** No issues detected (simplified checks)

---

## Why Some Checks Are Simplified

The current implementation focuses on the most critical security checks first, with simplified versions of other pillars because:

1. **Security First**: Security issues pose immediate risk
2. **Cost Efficiency**: Full implementation of all 30 checks would increase Lambda execution time and cost
3. **Iterative Development**: Core functionality first, then enhancement
4. **Real-World Priority**: Security findings typically have highest business impact

## Next Phase Enhancement

Phase 2 will implement full versions of all 30 checks with:
- Detailed CloudWatch metrics analysis
- Comprehensive cost optimization recommendations
- Advanced performance monitoring
- Complete reliability assessments
- Full sustainability scoring