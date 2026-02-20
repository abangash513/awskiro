# This Week Implementation Plan
**Week of:** December 3-7, 2025  
**Goal:** Achieve $8,280/month in savings  
**Team:** 2-3 engineers, 1 project lead

---

## 📅 Daily Schedule

### Monday, December 3

#### Morning (9am - 12pm)

**9:00am - 9:30am: Kickoff Meeting**
- Review this implementation plan
- Assign roles and responsibilities
- Set up communication channels (Slack, email)
- Review risk mitigation strategies

**9:30am - 10:30am: Leadership Presentation**
- Present findings to leadership
- Get approval for Phase 1 optimizations
- Secure budget for Reserved Instance purchases
- Confirm resource allocation

**10:30am - 12:00pm: Environment Setup**
- [ ] Verify AWS credentials are working
- [ ] Test cross-account access (if needed)
- [ ] Set up CloudWatch dashboards for monitoring
- [ ] Create Slack channel for updates (#aws-cost-optimization)
- [ ] Set up cost alerts in AWS Budgets

#### Afternoon (1pm - 5pm)

**1:00pm - 2:00pm: Run Analysis Scripts**
```powershell
# Run utilization analysis
.\identify-low-utilization-instances.ps1

# Review results
# File: low-utilization-instances.csv
```

**2:00pm - 3:30pm: Identify Immediate Targets**
- [ ] Review low-utilization-instances.csv
- [ ] Identify instances with < 5% CPU (CRITICAL priority)
- [ ] Verify these instances with application teams
- [ ] Create list of instances to stop
- [ ] Document dependencies

**3:30pm - 5:00pm: Communication & Planning**
- [ ] Email application teams about planned changes
- [ ] Schedule brief check-ins with each team
- [ ] Create rollback plan
- [ ] Document current state (screenshots, configs)

**End of Day Deliverable:**
- List of 10-15 instances approved for stopping
- Communication sent to all stakeholders
- Monitoring dashboards configured

---

### Tuesday, December 4

#### Morning (9am - 12pm)

**9:00am - 9:30am: Daily Standup**
- Review Monday's progress
- Confirm approvals received
- Address any concerns

**9:30am - 11:30am: Stop Unused Instances (Phase 1)**

**Step 1: Snapshot Everything (30 minutes)**
```powershell
# For each instance to be stopped
$instances = @("i-xxxxx", "i-yyyyy", "i-zzzzz")

foreach ($instanceId in $instances) {
    # Create snapshot
    aws ec2 create-snapshot `
        --volume-id $(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text) `
        --description "Backup before stopping $instanceId" `
        --tag-specifications "ResourceType=snapshot,Tags=[{Key=Purpose,Value=CostOptimization},{Key=InstanceId,Value=$instanceId}]"
}
```

**Step 2: Stop Instances (30 minutes)**

**Stopped instances (already stopped, just terminate):**
```powershell
# These have been stopped for months/years - safe to terminate
$stoppedInstances = @(
    "i-a409368e",  # c3.xlarge - stopped since 2021
    "i-52cfda7c",  # c3.xlarge - stopped since 2021
    "i-d07743c7",  # m3.medium - stopped since 2021
    "i-0e002527a16392fa1",  # m3.medium - stopped since 2017
    "i-0eb8bbfffdd2f3ec7",  # c4.large - stopped since 2017
    "i-05bc73a0c7e562ce0",  # m3.medium - stopped since 2023
    "i-0d106f55f0dd4fcdc",  # t2.micro - stopped since 2022
    "i-0a086d7d2a4ba25a9",  # t3.small - stopped since 2021
    "i-0dbb4653a8cfca4ae",  # c4.xlarge - stopped since 2021
    "i-0003603fb4581513a"   # t4g.large - stopped since 2021
)

foreach ($instanceId in $stoppedInstances) {
    Write-Host "Terminating $instanceId..."
    aws ec2 terminate-instances --instance-ids $instanceId
}
```

**Old running instances (verify first, then stop):**
```powershell
# These are from 2015-2017 - likely abandoned
$oldInstances = @(
    "i-0f755cb1",  # c3.xlarge - running since 2015 (9 years!)
    "i-8af05a0d",  # m3.medium - running since 2016 (8 years!)
    "i-5b08ffb7",  # t2.micro - running since 2017
    "i-9e859f4e",  # t2.micro - running since 2017
    "i-efc4fb3a",  # t2.micro - running since 2017
    "i-a915407c"   # t2.medium - running since 2017
)

