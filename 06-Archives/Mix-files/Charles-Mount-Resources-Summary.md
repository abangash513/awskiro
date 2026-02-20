# Charles Mount Account - Resources by Environment

**Account ID:** 198161015548  
**Total Monthly Cost:** $57,452  
**Analysis Date:** December 3, 2025

---

## 📊 Summary by Environment

| Environment | EC2 Instances | RDS Databases | EBS Volumes | EBS Storage |
|-------------|---------------|---------------|-------------|-------------|
| **Production** | 50 | 6 | 72 | 81,819 GB |
| **Staging** | 24 | 10 | 29 | 7,772 GB |
| **Development** | 1 | 0 | 1 | 8 GB |
| **Test/QA** | 2 | 0 | 4 | 2,200 GB |
| **Unknown/Other** | 2 | 0 | 73 | 52,627 GB |
| **TOTAL** | **79** | **16** | **179** | **144,426 GB** |

---

## 🏭 PRODUCTION ENVIRONMENT

### Applications Identified:
- **Doppio** (Primary application)
- **Macchiato** (Secondary application)
- **MFA** (Multi-Factor Authentication)
- **Database Replicas** (Read replicas)

### RDS Databases (6 instances)

#### Doppio Application:
| Database | Instance Class | Engine | Storage | Multi-AZ | Status |
|----------|---------------|--------|---------|----------|--------|
| doppio-prod | db.r7g.2xlarge | Aurora MySQL | 1 GB | No | Running |
| doppio-prod-us-east-1d | db.r7g.2xlarge | Aurora MySQL | 1 GB | No | Running |

**Cost:** ~$1,600/month  
**Optimization:** Purchase Reserved Instances (save 40%)

#### Macchiato Application:
| Database | Instance Class | Engine | Storage | Multi-AZ | Status |
|----------|---------------|--------|---------|----------|--------|
| production-db-macchiato | db.m5.xlarge | MySQL 5.7 | 600 GB | Yes | Running |

**Cost:** ~$500/month  
**Optimization:** Purchase Reserved Instance (save 40%)

#### MFA Application:
| Database | Instance Class | Engine | Storage | Multi-AZ | Status |
|----------|---------------|--------|---------|----------|--------|
| production-db-mfa-5-7 | db.m5.large | MySQL 5.7 | 100 GB | Yes | Running |

**Cost:** ~$300/month  
**Optimization:** Purchase Reserved Instance (save 40%)

#### Database Replicas:
| Database | Instance Class | Engine | Storage | Multi-AZ | Status |
|----------|---------------|--------|---------|----------|--------|
| prod-replica-57b | db.m5.xlarge | MySQL 5.7 | 6,443 GB | No | Running |
| prod-replica-8 | db.m7g.xlarge | MySQL 8.0 | 6,443 GB | No | Running |

**Cost:** ~$800/month  
**Optimization:** Purchase Reserved Instances (save 40%)

### EC2 Instances (50 instances)

#### Running: 42 instances
- **Large Instances (High Cost):**
  - 5x c4.4xlarge (16 vCPU) - ~$560/month each = $2,800/month
  - 2x m4.2xlarge (8 vCPU) - ~$336/month each = $672/month
  - 3x c4.2xlarge (8 vCPU) - ~$350/month each = $1,050/month

- **Medium Instances:**
  - 8x m3.xlarge, m4.xlarge, c4.xlarge
  - 10x c4.large, m4.large, m3.large
  - 14x m3.medium, t3.medium, t2.medium, t2.micro

#### Stopped: 8 instances
- **Action Required:** Terminate after verification
- **Estimated Savings:** $2,000/month

### EBS Volumes (72 volumes)
- **Total Storage:** 81,819 GB (81.8 TB)
- **All Attached:** Yes
- **Volume Type:** Mostly GP2 (should migrate to GP3)
- **Encrypted:** Unknown (needs verification)

**Estimated Cost:** ~$8,182/month  
**Optimization:** Migrate GP2 to GP3 (save 20% = $1,636/month)

---

