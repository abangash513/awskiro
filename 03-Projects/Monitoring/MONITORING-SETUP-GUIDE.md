# WAC Production Domain Controllers Monitoring Setup Guide

## Overview
Complete monitoring solution for WACPRODDC01 and WACPRODDC02 with email and SMS alerts.

## What Gets Monitored

### CloudWatch Alarms (Automatic)
1. **Instance Status** - Detects if EC2 instance is down
2. **CPU Utilization** - Alerts when > 70% for 10 minutes
3. **Memory Utilization** - Alerts when > 70% for 10 minutes

### Active Directory Health Checks (Every 5 minutes)
1. **Critical Services Status**
   - NTDS (Active Directory Domain Services)
   - DNS Server
   - Netlogon
   - KDC (Kerberos Key Distribution Center)
   - W32Time (Time Synchronization)

2. **AD Replication Monitoring**
   - Replication errors between DCs
   - Replication partner status
   - Last successful replication time (alerts if > 60 min)
   - Replication queue depth (alerts if > 50 items)

3. **SYSVOL Share** - Ensures SYSVOL is accessible
4. **DNS Resolution** - Verifies domain DNS is working

### Event Log Collection (Continuous)
- System errors and critical events
- Directory Service warnings/errors
- DNS Server errors

## Files Created

### Local Machine Scripts (Run from your workstation)
- `wac-monitoring-setup.ps1` - Initial setup (SNS + CloudWatch alarms)
- `add-memory-alarms.ps1` - Adds memory alarms after agent install

### DC Instance Scripts (Run on each DC via RDP)
- `install-cloudwatch-agent.ps1` - Installs CloudWatch agent
- `cloudwatch-agent-config.json` - Agent configuration
- `ad-health-monitor.ps1` - AD health check script
- `setup-ad-monitoring.ps1` - Creates scheduled task

## Setup Steps

### Step 1: Initial Setup (Local Machine)
```powershell
cd C:\AWSKiro
.\wac-monitoring-setup.ps1
```
**Prompts:**
- Enter your email address
- Enter your phone number (format: +12345678900)

**What it does:**
- Fetches instance IDs for both DCs
- Creates SNS topic: WAC-Prod-DC-Alerts
- Subscribes your email and phone
- Creates 4 CloudWatch alarms:
  - WACPRODDC01-StatusCheck
  - WACPRODDC01-HighCPU
  - WACPRODDC02-StatusCheck
  - WACPRODDC02-HighCPU

**Important:** Check your email and confirm SNS subscription!

### Step 2: Install CloudWatch Agent (On WACPRODDC01)
1. RDP to WACPRODDC01
2. Copy files to C:\AWSKiro on the DC
3. Run as Administrator:
```powershell
cd C:\AWSKiro
.\install-cloudwatch-agent.ps1
```

**What it does:**
- Downloads CloudWatch agent installer
- Installs agent silently
- Configures metrics collection (CPU, Memory, Disk)
- Configures log collection (System, AD, DNS events)
- Starts the agent

### Step 3: Setup AD Monitoring (On WACPRODDC01)
```powershell
cd C:\AWSKiro
.\setup-ad-monitoring.ps1
```

**What it does:**
- Creates scheduled task: WAC-AD-Health-Monitor
- Runs every 5 minutes as SYSTEM account
- Executes ad-health-monitor.ps1

### Step 4: Repeat Steps 2-3 on WACPRODDC02

### Step 5: Add Memory Alarms (Local Machine)
```powershell
cd C:\AWSKiro
.\add-memory-alarms.ps1
```

**What it does:**
- Creates 2 additional CloudWatch alarms:
  - WACPRODDC01-HighMemory
  - WACPRODDC02-HighMemory

## Alert Notifications

### You'll receive alerts via Email + SMS for:

**CloudWatch Alarms:**
- Instance status check failure (DC is down)
- CPU utilization > 70% for 10 minutes
- Memory utilization > 70% for 10 minutes

**AD Health Alerts:**
- Any critical service stopped (NTDS, DNS, Netlogon, KDC, W32Time)
- AD replication failures
- Replication lag > 60 minutes
- High replication queue (> 50 items)
- SYSVOL share inaccessible
- DNS resolution failures

## Verification

### Check CloudWatch Alarms
```powershell
aws cloudwatch describe-alarms --profile WACPROD --region us-west-2
```

### Check SNS Subscriptions
```powershell
aws sns list-subscriptions --profile WACPROD --region us-west-2
```

### Check CloudWatch Agent Status (On DC)
```powershell
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a query -m ec2 -c default -s
```

### Check Scheduled Task (On DC)
```powershell
Get-ScheduledTask -TaskName "WAC-AD-Health-Monitor"
```

### Test AD Health Script Manually (On DC)
```powershell
cd C:\AWSKiro
.\ad-health-monitor.ps1
```

## CloudWatch Dashboards (Optional)

View metrics in AWS Console:
1. Go to CloudWatch > Dashboards
2. Create dashboard: WAC-Prod-DCs
3. Add widgets for:
   - CPU Utilization (both DCs)
   - Memory Utilization (both DCs)
   - Status Checks (both DCs)

## Troubleshooting

### Not receiving alerts?
- Confirm SNS email subscription (check spam folder)
- Verify phone number format: +1XXXXXXXXXX
- Check alarm state: `aws cloudwatch describe-alarms --profile WACPROD --region us-west-2`

### CloudWatch agent not sending metrics?
- Check agent status on DC
- Verify IAM role attached to EC2 instances has CloudWatchAgentServerPolicy
- Check agent logs: `C:\ProgramData\Amazon\AmazonCloudWatchAgent\Logs\`

### AD health script not running?
- Verify scheduled task exists and is enabled
- Check task history in Task Scheduler
- Run script manually to test
- Ensure AWS CLI is installed on DCs

## Cost Estimate

**CloudWatch:**
- 6 alarms × $0.10/month = $0.60/month
- Metrics: ~$3/month (custom metrics)
- Logs: ~$0.50/month (minimal logs)

**SNS:**
- Email: Free
- SMS: ~$0.00645 per message (US)

**Total: ~$5-10/month** (depending on alert frequency)

## Maintenance

### Monthly:
- Review CloudWatch alarm history
- Check for false positives
- Verify replication is healthy

### Quarterly:
- Test failover scenarios
- Update alert thresholds if needed
- Review cost and optimize

## Support Contacts

**AWS Account:** 466090007609
**Region:** us-west-2
**Profile:** WACPROD
**Instances:**
- WACPRODDC01
- WACPRODDC02

**SNS Topic:** WAC-Prod-DC-Alerts