# VERIFY WITH TEAMS FIRST!
# Then stop (not terminate yet):
foreach ($instanceId in $oldInstances) {
    Write-Host "Stopping $instanceId..."
    aws ec2 stop-instances --instance-ids $instanceId
}
```

**Step 3: Monitor (30 minutes)**
- [ ] Verify instances stopped successfully
- [ ] Check for any alerts or errors
- [ ] Monitor application health
- [ ] Document what was stopped

**11:30am - 12:00pm: Team Check-in**
- Verify no issues reported
- Confirm applications still working
- Address any concerns

#### Afternoon (1pm - 5pm)

**1:00pm - 3:00pm: Purchase RDS Reserved Instances**

**Step 1: Identify Production Databases (30 minutes)**
```powershell
# Review RDS instances
Import-Csv "charles-mount-rds-instances.csv" | Where-Object {$_.DBInstanceId -like "*prod*"}
```

**Production databases to purchase RIs for:**
- doppio-prod (db.r7g.2xlarge) - Aurora MySQL
- doppio-prod-us-east-1d (db.r7g.2xlarge) - Aurora MySQL
- production-db-macchiato (db.m5.xlarge) - MySQL Multi-AZ
- production-db-mfa-5-7 (db.m5.large) - MySQL Multi-AZ
- prod-replica-57b (db.m5.xlarge) - MySQL
- prod-replica-8 (db.m7g.xlarge) - MySQL

**Step 2: Purchase Reserved Instances (60 minutes)**

**In AWS Console:**
1. Go to RDS → Reserved DB Instances
2. Click "Purchase Reserved DB Instance"
3. For each database:
   - Select instance class (e.g., db.r7g.2xlarge)
   - Select engine (e.g., Aurora MySQL)
   - Select term: 1 year
   - Select payment: All Upfront (best discount)
   - Review and purchase

**Or via CLI:**
```bash
# Example for doppio-prod
aws rds purchase-reserved-db-instances-offering \
    --reserved-db-instances-offering-id <offering-id> \
    --reserved-db-instance-id doppio-prod-ri \
    --db-instance-count 1 \
    --tags Key=Purpose,Value=CostOptimization

# Repeat for each database
```

**Step 3: Verify Purchases (30 minutes)**
- [ ] Confirm all RIs purchased
- [ ] Verify they're being applied
- [ ] Document purchase details
- [ ] Calculate actual savings

**3:00pm - 5:00pm: Implement Staging Database Auto-Stop**

**Step 1: Deploy AWS Instance Scheduler (60 minutes)**

**Option A: CloudFormation (Recommended)**
```bash
# Download Instance Scheduler template
wget https://s3.amazonaws.com/solutions-reference/aws-instance-scheduler/latest/instance-scheduler.template

# Deploy
aws cloudformation create-stack \
    --stack-name instance-scheduler \
    --template-body file://instance-scheduler.template \
    --parameters \
        ParameterKey=SchedulingActive,ParameterValue=Yes \
        ParameterKey=Regions,ParameterValue=us-east-1 \
        ParameterKey=DefaultTimezone,ParameterValue=US/Eastern \
    --capabilities CAPABILITY_IAM
```

**Option B: Manual Lambda Function (if CloudFormation fails)**
- Create Lambda function to stop/start RDS instances
- Set up CloudWatch Events for scheduling
- Configure IAM roles

**Step 2: Create Schedule (30 minutes)**

**Schedule Definition:**
- **Name:** staging-business-hours
- **Start:** 7:00 AM Monday-Friday
- **Stop:** 7:00 PM Monday-Friday
- **Weekends:** Stopped
- **Timezone:** US/Eastern

**In Instance Scheduler:**
```json
{
  "name": "staging-business-hours",
  "periods": [{
    "description": "Business hours",
    "begintime": "07:00",
    "endtime": "19:00",
    "weekdays": ["mon-fri"]
  }]
}
```

**Step 3: Tag Staging Databases (30 minutes)**
```bash
# Tag each staging database
staging_dbs=(
    "staging-cluster"
    "staging-cluster-us-east-1d"
    "staging-db-macchiato"
    "staging-db-mfa"
    "staging-replica-57"
    "staging-replica-8"
    "stagingdev-doppio-1-one"
    "stagingdev-doppio-1-two"
    "staging-database-test"
    "staging-database-test-us-west2b"
)

