-- CloudOptima AI - Multi-Cloud Mock Data
-- Two Azure subscriptions + One AWS account

-- Clear existing data
TRUNCATE TABLE budget_alerts CASCADE;
TRUNCATE TABLE budgets CASCADE;
TRUNCATE TABLE recommendations CASCADE;
TRUNCATE TABLE cost_summaries CASCADE;
TRUNCATE TABLE cost_records CASCADE;

-- ============================================
-- AZURE SUBSCRIPTION 1: Production (sub-azure-prod-001)
-- ============================================

-- Virtual Machines
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('sub-azure-prod-001', 'prod-eastus-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 185.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 182.30, 'USD', '2026-02-15', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'web-vm-02', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 185.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'web-vm-02', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 182.30, 'USD', '2026-02-15', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'api-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 245.75, 'USD', '2026-02-16', NOW(), NOW()),

-- SQL Database
('sub-azure-prod-001', 'prod-eastus-rg', 'sql-prod-primary', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 425.80, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'sql-prod-primary', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 420.50, 'USD', '2026-02-15', NOW(), NOW()),

-- Storage
('sub-azure-prod-001', 'prod-eastus-rg', 'prodstorageacct01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 125.40, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'prodstorageacct01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 122.80, 'USD', '2026-02-15', NOW(), NOW()),

-- Azure Kubernetes Service
('sub-azure-prod-001', 'prod-eastus-rg', 'aks-prod-cluster', 'Microsoft.ContainerService/managedClusters', 'Azure Kubernetes Service', 'Container Service', 385.60, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'aks-prod-cluster', 'Microsoft.ContainerService/managedClusters', 'Azure Kubernetes Service', 'Container Service', 380.20, 'USD', '2026-02-15', NOW(), NOW()),

-- App Service
('sub-azure-prod-001', 'prod-eastus-rg', 'webapp-prod-01', 'Microsoft.Web/sites', 'App Service', 'App Service', 175.00, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'webapp-prod-01', 'Microsoft.Web/sites', 'App Service', 'App Service', 175.00, 'USD', '2026-02-15', NOW(), NOW());

-- ============================================
-- AZURE SUBSCRIPTION 2: Development (sub-azure-dev-002)
-- ============================================

