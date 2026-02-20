# Snowflake on AWS - Requirements and Setup Guide

**Date:** February 1, 2026  
**Purpose:** Complete guide for running Snowflake Data Cloud on AWS

---

## Overview

Snowflake is a cloud-native data warehouse that runs on AWS infrastructure. Unlike traditional databases, Snowflake is a **fully managed SaaS** (Software as a Service) platform - you don't deploy or manage any infrastructure yourself.

### Key Concept
**You don't "install" Snowflake on AWS** - Snowflake manages all the infrastructure. You simply:
1. Sign up for a Snowflake account
2. Choose AWS as your cloud provider
3. Select your AWS region
4. Start using Snowflake immediately

---

## What You Need

### 1. Snowflake Account

**Sign Up:**
- Go to: https://signup.snowflake.com/
- Choose "AWS" as your cloud provider
- Select your AWS region (e.g., us-east-1, us-west-2)
- Choose your Snowflake edition:
  - **Standard** - Basic features
  - **Enterprise** - Advanced features (multi-cluster warehouses, materialized views)
  - **Business Critical** - Enhanced security (HIPAA, PCI-DSS compliance)
  - **Virtual Private Snowflake (VPS)** - Dedicated infrastructure

**Account Structure:**
```
<account_name>.<region>.<cloud>.snowflakecomputing.com

Example:
mycompany.us-east-1.aws.snowflakecomputing.com
```

**Cost Model:**
- Pay only for what you use
- Separate billing for:
  - **Compute** (virtual warehouses) - billed per second
  - **Storage** (data stored) - billed per TB/month
  - **Cloud Services** (metadata operations) - typically free up to 10% of compute

---

### 2. AWS Account (Optional but Recommended)

While Snowflake manages the infrastructure, you'll likely need an AWS account for:

#### Data Integration
- **S3 Buckets** - Store data files for loading into Snowflake
- **IAM Roles** - Secure access between Snowflake and S3
- **VPC** (Optional) - Private connectivity via AWS PrivateLink

#### Common AWS Services Used with Snowflake
- **S3** - Data lake storage, staging area for data loads
- **IAM** - Access control and authentication
- **KMS** - Encryption key management (optional)
- **PrivateLink** - Private network connectivity
- **Lambda** - Automated data pipelines
- **Glue** - ETL and data catalog
- **EventBridge** - Event-driven workflows
- **Secrets Manager** - Credential storage

---

## Architecture: How Snowflake Runs on AWS

### Snowflake Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Applications                         │
│  (BI Tools, Python, SQL Clients, APIs, etc.)                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Snowflake Cloud Services Layer                  │
│  (Metadata, Query Optimization, Security, Access Control)   │
│                  Managed by Snowflake                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Snowflake Compute Layer (Virtual Warehouses)    │
│  (Query Processing, Data Loading, Transformations)          │
│                  Runs on AWS EC2                             │
│                  Managed by Snowflake                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Snowflake Storage Layer                         │
│  (Compressed, Encrypted Data Storage)                       │
│                  Runs on AWS S3                              │
│                  Managed by Snowflake                        │
└─────────────────────────────────────────────────────────────┘
```

### What Snowflake Manages (You Don't See)
- EC2 instances for compute
- S3 buckets for storage
- Load balancers
- Networking
- Security patches
- Backups
- High availability
- Disaster recovery

### What You Manage
- Virtual warehouses (size and auto-suspend settings)
- Databases, schemas, tables
- Users and roles
- Data loading and queries
- Cost optimization

---

## Setup Steps

### Step 1: Create Snowflake Account

1. **Sign up at:** https://signup.snowflake.com/

2. **Choose Configuration:**
   - **Cloud Provider:** AWS
   - **Region:** us-east-1 (or your preferred region)
   - **Edition:** Standard, Enterprise, or Business Critical

3. **Receive Credentials:**
   - Account URL: `https://<account>.snowflakecomputing.com`
   - Username: (your email)
   - Temporary password (change on first login)

4. **First Login:**
   - Go to your account URL
   - Login with credentials
   - Change password
   - Set up MFA (recommended)

---

### Step 2: Set Up AWS Integration (Optional)

#### Option A: S3 Integration for Data Loading

**Purpose:** Load data from S3 into Snowflake

**Requirements:**
1. AWS S3 bucket with your data
2. IAM role for Snowflake to access S3
3. External stage in Snowflake pointing to S3

**Setup Steps:**

**1. Create S3 Bucket (if needed):**
```bash
aws s3 mb s3://my-snowflake-data --region us-east-1
```