for db in "${staging_dbs[@]}"; do
    aws rds add-tags-to-resource \
        --resource-name arn:aws:rds:us-east-1:198161015548:db:$db \
        --tags Key=Schedule,Value=staging-business-hours
done
```

**End of Day Deliverable:**
- 10-16 instances stopped/terminated
- 6 RDS Reserved Instances purchased
- Staging database auto-stop implemented
- Estimated savings: $8,280/month

---

### Wednesday, December 5

#### Morning (9am - 12pm)

**9:00am - 9:30am: Daily Standup**
- Review Tuesday's actions
- Verify no issues overnight
- Check cost dashboard

**9:30am - 11:30am: Verify & Monitor**

**Step 1: Verify Instance Stops (30 minutes)**
```powershell
# Check status of stopped instances
$stoppedInstances | ForEach-Object {
    aws ec2 describe-instances --instance-ids $_ --query 'Reservations[0].Instances[0].State.Name'
}
```

**Step 2: Verify RI Application (30 minutes)**
```bash
# Check RI utilization
aws ce get-reservation-utilization \
    --time-period Start=2025-12-01,End=2025-12-07 \
    --granularity DAILY
```

**Step 3: Verify Staging Auto-Stop (30 minutes)**
- [ ] Check that staging DBs stopped last night
- [ ] Verify they started this morning
- [ ] Test application connectivity
- [ ] Review CloudWatch logs

**Step 4: Application Health Check (60 minutes)**
- [ ] Check application logs for errors
- [ ] Verify all services responding
- [ ] Test critical user flows
- [ ] Monitor response times

**11:30am - 12:00pm: Team Sync**
- Report on verification results
- Address any issues
- Plan afternoon activities

#### Afternoon (1pm - 5pm)

**1:00pm - 3:00pm: Right-Sizing Analysis**

**Step 1: Analyze c4.4xlarge Instances (60 minutes)**
```powershell
# Get detailed metrics for large instances
$largeInstances = @(
    "i-d87e770d",
    "i-2c7f76f9",
    "i-059b953a2e312a39c",
    "i-01400e7184ad7c200",
    "i-043114ca52c5e8164"
)