-- Virtual Machines
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('sub-azure-dev-002', 'dev-westus-rg', 'dev-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 95.30, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'dev-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 92.80, 'USD', '2026-02-15', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'dev-vm-02', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 95.30, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'test-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 45.20, 'USD', '2026-02-16', NOW(), NOW()),

-- SQL Database
('sub-azure-dev-002', 'dev-westus-rg', 'sql-dev-db', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 85.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'sql-dev-db', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 82.30, 'USD', '2026-02-15', NOW(), NOW()),

-- Storage
('sub-azure-dev-002', 'dev-westus-rg', 'devstorageacct01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 35.60, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'devstorageacct01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 33.20, 'USD', '2026-02-15', NOW(), NOW()),

-- App Service
('sub-azure-dev-002', 'dev-westus-rg', 'webapp-dev-01', 'Microsoft.Web/sites', 'App Service', 'App Service', 65.00, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'webapp-dev-01', 'Microsoft.Web/sites', 'App Service', 'App Service', 65.00, 'USD', '2026-02-15', NOW(), NOW());

-- ============================================
-- AWS ACCOUNT: Production (aws-account-123456789012)
-- ============================================

-- EC2 Instances
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('aws-account-123456789012', 'us-east-1', 'i-0abc123prod01', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 215.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'i-0abc123prod01', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 212.80, 'USD', '2026-02-15', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'i-0abc123prod02', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 215.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'us-west-2', 'i-0def456prod03', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 185.60, 'USD', '2026-02-16', NOW(), NOW()),

-- RDS Database
('aws-account-123456789012', 'us-east-1', 'prod-mysql-db-01', 'AWS::RDS::DBInstance', 'Amazon RDS', 'Database', 385.75, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'prod-mysql-db-01', 'AWS::RDS::DBInstance', 'Amazon RDS', 'Database', 380.20, 'USD', '2026-02-15', NOW(), NOW()),

-- S3 Storage
('aws-account-123456789012', 'us-east-1', 'prod-data-bucket', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 145.30, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'prod-data-bucket', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 142.80, 'USD', '2026-02-15', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'prod-backup-bucket', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 95.60, 'USD', '2026-02-16', NOW(), NOW()),

-- Lambda
('aws-account-123456789012', 'us-east-1', 'api-lambda-function', 'AWS::Lambda::Function', 'AWS Lambda', 'Compute', 45.80, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'api-lambda-function', 'AWS::Lambda::Function', 'AWS Lambda', 'Compute', 43.20, 'USD', '2026-02-15', NOW(), NOW()),

-- EKS Cluster
('aws-account-123456789012', 'us-east-1', 'prod-eks-cluster', 'AWS::EKS::Cluster', 'Amazon EKS', 'Container Service', 285.50, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'us-east-1', 'prod-eks-cluster', 'AWS::EKS::Cluster', 'Amazon EKS', 'Container Service', 280.30, 'USD', '2026-02-15', NOW(), NOW()),

-- CloudFront
('aws-account-123456789012', 'global', 'prod-cdn-distribution', 'AWS::CloudFront::Distribution', 'Amazon CloudFront', 'CDN', 125.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-account-123456789012', 'global', 'prod-cdn-distribution', 'AWS::CloudFront::Distribution', 'Amazon CloudFront', 'CDN', 122.60, 'USD', '2026-02-15', NOW(), NOW());

-- ============================================
-- RECOMMENDATIONS - Multi-Cloud
-- ============================================

INSERT INTO recommendations (
    subscription_id, resource_group, resource_name, resource_type,
    title, description, category, impact,
    estimated_monthly_savings, estimated_annual_savings, currency, confidence_score,
    current_config, recommended_config,
    implementation_effort, implementation_steps, risk_level,
    status, source, valid_from, is_stale, created_at, updated_at
) VALUES

-- Azure Prod Recommendation 1
('sub-azure-prod-001', 'prod-eastus-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines',
 'Azure: Rightsize VM Standard_D4s_v3 → Standard_D2s_v3',
 'VM web-vm-01 shows consistent underutilization (18% CPU, 30% memory). Downsizing to Standard_D2s_v3 maintains performance while reducing costs by 50%.',
 'RIGHTSIZING', 'HIGH',
 92.75, 1113.00, 'USD', 0.87,
 'Standard_D4s_v3 (4 vCPUs, 16 GB RAM) - $185.50/day',
 'Standard_D2s_v3 (2 vCPUs, 8 GB RAM) - $92.75/day',
 'LOW', '1. Snapshot VM\n2. Stop during maintenance window\n3. Resize to Standard_D2s_v3\n4. Start and verify\n5. Monitor 48 hours',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Azure Prod Recommendation 2
('sub-azure-prod-001', 'prod-eastus-rg', 'sql-prod-primary', 'Microsoft.Sql/servers/databases',
 'Azure: Purchase 3-Year Reserved Instance for SQL Database',
 'SQL Database runs 24/7 with consistent usage. A 3-year reserved instance provides 62% savings compared to pay-as-you-go.',
 'RESERVED_INSTANCES', 'HIGH',
 263.60, 3163.20, 'USD', 0.92,
 'Pay-as-you-go: $425.80/day',
 '3-Year Reserved Instance: $162.20/day (62% savings)',
 'MEDIUM', '1. Review 3-year commitment\n2. Purchase RI via Azure Portal\n3. Apply to database\n4. Verify billing discount\n5. Document renewal date',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Azure Prod Recommendation 3
('sub-azure-prod-001', 'prod-eastus-rg', 'prodstorageacct01', 'Microsoft.Storage/storageAccounts',
 'Azure: Implement Storage Lifecycle Policy',
 'Analysis shows 3.2 TB of blob data not accessed in 90+ days. Move to Cool tier for 50% storage cost reduction.',
 'STORAGE_OPTIMIZATION', 'MEDIUM',
 62.70, 752.40, 'USD', 0.78,
 'Hot tier: $0.0184/GB/month for 3.2 TB',
 'Cool tier: $0.0092/GB/month for 3.2 TB',
 'LOW', '1. Identify cold data\n2. Create lifecycle policy\n3. Test on 100GB subset\n4. Apply to all cold data\n5. Monitor access patterns',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Azure Dev Recommendation
('sub-azure-dev-002', 'dev-westus-rg', 'test-vm-01', 'Microsoft.Compute/virtualMachines',
 'Azure Dev: Deallocate Idle Test VM',
 'Test VM shows zero activity for 21 days (0% CPU, no network). Deallocate when not in use to eliminate compute costs.',
 'IDLE_RESOURCES', 'MEDIUM',
 45.20, 542.40, 'USD', 0.85,
 'Running 24/7: $45.20/day',
 'Deallocate: $0/day compute + $2/day storage',
 'LOW', '1. Confirm with dev team\n2. Take snapshot\n3. Deallocate VM\n4. Document startup procedure\n5. Set reminder for cleanup',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- AWS Recommendation 1
('aws-account-123456789012', 'us-east-1', 'i-0abc123prod01', 'AWS::EC2::Instance',
 'AWS: Purchase EC2 Reserved Instance (1-Year)',
 'EC2 instance i-0abc123prod01 (m5.2xlarge) runs continuously. 1-year RI provides 40% savings.',
 'RESERVED_INSTANCES', 'HIGH',
 86.16, 1033.92, 'USD', 0.90,
 'On-Demand: $215.40/day',
 '1-Year Standard RI: $129.24/day (40% savings)',
 'MEDIUM', '1. Review instance usage patterns\n2. Purchase RI in AWS Console\n3. Apply to instance\n4. Verify billing\n5. Set renewal reminder',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- AWS Recommendation 2
('aws-account-123456789012', 'us-east-1', 'prod-mysql-db-01', 'AWS::RDS::DBInstance',
 'AWS: Upgrade RDS to Graviton2 Instance',
 'RDS MySQL database can migrate to Graviton2 (db.r6g.xlarge) for 20% cost savings with better performance.',
 'RIGHTSIZING', 'HIGH',
 77.15, 925.80, 'USD', 0.82,
 'db.r5.xlarge: $385.75/day',
 'db.r6g.xlarge: $308.60/day (20% savings, better performance)',
 'MEDIUM', '1. Test application compatibility\n2. Create snapshot\n3. Schedule maintenance window\n4. Modify instance class\n5. Verify application performance',
 'MEDIUM',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- AWS Recommendation 3
('aws-account-123456789012', 'us-east-1', 'prod-backup-bucket', 'AWS::S3::Bucket',
 'AWS: Move S3 Backups to Glacier Deep Archive',
 'Backup bucket contains 5TB of data older than 90 days. Move to Glacier Deep Archive for 95% storage cost reduction.',
 'STORAGE_OPTIMIZATION', 'HIGH',
 90.82, 1089.84, 'USD', 0.88,
 'S3 Standard: $0.023/GB/month for 5TB',
 'Glacier Deep Archive: $0.00099/GB/month for 5TB',
 'LOW', '1. Identify backup data >90 days\n2. Create S3 lifecycle rule\n3. Test restore process\n4. Apply lifecycle policy\n5. Monitor transition',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- AWS Recommendation 4
('aws-account-123456789012', 'us-east-1', 'prod-eks-cluster', 'AWS::EKS::Cluster',
 'AWS: Apply Compute Savings Plan for EKS',
 'Consistent compute usage across EC2 and EKS. Compute Savings Plan (1-year) provides 17% savings.',
 'SAVINGS_PLANS', 'HIGH',
 119.60, 1435.20, 'USD', 0.89,
 'On-Demand compute: $700/day average',
 'Compute Savings Plan: $581/day (17% savings)',
 'MEDIUM', '1. Analyze compute usage\n2. Calculate commitment amount\n3. Purchase Savings Plan\n4. Monitor utilization\n5. Adjust at renewal',
 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW());

-- ============================================
-- BUDGETS - Multi-Cloud
-- ============================================

INSERT INTO budgets (
    name, description, subscription_id, resource_group,
    amount, currency, time_grain, alert_thresholds,
    current_spend, spend_percentage,
    start_date, end_date, is_active,
    created_at, updated_at
) VALUES
-- Azure Production Budget
('Azure Production Monthly', 'Monthly budget for Azure production subscription', 'sub-azure-prod-001', 'prod-eastus-rg',
 8000.00, 'USD', 'MONTHLY', '50,75,90,100',
 4235.85, 52.95,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

-- Azure Development Budget
('Azure Development Monthly', 'Monthly budget for Azure dev/test subscription', 'sub-azure-dev-002', 'dev-westus-rg',
 2000.00, 'USD', 'MONTHLY', '60,80,100',
 1045.20, 52.26,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

-- AWS Production Budget
('AWS Production Monthly', 'Monthly budget for AWS production account', 'aws-account-123456789012', NULL,
 10000.00, 'USD', 'MONTHLY', '50,75,90,100',
 5234.65, 52.35,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

-- Multi-Cloud Annual Budget
('Multi-Cloud Annual Budget', 'Annual budget across all cloud providers', 'multi-cloud', NULL,
 200000.00, 'USD', 'ANNUALLY', '50,75,90,100',
 31547.80, 15.77,
 '2026-01-01', '2026-12-31', true, NOW(), NOW());

-- ============================================
-- COST SUMMARIES
-- ============================================

INSERT INTO cost_summaries (
    subscription_id, resource_group,
    period_start, period_end, granularity,
    total_cost, currency,
    cost_by_service, cost_by_resource_type,
    previous_period_cost, cost_change_percent,
    created_at
) VALUES
-- Azure Production Summary
('sub-azure-prod-001', 'prod-eastus-rg',
 '2026-02-16', '2026-02-16', 'daily',
 2117.55, 'USD',
 '{"Virtual Machines": 616.75, "SQL Database": 425.80, "Storage": 125.40, "Azure Kubernetes Service": 385.60, "App Service": 175.00}',
 '{"Microsoft.Compute/virtualMachines": 616.75, "Microsoft.Sql/servers/databases": 425.80, "Microsoft.Storage/storageAccounts": 125.40}',
 2055.30, 3.03,
 NOW()),

-- Azure Development Summary
('sub-azure-dev-002', 'dev-westus-rg',
 '2026-02-16', '2026-02-16', 'daily',
 522.60, 'USD',
 '{"Virtual Machines": 235.80, "SQL Database": 85.50, "Storage": 35.60, "App Service": 65.00}',
 '{"Microsoft.Compute/virtualMachines": 235.80, "Microsoft.Sql/servers/databases": 85.50, "Microsoft.Storage/storageAccounts": 35.60}',
 508.20, 2.83,
 NOW()),

-- AWS Production Summary
('aws-account-123456789012', NULL,
 '2026-02-16', '2026-02-16', 'daily',
 2617.30, 'USD',
 '{"Amazon EC2": 616.40, "Amazon RDS": 385.75, "Amazon S3": 240.90, "Amazon EKS": 285.50, "AWS Lambda": 45.80, "Amazon CloudFront": 125.40}',
 '{"AWS::EC2::Instance": 616.40, "AWS::RDS::DBInstance": 385.75, "AWS::S3::Bucket": 240.90}',
 2538.90, 3.09,
 NOW());

-- Verification queries
SELECT 'Cost Records by Cloud Provider:' as summary;
SELECT 
    CASE 
        WHEN subscription_id LIKE 'sub-azure%' THEN 'Azure'
        WHEN subscription_id LIKE 'aws-%' THEN 'AWS'
        ELSE 'Other'
    END as cloud_provider,
    COUNT(*) as record_count,
    ROUND(SUM(cost)::numeric, 2) as total_cost
FROM cost_records 
GROUP BY cloud_provider
ORDER BY total_cost DESC;

SELECT 'Cost Records by Subscription:' as summary;
SELECT 
    subscription_id,
    COUNT(*) as record_count,
    ROUND(SUM(cost)::numeric, 2) as total_cost
FROM cost_records 
GROUP BY subscription_id
ORDER BY total_cost DESC;

SELECT 'Recommendations by Cloud:' as summary;
SELECT 
    CASE 
        WHEN subscription_id LIKE 'sub-azure%' THEN 'Azure'
        WHEN subscription_id LIKE 'aws-%' THEN 'AWS'
        ELSE 'Other'
    END as cloud_provider,
    COUNT(*) as recommendation_count,
    ROUND(SUM(estimated_monthly_savings)::numeric, 2) as monthly_savings,
    ROUND(SUM(estimated_annual_savings)::numeric, 2) as annual_savings
FROM recommendations 
GROUP BY cloud_provider
ORDER BY monthly_savings DESC;

SELECT 'Total Summary:' as summary;
SELECT 
    COUNT(DISTINCT subscription_id) as total_accounts,
    COUNT(*) as total_cost_records,
    ROUND(SUM(cost)::numeric, 2) as total_cost
FROM cost_records;

SELECT 
    COUNT(*) as total_recommendations,
    ROUND(SUM(estimated_monthly_savings)::numeric, 2) as total_monthly_savings,
    ROUND(SUM(estimated_annual_savings)::numeric, 2) as total_annual_savings
FROM recommendations;