**2. Create IAM Policy for Snowflake:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::my-snowflake-data",
        "arn:aws:s3:::my-snowflake-data/*"
      ]
    }
  ]
}
```

**3. Create IAM Role:**
```bash
# Create trust policy for Snowflake
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::SNOWFLAKE_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "SNOWFLAKE_EXTERNAL_ID"
        }
      }
    }
  ]
}
EOF

# Create role
aws iam create-role --role-name SnowflakeS3Access --assume-role-policy-document file://trust-policy.json

# Attach policy
aws iam attach-role-policy --role-name SnowflakeS3Access --policy-arn arn:aws:iam::YOUR_ACCOUNT:policy/SnowflakeS3Policy
```

**4. Configure in Snowflake:**
```sql
-- Create storage integration
CREATE STORAGE INTEGRATION s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::YOUR_ACCOUNT:role/SnowflakeS3Access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://my-snowflake-data/');

-- Get Snowflake AWS account and external ID
DESC STORAGE INTEGRATION s3_integration;

-- Update IAM trust policy with values from above

-- Create external stage
CREATE STAGE my_s3_stage
  STORAGE_INTEGRATION = s3_integration
  URL = 's3://my-snowflake-data/'
  FILE_FORMAT = (TYPE = CSV);

-- Test by listing files
LIST @my_s3_stage;

-- Load data
COPY INTO my_table
FROM @my_s3_stage
FILE_FORMAT = (TYPE = CSV);
```

---

#### Option B: AWS PrivateLink (Private Connectivity)

**Purpose:** Private network connection between AWS VPC and Snowflake

**Requirements:**
- Snowflake Business Critical or Enterprise edition
- AWS VPC
- VPC endpoint service

**Benefits:**
- Traffic doesn't traverse public internet
- Enhanced security
- Lower latency
- Compliance requirements (HIPAA, PCI-DSS)

**Setup Steps:**

**1. Enable PrivateLink in Snowflake:**
```sql
-- Contact Snowflake support to enable PrivateLink
-- They will provide VPC endpoint service name
```

**2. Create VPC Endpoint in AWS:**
```bash
# Create VPC endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-12345678 \
  --service-name com.amazonaws.vpce.us-east-1.vpce-svc-SNOWFLAKE_SERVICE_ID \
  --vpc-endpoint-type Interface \
  --subnet-ids subnet-12345678 subnet-87654321 \
  --security-group-ids sg-12345678

# Get endpoint DNS name
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids vpce-12345678
```

**3. Update Snowflake Connection:**
```
# Use PrivateLink URL instead of public URL
https://<account>.privatelink.snowflakecomputing.com
```

---

### Step 3: Create Virtual Warehouse

**Purpose:** Compute resources for running queries

```sql
-- Create warehouse
CREATE WAREHOUSE my_warehouse
  WITH WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 300          -- Suspend after 5 minutes of inactivity
  AUTO_RESUME = TRUE          -- Resume automatically when query submitted
  INITIALLY_SUSPENDED = TRUE; -- Start in suspended state

-- Warehouse sizes and costs (approximate)
-- X-Small:  1 credit/hour  (~$2-4/hour depending on edition)
-- Small:    2 credits/hour
-- Medium:   4 credits/hour
-- Large:    8 credits/hour
-- X-Large:  16 credits/hour
-- 2X-Large: 32 credits/hour
-- 3X-Large: 64 credits/hour
-- 4X-Large: 128 credits/hour
```

---

### Step 4: Create Database and Schema

```sql
-- Create database
CREATE DATABASE my_database;

-- Use database
USE DATABASE my_database;

-- Create schema
CREATE SCHEMA my_schema;

-- Use schema
USE SCHEMA my_schema;
```

---

### Step 5: Create Tables and Load Data

```sql
-- Create table
CREATE TABLE customers (
  customer_id INT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100),
  created_at TIMESTAMP
);

-- Load data from S3
COPY INTO customers
FROM @my_s3_stage/customers.csv
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1);

-- Or insert data directly
INSERT INTO customers VALUES
  (1, 'John', 'Doe', 'john@example.com', CURRENT_TIMESTAMP()),
  (2, 'Jane', 'Smith', 'jane@example.com', CURRENT_TIMESTAMP());