foreach ($instanceId in $largeInstances) {
    # Get 30-day CPU average
    $metrics = aws cloudwatch get-metric-statistics `
        --namespace AWS/EC2 `
        --metric-name CPUUtilization `
        --dimensions Name=InstanceId,Value=$instanceId `
        --start-time (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ss") `
        --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss") `
        --period 3600 `
        --statistics Average,Maximum `
        --region us-east-1
    
    # Calculate average
    $avgCPU = ($metrics.Datapoints | Measure-Object Average -Average).Average
    Write-Host "$instanceId : Avg CPU = $avgCPU%"
}
```

**Step 2: Create Right-Sizing Plan (60 minutes)**

**For each c4.4xlarge instance:**
- If CPU < 20%: Downsize to c4.xlarge (save $420/month)
- If CPU < 40%: Downsize to c4.2xlarge (save $280/month)
- If CPU > 40%: Keep as is

**Document:**
- Current size and cost
- Average utilization
- Recommended size
- Expected savings
- Testing plan

**3:00pm - 5:00pm: Documentation & Reporting**

**Step 1: Update Cost Dashboard (30 minutes)**
- [ ] Update current month spend
- [ ] Add savings achieved
- [ ] Project end-of-month cost
- [ ] Create trend charts

**Step 2: Create Status Report (60 minutes)**

**Report Contents:**
- Actions taken this week
- Savings achieved
- Issues encountered
- Next week's plan
- Risks and mitigation

**Step 3: Stakeholder Communication (30 minutes)**
- [ ] Email update to leadership
- [ ] Update Slack channel
- [ ] Schedule Friday review meeting
- [ ] Prepare presentation

**End of Day Deliverable:**
- Verification complete, no issues
- Right-sizing plan created
- Status report drafted
- Stakeholders updated

---

### Thursday, December 6

#### Morning (9am - 12pm)

**9:00am - 9:30am: Daily Standup**
- Review Wednesday's progress
- Confirm right-sizing plan
- Address any concerns

**9:30am - 11:30am: Begin Right-Sizing (Test Environment)**

**Step 1: Test in Staging First (60 minutes)**

**Select 2-3 staging instances for testing:**
```powershell
# Example: Downsize a staging c4.4xlarge to c4.2xlarge
$testInstance = "i-staging-test-001"

# 1. Stop instance
aws ec2 stop-instances --instance-ids $testInstance

# 2. Wait for stopped state
aws ec2 wait instance-stopped --instance-ids $testInstance

# 3. Change instance type
aws ec2 modify-instance-attribute `
    --instance-id $testInstance `
    --instance-type c4.2xlarge

# 4. Start instance
aws ec2 start-instances --instance-ids $testInstance

# 5. Wait for running state
aws ec2 wait instance-running --instance-ids $testInstance
```

**Step 2: Test Applications (60 minutes)**
- [ ] Verify instance started successfully
- [ ] Test application functionality
- [ ] Check response times
- [ ] Monitor for errors
- [ ] Load test if possible

**11:30am - 12:00pm: Review Test Results**
- Discuss findings
- Decide if ready for production
- Adjust plan if needed

#### Afternoon (1pm - 5pm)

**1:00pm - 3:00pm: Production Right-Sizing (if tests passed)**

**Step 1: Schedule Maintenance Window**
- [ ] Notify teams of maintenance
- [ ] Choose low-traffic time
- [ ] Have rollback plan ready

**Step 2: Right-Size Production Instances (one at a time)**

**Priority 1: Instances with < 10% CPU**
```powershell
# Example: i-d87e770d (c4.4xlarge with 8% CPU)
$instanceId = "i-d87e770d"

# 1. Create AMI backup
aws ec2 create-image `
    --instance-id $instanceId `
    --name "backup-$instanceId-$(Get-Date -Format 'yyyyMMdd')" `
    --description "Backup before right-sizing"

# 2. Stop instance
aws ec2 stop-instances --instance-ids $instanceId

# 3. Change to c4.2xlarge
aws ec2 modify-instance-attribute `
    --instance-id $instanceId `
    --instance-type c4.2xlarge

# 4. Start instance
aws ec2 start-instances --instance-ids $instanceId

# 5. Monitor closely
```

**Step 3: Monitor Each Change (30 minutes per instance)**
- [ ] Verify instance starts
- [ ] Check application health
- [ ] Monitor CPU/memory
- [ ] Test critical functions
- [ ] Wait 30 minutes before next change

**3:00pm - 5:00pm: OpenSearch Analysis**

**Step 1: Review OpenSearch Domains (60 minutes)**
```bash
# Get domain details
aws opensearch describe-domain --domain-name onehub-search-production
aws opensearch describe-domain --domain-name opensearch-13-staging
aws opensearch describe-domain --domain-name search-staging
aws opensearch describe-domain --domain-name stagingdev-opensearch
```

**Step 2: Analyze Usage (60 minutes)**
- [ ] Check cluster health
- [ ] Review index sizes
- [ ] Analyze query patterns
- [ ] Check CPU/memory utilization
- [ ] Identify optimization opportunities

**Step 3: Create OpenSearch Optimization Plan**
- Document current configuration
- Recommend new configuration
- Calculate savings
- Plan migration approach

**End of Day Deliverable:**
- 2-3 instances right-sized in staging (tested)
- 1-2 instances right-sized in production
- OpenSearch optimization plan created
- No performance issues

---

### Friday, December 7

#### Morning (9am - 12pm)

**9:00am - 9:30am: Daily Standup**
- Review week's accomplishments
- Verify all changes stable
- Plan final activities

**9:30am - 11:00am: Final Verification & Monitoring**

**Step 1: Comprehensive Health Check (30 minutes)**
- [ ] All applications responding normally
- [ ] No error rate increases
- [ ] Response times acceptable
- [ ] No customer complaints

**Step 2: Cost Verification (30 minutes)**
```bash
# Check current month spend
aws ce get-cost-and-usage \
    --time-period Start=2025-12-01,End=2025-12-07 \
    --granularity DAILY \
    --metrics UnblendedCost

# Compare to previous week
```

**Step 3: Document Everything (30 minutes)**
- [ ] Update runbook
- [ ] Document all changes
- [ ] Create rollback procedures
- [ ] Update architecture diagrams

**11:00am - 12:00pm: Week in Review Meeting**

**Agenda:**
1. Review accomplishments
2. Discuss challenges
3. Verify savings
4. Plan next week
5. Celebrate wins!

#### Afternoon (1pm - 5pm)

**1:00pm - 3:00pm: Create Week 2 Plan**

**Next Week's Focus:**
- Complete right-sizing of remaining instances
- Implement OpenSearch optimizations
- Begin ElastiCache consolidation
- Expand to other accounts

**Step 1: Prioritize Remaining Work (60 minutes)**
- [ ] List all remaining optimization opportunities
- [ ] Prioritize by savings potential
- [ ] Assess complexity and risk
- [ ] Create detailed schedule

**Step 2: Resource Planning (60 minutes)**
- [ ] Confirm team availability
- [ ] Identify any skill gaps
- [ ] Plan training if needed
- [ ] Schedule meetings

**3:00pm - 4:30pm: Final Status Report**

**Report Contents:**
1. **Executive Summary**
   - Savings achieved: $X/month
   - Actions completed
   - Issues resolved
   - Next week's plan

2. **Detailed Metrics**
   - Instances stopped: X
   - Instances right-sized: X
   - RIs purchased: X
   - Databases on auto-stop: X

3. **Financial Impact**
   - Estimated monthly savings
   - Actual cost reduction (partial month)
   - Projected annual savings
   - ROI calculation

4. **Risks & Issues**
   - Any problems encountered
   - How they were resolved
   - Lessons learned
   - Recommendations

**4:30pm - 5:00pm: Send Updates**
- [ ] Email status report to leadership
- [ ] Update Slack channel
- [ ] Schedule Monday kickoff for Week 2
- [ ] Thank the team!

**End of Week Deliverable:**
- $8,280/month in savings achieved
- All changes documented
- No performance issues
- Team ready for Week 2

---

## 📊 Success Metrics

### Track Daily:
- [ ] Number of instances stopped
- [ ] Number of RIs purchased
- [ ] Number of databases on auto-stop
- [ ] Application health status
- [ ] Cost trend

### Track Weekly:
- [ ] Total monthly savings achieved
- [ ] Percentage of plan completed
- [ ] Issues encountered and resolved
- [ ] Team morale and feedback

### End of Week Targets:
- ✅ 10-16 instances stopped/terminated
- ✅ 6 RDS Reserved Instances purchased
- ✅ 10 staging databases on auto-stop schedule
- ✅ 2-3 instances right-sized
- ✅ $8,280/month in savings
- ✅ Zero customer-facing incidents

---

## 🚨 Escalation Procedures

### If Performance Issues Arise:

**Severity 1 (Customer Impact):**
1. Immediately rollback last change
2. Notify leadership
3. Investigate root cause
4. Document incident

**Severity 2 (Internal Impact):**
1. Assess impact
2. Decide: rollback or fix forward
3. Notify affected teams
4. Monitor closely

**Severity 3 (Minor Issues):**
1. Document issue
2. Plan fix
3. Implement during maintenance window

### Contact List:
- **Project Lead:** [Name] - [Phone]
- **Cloud Engineering:** [Name] - [Phone]
- **AWS Support:** 1-800-xxx-xxxx
- **On-Call Engineer:** [Phone]

---

## ✅ Daily Checklist

### Every Morning:
- [ ] Check for any overnight alerts
- [ ] Review cost dashboard
- [ ] Check application health
- [ ] Daily standup meeting

### Every Evening:
- [ ] Document day's activities
- [ ] Update progress tracker
- [ ] Send status update
- [ ] Plan tomorrow's activities

### Before Any Change:
- [ ] Create backup/snapshot
- [ ] Notify affected teams
- [ ] Have rollback plan ready
- [ ] Schedule during low-traffic time

### After Any Change:
- [ ] Verify change successful
- [ ] Monitor for 30 minutes
- [ ] Check application health
- [ ] Document change

---

## 📞 Communication Plan

### Daily Updates (Slack):
- Morning: Today's plan
- Evening: Today's accomplishments
- Any issues: Immediate notification

### Weekly Updates (Email):
- Friday afternoon
- To: Leadership, stakeholders
- Content: Status report

### Ad-Hoc Communication:
- Before any production change
- If any issues arise
- When milestones achieved

---

**Let's make this week count! 🚀**

**Target: $8,280/month savings**  
**Timeline: 5 days**  
**Risk: Low**  
**Confidence: High**

**You've got this!**