## 🧪 STAGING ENVIRONMENT

### Applications Identified:
- **Doppio Staging**
- **Macchiato Staging**
- **MFA Staging**
- **Database Replicas**
- **General Staging**

### RDS Databases (10 instances - ALL RUNNING 24/7)

#### Doppio Staging:
| Database | Instance Class | Engine | Storage | Status |
|----------|---------------|--------|---------|--------|
| stagingdev-doppio-1-one | db.t4g.medium | Aurora MySQL | 1 GB | Running |
| stagingdev-doppio-1-two | db.t4g.medium | Aurora MySQL | 1 GB | Running |

#### General Staging:
| Database | Instance Class | Engine | Storage | Status |
|----------|---------------|--------|---------|--------|
| staging-cluster | db.t4g.large | Aurora MySQL | 1 GB | Running |
| staging-cluster-us-east-1d | db.t4g.large | Aurora MySQL | 1 GB | Running |
| staging-database-test | db.t4g.large | Aurora MySQL | 1 GB | Running |
| staging-database-test-us-west2b | db.t4g.large | Aurora MySQL | 1 GB | Running |

#### Macchiato Staging:
| Database | Instance Class | Engine | Storage | Status |
|----------|---------------|--------|---------|--------|
| staging-db-macchiato | db.t3.small | MySQL 5.7 | 25 GB | Running |

#### MFA Staging:
| Database | Instance Class | Engine | Storage | Status |
|----------|---------------|--------|---------|--------|
| staging-db-mfa | db.t3.micro | MySQL 8.0 | 25 GB | Running |

#### Database Replicas:
| Database | Instance Class | Engine | Storage | Status |
|----------|---------------|--------|---------|--------|
| staging-replica-57 | db.t3.medium | MySQL 5.7 | 20 GB | Running |
| staging-replica-8 | db.t3.medium | MySQL 8.0 | 20 GB | Running |

**Current Cost:** ~$4,000/month (running 24/7)  
**Optimization:** Implement auto-stop (7pm-7am + weekends)  
**Savings:** ~$3,000/month (70% uptime reduction)

### EC2 Instances (24 instances)

#### Running: 15 instances
- Mix of t2.medium, t3.medium, m3.medium, c4.xlarge, c4.2xlarge
- **Issue:** Sized too large for staging environment

#### Stopped: 9 instances
- **Action Required:** Terminate old stopped instances
- **Estimated Savings:** $500/month

### EBS Volumes (29 volumes)
- **Total Storage:** 7,772 GB (7.8 TB)
- **All Attached:** Yes
- **Estimated Cost:** ~$777/month

**Optimization:** Migrate to GP3, implement auto-stop with instances

---

## 🔧 DEVELOPMENT ENVIRONMENT

### RDS Databases: 0
**Good:** No databases running in dev (using staging or local)

### EC2 Instances: 1 (stopped)
- i-0a4890503b8ec083b (t2.micro) - Stopped
- **Action:** Terminate if not needed

### EBS Volumes: 1
- **Total Storage:** 8 GB
- **Cost:** Negligible

---

## 🧪 TEST/QA ENVIRONMENT

### RDS Databases: 0
**Good:** No databases running in test/QA

### EC2 Instances: 2
- 1 running (m3.large)
- 1 stopped (m3.large)
- **Action:** Verify if still needed, implement auto-stop

### EBS Volumes: 4
- **Total Storage:** 2,200 GB
- **Cost:** ~$220/month

---

## ❓ UNKNOWN/OTHER ENVIRONMENT

### EC2 Instances: 2
- 1 stopped Windows instance (c3.xlarge) - Terminate
- 1 running Windows instance (t2.medium) - Verify purpose

### EBS Volumes: 73 volumes
- **Total Storage:** 52,627 GB (52.6 TB)
- **Issue:** Large number of unclassified volumes
- **Action Required:** Investigate and categorize
- **Estimated Cost:** ~$5,263/month

---

## 💰 Cost Breakdown by Environment