-- Query data
SELECT * FROM customers;
```

---

## AWS Resources Needed (Summary)

### Minimum Requirements (No AWS Account Needed)
- ✅ Snowflake account only
- ✅ Access via web UI or SQL clients
- ✅ Can load data via web UI (small files)

### Recommended Setup (AWS Account)
- ✅ S3 bucket for data staging
- ✅ IAM role for S3 access
- ✅ Storage integration in Snowflake

### Enterprise Setup (AWS Account)
- ✅ S3 buckets for data lake
- ✅ IAM roles and policies
- ✅ VPC with PrivateLink
- ✅ KMS keys for encryption
- ✅ Lambda for automation
- ✅ Glue for ETL
- ✅ EventBridge for orchestration

---

## Network Requirements

### Outbound Connectivity (Required)
Your applications/users need to connect to Snowflake:

**Public Internet:**
- HTTPS (port 443) to `*.snowflakecomputing.com`
- No inbound ports required

**PrivateLink (Optional):**
- VPC endpoint in your AWS VPC
- Private DNS resolution
- Security group allowing outbound HTTPS

### Firewall Rules
```
# Allow outbound HTTPS to Snowflake
Destination: *.snowflakecomputing.com
Port: 443
Protocol: HTTPS

# For PrivateLink
Destination: <account>.privatelink.snowflakecomputing.com
Port: 443
Protocol: HTTPS
```

---

## Security Requirements

### Authentication Options

**1. Username/Password**
- Basic authentication
- MFA recommended

**2. Key Pair Authentication**
```sql
-- Generate key pair
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

-- Assign public key to user
ALTER USER myuser SET RSA_PUBLIC_KEY='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...';
```

**3. OAuth**
- External OAuth (Okta, Azure AD, etc.)
- Snowflake OAuth

**4. SAML 2.0 SSO**
- Enterprise SSO integration
- Okta, Azure AD, ADFS, etc.

### Encryption

**Data at Rest:**
- Automatic encryption with AES-256
- Snowflake-managed keys (default)
- Customer-managed keys via AWS KMS (optional)

**Data in Transit:**
- TLS 1.2+ for all connections
- End-to-end encryption

### Network Security

**IP Whitelisting:**
```sql
-- Restrict access to specific IPs
CREATE NETWORK POLICY my_policy
  ALLOWED_IP_LIST = ('192.168.1.0/24', '10.0.0.0/8');

-- Apply to account
ALTER ACCOUNT SET NETWORK_POLICY = my_policy;
```

**PrivateLink:**
- Private connectivity via AWS VPC
- No public internet exposure

---

## Cost Optimization

### Compute Costs

**Virtual Warehouse Best Practices:**
```sql
-- Auto-suspend after 5 minutes
ALTER WAREHOUSE my_warehouse SET AUTO_SUSPEND = 300;

-- Auto-resume when needed
ALTER WAREHOUSE my_warehouse SET AUTO_RESUME = TRUE;

-- Start with smaller size
ALTER WAREHOUSE my_warehouse SET WAREHOUSE_SIZE = 'SMALL';