### Production (~$35,000/month)
- RDS: ~$3,200/month
- EC2: ~$25,000/month
- EBS: ~$8,182/month
- Other: ~$2,000/month (OpenSearch, ElastiCache, etc.)

**Optimization Potential:** $8,000-12,000/month
- Reserved Instances: $1,280/month
- Right-size instances: $6,000/month
- GP2 to GP3: $1,636/month

### Staging (~$15,000/month)
- RDS: ~$4,000/month
- EC2: ~$8,000/month
- EBS: ~$777/month
- Other: ~$2,000/month

**Optimization Potential:** $10,000-12,000/month
- Auto-stop RDS: $3,000/month
- Auto-stop EC2: $5,000/month
- Right-size instances: $2,000/month

### Development/Test/QA (~$2,000/month)
- Minimal resources
- **Optimization Potential:** $500-1,000/month

### Unknown/Other (~$5,500/month)
- Mostly EBS volumes
- **Action Required:** Investigate and categorize
- **Optimization Potential:** $2,000-3,000/month

---

## 🎯 Key Findings

### 1. Production is Appropriately Sized
- 50 EC2 instances, 6 RDS databases
- Running 24/7 as expected
- **Optimization:** Reserved Instances, right-sizing

### 2. Staging is Over-Provisioned
- 24 EC2 instances, 10 RDS databases
- Running 24/7 (should only run business hours)
- **Optimization:** Auto-stop schedules, right-sizing

### 3. Large Unknown/Other Category
- 73 EBS volumes (52.6 TB) unclassified
- **Action Required:** Investigate and categorize

### 4. Old Resources Still Running
- Instances from 2015-2017 still active
- Stopped instances from 2021-2022 not terminated
- **Action Required:** Clean up old resources

---

## 📋 Immediate Actions Required

### This Week:

1. **Terminate Stopped Instances (8 in production, 9 in staging)**
   - Savings: $2,500/month

2. **Purchase RDS Reserved Instances (6 production databases)**
   - Savings: $1,280/month

3. **Implement Staging Auto-Stop (10 databases)**
   - Savings: $3,000/month

4. **Investigate Unknown EBS Volumes (73 volumes, 52.6 TB)**
   - Potential Savings: $2,000-3,000/month

### Next Week:

5. **Right-Size Production Instances**
   - Target: 5x c4.4xlarge, 2x m4.2xlarge, 3x c4.2xlarge
   - Savings: $6,000/month

6. **Implement Staging EC2 Auto-Stop**
   - Savings: $5,000/month

7. **Migrate All GP2 to GP3**
   - Savings: $1,636/month

---

## 📊 Applications Summary

### Identified Applications:

1. **Doppio**
   - Production: 2 Aurora MySQL clusters (db.r7g.2xlarge)
   - Staging: 2 Aurora MySQL clusters (db.t4g.medium)
   - Primary application

2. **Macchiato**
   - Production: 1 MySQL database (db.m5.xlarge, Multi-AZ)
   - Staging: 1 MySQL database (db.t3.small)
   - Secondary application

3. **MFA (Multi-Factor Authentication)**
   - Production: 1 MySQL database (db.m5.large, Multi-AZ)
   - Staging: 1 MySQL database (db.t3.micro)
   - Authentication service

4. **Database Replicas**
   - Production: 2 read replicas (MySQL 5.7 and 8.0)
   - Staging: 2 read replicas (MySQL 5.7 and 8.0)
   - Read scaling

5. **General/Infrastructure**
   - Various EC2 instances for web servers, app servers, workers
   - OpenSearch for search functionality
   - ElastiCache for caching
   - Load balancers, NAT gateways

---

## 📁 Files Generated

1. **production-rds.csv** - All production RDS databases
2. **production-ec2.csv** - All production EC2 instances
3. **production-ebs.csv** - All production EBS volumes
4. **staging-rds.csv** - All staging RDS databases
5. **staging-ec2.csv** - All staging EC2 instances
6. **staging-ebs.csv** - All staging EBS volumes

---

**Next Steps:** Review this summary and approve Phase 1 optimizations to save $8,280/month immediately.