-- Use multi-cluster for concurrency (Enterprise+)
ALTER WAREHOUSE my_warehouse SET
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  SCALING_POLICY = 'STANDARD';
```

**Cost Monitoring:**
```sql
-- View warehouse usage
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(day, -7, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;

-- View query costs
SELECT
  QUERY_ID,
  USER_NAME,
  WAREHOUSE_NAME,
  EXECUTION_TIME,
  CREDITS_USED_CLOUD_SERVICES
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(day, -1, CURRENT_TIMESTAMP())
ORDER BY CREDITS_USED_CLOUD_SERVICES DESC;
```

### Storage Costs

**Data Retention:**
```sql
-- Set data retention (Time Travel)
ALTER TABLE my_table SET DATA_RETENTION_TIME_IN_DAYS = 1; -- Default is 1 day

-- Enterprise edition supports up to 90 days
ALTER TABLE my_table SET DATA_RETENTION_TIME_IN_DAYS = 90;
```

**Storage Monitoring:**
```sql
-- View storage usage
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE
ORDER BY USAGE_DATE DESC;

-- View table storage
SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  BYTES / (1024*1024*1024) AS SIZE_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
ORDER BY BYTES DESC;
```

---

## Monitoring and Observability

### CloudWatch Integration (Optional)

**Export Snowflake metrics to CloudWatch:**
```python
import boto3
import snowflake.connector

# Connect to Snowflake
conn = snowflake.connector.connect(
    user='myuser',
    password='mypassword',
    account='myaccount',
    warehouse='my_warehouse'
)

# Query metrics
cursor = conn.cursor()
cursor.execute("""
    SELECT WAREHOUSE_NAME, CREDITS_USED
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    WHERE START_TIME >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
""")

# Send to CloudWatch
cloudwatch = boto3.client('cloudwatch')
for row in cursor:
    cloudwatch.put_metric_data(
        Namespace='Snowflake',
        MetricData=[{
            'MetricName': 'CreditsUsed',
            'Value': row[1],
            'Unit': 'Count',
            'Dimensions': [{'Name': 'Warehouse', 'Value': row[0]}]
        }]
    )
```

### Built-in Monitoring

```sql
-- Query history
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(day, -1, CURRENT_TIMESTAMP());

-- Login history
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE EVENT_TIMESTAMP >= DATEADD(day, -7, CURRENT_TIMESTAMP());

-- Access history
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE QUERY_START_TIME >= DATEADD(day, -1, CURRENT_TIMESTAMP());
```

---

## Common Integration Patterns

### Pattern 1: S3 Data Lake → Snowflake

```
AWS S3 (Data Lake)
    │
    ├─ Raw Data (CSV, JSON, Parquet)
    │
    ▼
Snowflake External Stage
    │
    ▼
Snowflake Tables (Structured Data)
    │
    ▼
BI Tools / Analytics
```

### Pattern 2: Real-time Streaming

```
Application
    │
    ▼
AWS Kinesis / Kafka
    │
    ▼
AWS Lambda (Transform)
    │
    ▼
Snowflake (Snowpipe)
    │
    ▼
Real-time Analytics
```

### Pattern 3: ETL Pipeline

```
Source Systems
    │
    ▼
AWS Glue (ETL)
    │
    ▼
S3 (Staging)
    │
    ▼
Snowflake (Load)
    │
    ▼
Data Warehouse
```

---

## Quick Start Checklist

### Phase 1: Account Setup (Day 1)
- [ ] Sign up for Snowflake account
- [ ] Choose AWS as cloud provider
- [ ] Select region (e.g., us-east-1)
- [ ] Complete first login
- [ ] Enable MFA
- [ ] Create first virtual warehouse
- [ ] Create database and schema

### Phase 2: AWS Integration (Day 2-3)
- [ ] Create S3 bucket for data
- [ ] Create IAM role for Snowflake
- [ ] Configure storage integration
- [ ] Create external stage
- [ ] Test data loading from S3

### Phase 3: Data Loading (Week 1)
- [ ] Design table schemas
- [ ] Create tables
- [ ] Load sample data
- [ ] Test queries
- [ ] Set up monitoring

### Phase 4: Production (Week 2+)
- [ ] Configure auto-suspend/resume
- [ ] Set up user roles and permissions
- [ ] Implement cost monitoring
- [ ] Connect BI tools
- [ ] Set up automated pipelines
- [ ] Configure PrivateLink (if needed)

---

## Troubleshooting

### Issue 1: Cannot Connect to Snowflake

**Symptoms:** Connection timeout or refused

**Solutions:**
1. Check firewall allows HTTPS (443) to `*.snowflakecomputing.com`
2. Verify account URL is correct
3. Check credentials
4. Verify MFA if enabled
5. Check IP whitelist if configured

### Issue 2: Cannot Load Data from S3

**Symptoms:** Access denied or file not found

**Solutions:**
1. Verify IAM role trust policy includes Snowflake account
2. Check IAM role has S3 read permissions
3. Verify external ID matches
4. Check S3 bucket policy
5. Verify storage integration is created correctly

### Issue 3: High Costs

**Symptoms:** Unexpected Snowflake bills

**Solutions:**
1. Check warehouse auto-suspend settings
2. Review query history for expensive queries
3. Optimize warehouse sizes
4. Implement resource monitors
5. Set up cost alerts

---

## Resources

### Official Documentation
- Snowflake Documentation: https://docs.snowflake.com/
- AWS Integration Guide: https://docs.snowflake.com/en/user-guide/data-load-s3.html
- PrivateLink Setup: https://docs.snowflake.com/en/user-guide/admin-security-privatelink.html

### AWS Resources
- S3 Documentation: https://docs.aws.amazon.com/s3/
- IAM Documentation: https://docs.aws.amazon.com/iam/
- PrivateLink Documentation: https://docs.aws.amazon.com/vpc/latest/privatelink/

### Community
- Snowflake Community: https://community.snowflake.com/
- AWS Forums: https://forums.aws.amazon.com/

---

## Summary

### What You Need:
1. **Snowflake Account** (Required)
   - Sign up at snowflake.com
   - Choose AWS as provider
   - Select region

2. **AWS Account** (Optional but Recommended)
   - S3 for data storage
   - IAM for access control
   - VPC for PrivateLink (optional)

3. **Network Access** (Required)
   - HTTPS (443) to Snowflake
   - No inbound ports needed

4. **Nothing to Install**
   - Snowflake is fully managed SaaS
   - No servers to provision
   - No infrastructure to manage

### Key Takeaway:
**Snowflake runs ON AWS infrastructure, but you don't manage any AWS resources for Snowflake itself.** You only need AWS resources for data integration (S3, IAM) and optional private connectivity (PrivateLink).

---

**Last Updated:** February 1, 2026  
**Version:** 1.0

---

**END OF GUIDE**
