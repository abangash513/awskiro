-- CloudOptima AI - 10 Demo Accounts (4 AWS, 3 Azure, 2 GCP, 1 OCI)
-- Realistic multi-cloud cost data for client presentation

-- Clear existing data
TRUNCATE TABLE budget_alerts CASCADE;
TRUNCATE TABLE budgets CASCADE;
TRUNCATE TABLE recommendations CASCADE;
TRUNCATE TABLE cost_summaries CASCADE;
TRUNCATE TABLE cost_records CASCADE;

-- ============================================
-- AWS ACCOUNT 1: Production (aws-prod-123456789012)
-- ============================================
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('aws-prod-123456789012', 'us-east-1', 'i-prod-web-01', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 285.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-prod-123456789012', 'us-east-1', 'i-prod-web-02', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 285.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-prod-123456789012', 'us-east-1', 'prod-rds-primary', 'AWS::RDS::DBInstance', 'Amazon RDS', 'Database', 485.75, 'USD', '2026-02-16', NOW(), NOW()),
('aws-prod-123456789012', 'us-east-1', 'prod-s3-data', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 245.30, 'USD', '2026-02-16', NOW(), NOW()),
('aws-prod-123456789012', 'us-east-1', 'prod-eks-cluster', 'AWS::EKS::Cluster', 'Amazon EKS', 'Container', 385.50, 'USD', '2026-02-16', NOW(), NOW()),
('aws-prod-123456789012', 'global', 'prod-cloudfront', 'AWS::CloudFront::Distribution', 'Amazon CloudFront', 'CDN', 185.40, 'USD', '2026-02-16', NOW(), NOW());

-- AWS ACCOUNT 2: Development (aws-dev-234567890123)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('aws-dev-234567890123', 'us-west-2', 'i-dev-app-01', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 125.60, 'USD', '2026-02-16', NOW(), NOW()),
('aws-dev-234567890123', 'us-west-2', 'dev-rds-mysql', 'AWS::RDS::DBInstance', 'Amazon RDS', 'Database', 145.80, 'USD', '2026-02-16', NOW(), NOW()),
('aws-dev-234567890123', 'us-west-2', 'dev-s3-bucket', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 65.20, 'USD', '2026-02-16', NOW(), NOW()),
('aws-dev-234567890123', 'us-west-2', 'dev-lambda-api', 'AWS::Lambda::Function', 'AWS Lambda', 'Compute', 45.30, 'USD', '2026-02-16', NOW(), NOW());

-- AWS ACCOUNT 3: Staging (aws-staging-345678901234)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('aws-staging-345678901234', 'eu-west-1', 'i-staging-web', 'AWS::EC2::Instance', 'Amazon EC2', 'Compute', 185.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-staging-345678901234', 'eu-west-1', 'staging-rds', 'AWS::RDS::DBInstance', 'Amazon RDS', 'Database', 245.60, 'USD', '2026-02-16', NOW(), NOW()),
('aws-staging-345678901234', 'eu-west-1', 'staging-s3', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 95.30, 'USD', '2026-02-16', NOW(), NOW()),
('aws-staging-345678901234', 'eu-west-1', 'staging-elb', 'AWS::ElasticLoadBalancing::LoadBalancer', 'Elastic Load Balancing', 'Network', 75.20, 'USD', '2026-02-16', NOW(), NOW());

-- AWS ACCOUNT 4: Analytics (aws-analytics-456789012345)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('aws-analytics-456789012345', 'us-east-1', 'analytics-redshift', 'AWS::Redshift::Cluster', 'Amazon Redshift', 'Data Warehouse', 685.90, 'USD', '2026-02-16', NOW(), NOW()),
('aws-analytics-456789012345', 'us-east-1', 'analytics-emr', 'AWS::EMR::Cluster', 'Amazon EMR', 'Big Data', 445.60, 'USD', '2026-02-16', NOW(), NOW()),
('aws-analytics-456789012345', 'us-east-1', 'analytics-s3-lake', 'AWS::S3::Bucket', 'Amazon S3', 'Storage', 385.40, 'USD', '2026-02-16', NOW(), NOW()),
('aws-analytics-456789012345', 'us-east-1', 'analytics-glue', 'AWS::Glue::Job', 'AWS Glue', 'ETL', 185.30, 'USD', '2026-02-16', NOW(), NOW());

-- ============================================
-- AZURE ACCOUNT 1: Production (sub-azure-prod-001)
-- ============================================
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('sub-azure-prod-001', 'prod-eastus-rg', 'vm-prod-web-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Compute', 225.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'vm-prod-web-02', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Compute', 225.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'sql-prod-primary', 'Microsoft.Sql/servers/databases', 'SQL Database', 'Database', 525.80, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'storage-prod', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 185.40, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'aks-prod-cluster', 'Microsoft.ContainerService/managedClusters', 'Azure Kubernetes Service', 'Container', 485.60, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-prod-001', 'prod-eastus-rg', 'appservice-prod', 'Microsoft.Web/sites', 'App Service', 'Web', 225.00, 'USD', '2026-02-16', NOW(), NOW());

-- AZURE ACCOUNT 2: Development (sub-azure-dev-002)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('sub-azure-dev-002', 'dev-westus-rg', 'vm-dev-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Compute', 115.30, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'sql-dev', 'Microsoft.Sql/servers/databases', 'SQL Database', 'Database', 125.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'storage-dev', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 55.60, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-dev-002', 'dev-westus-rg', 'appservice-dev', 'Microsoft.Web/sites', 'App Service', 'Web', 85.00, 'USD', '2026-02-16', NOW(), NOW());

-- AZURE ACCOUNT 3: Testing (sub-azure-test-003)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('sub-azure-test-003', 'test-centralus-rg', 'vm-test-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Compute', 95.40, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-test-003', 'test-centralus-rg', 'sql-test', 'Microsoft.Sql/servers/databases', 'SQL Database', 'Database', 85.30, 'USD', '2026-02-16', NOW(), NOW()),
('sub-azure-test-003', 'test-centralus-rg', 'storage-test', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 35.20, 'USD', '2026-02-16', NOW(), NOW());

-- ============================================
-- GCP ACCOUNT 1: Production (gcp-prod-project-001)
-- ============================================
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('gcp-prod-project-001', 'us-central1', 'gce-prod-web-01', 'compute.googleapis.com/Instance', 'Compute Engine', 'Compute', 265.40, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-prod-project-001', 'us-central1', 'gce-prod-web-02', 'compute.googleapis.com/Instance', 'Compute Engine', 'Compute', 265.40, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-prod-project-001', 'us-central1', 'cloudsql-prod', 'sqladmin.googleapis.com/Database', 'Cloud SQL', 'Database', 445.75, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-prod-project-001', 'us-central1', 'gcs-prod-bucket', 'storage.googleapis.com/Bucket', 'Cloud Storage', 'Storage', 185.30, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-prod-project-001', 'us-central1', 'gke-prod-cluster', 'container.googleapis.com/Cluster', 'Google Kubernetes Engine', 'Container', 385.50, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-prod-project-001', 'global', 'cdn-prod', 'compute.googleapis.com/CDN', 'Cloud CDN', 'CDN', 145.20, 'USD', '2026-02-16', NOW(), NOW());

-- GCP ACCOUNT 2: Development (gcp-dev-project-002)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('gcp-dev-project-002', 'us-west1', 'gce-dev-01', 'compute.googleapis.com/Instance', 'Compute Engine', 'Compute', 135.60, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-dev-project-002', 'us-west1', 'cloudsql-dev', 'sqladmin.googleapis.com/Database', 'Cloud SQL', 'Database', 165.80, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-dev-project-002', 'us-west1', 'gcs-dev-bucket', 'storage.googleapis.com/Bucket', 'Cloud Storage', 'Storage', 75.20, 'USD', '2026-02-16', NOW(), NOW()),
('gcp-dev-project-002', 'us-west1', 'cloud-functions', 'cloudfunctions.googleapis.com/Function', 'Cloud Functions', 'Serverless', 55.30, 'USD', '2026-02-16', NOW(), NOW());

-- ============================================
-- OCI ACCOUNT: Production (oci-prod-tenancy-001)
-- ============================================
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('oci-prod-tenancy-001', 'us-ashburn-1', 'instance-prod-01', 'oci.compute.Instance', 'Compute', 'Compute', 245.60, 'USD', '2026-02-16', NOW(), NOW()),
('oci-prod-tenancy-001', 'us-ashburn-1', 'instance-prod-02', 'oci.compute.Instance', 'Compute', 'Compute', 245.60, 'USD', '2026-02-16', NOW(), NOW()),
('oci-prod-tenancy-001', 'us-ashburn-1', 'adb-prod', 'oci.database.AutonomousDatabase', 'Autonomous Database', 'Database', 485.90, 'USD', '2026-02-16', NOW(), NOW()),
('oci-prod-tenancy-001', 'us-ashburn-1', 'object-storage-prod', 'oci.objectstorage.Bucket', 'Object Storage', 'Storage', 165.40, 'USD', '2026-02-16', NOW(), NOW()),
('oci-prod-tenancy-001', 'us-ashburn-1', 'oke-prod-cluster', 'oci.containerengine.Cluster', 'Container Engine', 'Container', 345.50, 'USD', '2026-02-16', NOW(), NOW());

-- ============================================
-- RECOMMENDATIONS - Multi-Cloud (20 recommendations)
-- ============================================
INSERT INTO recommendations (
    subscription_id, resource_group, resource_name, resource_type,
    title, description, category, impact,
    estimated_monthly_savings, estimated_annual_savings, currency, confidence_score,
    current_config, recommended_config,
    implementation_effort, implementation_steps, risk_level,
    status, source, valid_from, is_stale, created_at, updated_at
) VALUES

-- AWS Recommendations
('aws-prod-123456789012', 'us-east-1', 'i-prod-web-01', 'AWS::EC2::Instance',
 'AWS Prod: Purchase EC2 Reserved Instance',
 'EC2 instances run 24/7. 1-year RI provides 40% savings.',
 'RESERVED_INSTANCES', 'HIGH',
 114.16, 1369.92, 'USD', 0.92,
 'On-Demand: $285.40/day', '1-Year RI: $171.24/day',
 'MEDIUM', '1. Review usage\n2. Purchase RI\n3. Apply to instances', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('aws-dev-234567890123', 'us-west-2', 'i-dev-app-01', 'AWS::EC2::Instance',
 'AWS Dev: Use Spot Instances',
 'Development workload can tolerate interruptions. Spot instances provide 70% savings.',
 'RIGHTSIZING', 'HIGH',
 87.92, 1055.04, 'USD', 0.85,
 'On-Demand: $125.60/day', 'Spot: $37.68/day',
 'MEDIUM', '1. Test spot compatibility\n2. Implement spot fleet\n3. Monitor', 'MEDIUM',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('aws-staging-345678901234', 'eu-west-1', 'staging-rds', 'AWS::RDS::DBInstance',
 'AWS Staging: Downsize RDS Instance',
 'Staging database shows 25% utilization. Downsize for 50% savings.',
 'RIGHTSIZING', 'MEDIUM',
 122.80, 1473.60, 'USD', 0.80,
 'db.r5.xlarge: $245.60/day', 'db.r5.large: $122.80/day',
 'LOW', '1. Snapshot database\n2. Modify instance class\n3. Test', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('aws-analytics-456789012345', 'us-east-1', 'analytics-redshift', 'AWS::Redshift::Cluster',
 'AWS Analytics: Pause Redshift During Off-Hours',
 'Redshift cluster unused 16 hours/day. Pause for 67% savings.',
 'IDLE_RESOURCES', 'HIGH',
 459.27, 5511.24, 'USD', 0.88,
 'Running 24/7: $685.90/day', 'Running 8hrs/day: $226.63/day',
 'LOW', '1. Implement pause schedule\n2. Automate with Lambda\n3. Monitor', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Azure Recommendations
('sub-azure-prod-001', 'prod-eastus-rg', 'vm-prod-web-01', 'Microsoft.Compute/virtualMachines',
 'Azure Prod: Rightsize VM',
 'VM shows 20% CPU utilization. Downsize for 50% savings.',
 'RIGHTSIZING', 'HIGH',
 112.75, 1353.00, 'USD', 0.87,
 'Standard_D4s_v3: $225.50/day', 'Standard_D2s_v3: $112.75/day',
 'LOW', '1. Snapshot VM\n2. Resize\n3. Verify', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('sub-azure-prod-001', 'prod-eastus-rg', 'sql-prod-primary', 'Microsoft.Sql/servers/databases',
 'Azure Prod: SQL Reserved Capacity',
 'SQL Database runs continuously. 3-year reservation provides 62% savings.',
 'RESERVED_INSTANCES', 'HIGH',
 325.80, 3909.60, 'USD', 0.93,
 'Pay-as-you-go: $525.80/day', '3-Year Reserved: $200.00/day',
 'MEDIUM', '1. Review commitment\n2. Purchase reservation\n3. Apply', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('sub-azure-dev-002', 'dev-westus-rg', 'vm-dev-01', 'Microsoft.Compute/virtualMachines',
 'Azure Dev: Deallocate After Hours',
 'Dev VM unused 16 hours/day. Auto-shutdown for 67% savings.',
 'IDLE_RESOURCES', 'MEDIUM',
 77.20, 926.40, 'USD', 0.85,
 'Running 24/7: $115.30/day', 'Running 8hrs/day: $38.10/day',
 'LOW', '1. Configure auto-shutdown\n2. Set schedule\n3. Notify team', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('sub-azure-test-003', 'test-centralus-rg', 'storage-test', 'Microsoft.Storage/storageAccounts',
 'Azure Test: Delete Old Test Data',
 'Test storage contains data >90 days old. Delete for 100% savings.',
 'IDLE_RESOURCES', 'LOW',
 35.20, 422.40, 'USD', 0.75,
 'Current: $35.20/day', 'After cleanup: $0/day',
 'LOW', '1. Identify old data\n2. Backup if needed\n3. Delete', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- GCP Recommendations
('gcp-prod-project-001', 'us-central1', 'gce-prod-web-01', 'compute.googleapis.com/Instance',
 'GCP Prod: Use Committed Use Discounts',
 'Compute instances run continuously. 1-year CUD provides 37% savings.',
 'SAVINGS_PLANS', 'HIGH',
 196.40, 2356.80, 'USD', 0.90,
 'On-Demand: $530.80/day (2 instances)', 'With CUD: $334.40/day',
 'MEDIUM', '1. Analyze usage\n2. Purchase CUD\n3. Apply', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('gcp-prod-project-001', 'us-central1', 'cloudsql-prod', 'sqladmin.googleapis.com/Database',
 'GCP Prod: Migrate to Cloud SQL Enterprise',
 'Cloud SQL can use Enterprise edition for better performance at same cost.',
 'RIGHTSIZING', 'MEDIUM',
 0.00, 0.00, 'USD', 0.70,
 'Standard: $445.75/day', 'Enterprise: $445.75/day (better performance)',
 'MEDIUM', '1. Test Enterprise features\n2. Schedule migration\n3. Migrate', 'MEDIUM',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('gcp-dev-project-002', 'us-west1', 'gce-dev-01', 'compute.googleapis.com/Instance',
 'GCP Dev: Use Preemptible VMs',
 'Development instance can use preemptible VMs for 80% savings.',
 'RIGHTSIZING', 'HIGH',
 108.48, 1301.76, 'USD', 0.82,
 'Standard: $135.60/day', 'Preemptible: $27.12/day',
 'MEDIUM', '1. Test preemptible compatibility\n2. Implement\n3. Monitor', 'MEDIUM',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('gcp-dev-project-002', 'us-west1', 'gcs-dev-bucket', 'storage.googleapis.com/Bucket',
 'GCP Dev: Move to Nearline Storage',
 'Dev bucket data accessed <1/month. Nearline provides 50% savings.',
 'STORAGE_OPTIMIZATION', 'MEDIUM',
 37.60, 451.20, 'USD', 0.78,
 'Standard: $75.20/day', 'Nearline: $37.60/day',
 'LOW', '1. Identify cold data\n2. Create lifecycle policy\n3. Apply', 'LOW',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- OCI Recommendations
('oci-prod-tenancy-001', 'us-ashburn-1', 'instance-prod-01', 'oci.compute.Instance',
 'OCI Prod: Use Flexible Shapes',
 'Instances can use flexible shapes for better price/performance.',
 'RIGHTSIZING', 'MEDIUM',
 73.68, 884.16, 'USD', 0.80,
 'VM.Standard2.4: $245.60/day', 'VM.Standard.E4.Flex: $171.92/day',
 'MEDIUM', '1. Test flexible shape\n2. Resize instances\n3. Monitor', 'MEDIUM',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

('oci-prod-tenancy-001', 'us-ashburn-1', 'adb-prod', 'oci.database.AutonomousDatabase',
 'OCI Prod: Enable Auto-Scaling',
 'Autonomous DB can auto-scale during peak hours only.',
 'RIGHTSIZING', 'MEDIUM',
 145.77, 1749.24, 'USD', 0.75,
 'Fixed capacity: $485.90/day', 'Auto-scaling: $340.13/day average',
 'LOW', '1. Enable auto-scaling\n2. Set min/max\n3. Monitor', 'LOW',
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
('AWS Production', 'AWS production account monthly budget', 'aws-prod-123456789012', NULL,
 50000.00, 'USD', 'MONTHLY', '50,75,90,100',
 48225.00, 96.45,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('AWS Development', 'AWS development account monthly budget', 'aws-dev-234567890123', NULL,
 12000.00, 'USD', 'MONTHLY', '60,80,100',
 11439.00, 95.33,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('Azure Production', 'Azure production subscription monthly budget', 'sub-azure-prod-001', NULL,
 55000.00, 'USD', 'MONTHLY', '50,75,90,100',
 52596.00, 95.63,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('GCP Production', 'GCP production project monthly budget', 'gcp-prod-project-001', NULL,
 45000.00, 'USD', 'MONTHLY', '50,75,90,100',
 41985.00, 93.30,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('OCI Production', 'OCI production tenancy monthly budget', 'oci-prod-tenancy-001', NULL,
 40000.00, 'USD', 'MONTHLY', '50,75,90,100',
 37440.00, 93.60,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('Multi-Cloud Annual', 'Annual budget across all cloud providers', 'multi-cloud-all', NULL,
 2000000.00, 'USD', 'ANNUALLY', '50,75,90,100',
 285420.00, 14.27,
 '2026-01-01', '2026-12-31', true, NOW(), NOW());

-- Verification
SELECT 'Summary by Cloud Provider:' as info;
SELECT 
    CASE 
        WHEN subscription_id LIKE 'aws-%' THEN 'AWS'
        WHEN subscription_id LIKE 'sub-azure-%' THEN 'Azure'
        WHEN subscription_id LIKE 'gcp-%' THEN 'GCP'
        WHEN subscription_id LIKE 'oci-%' THEN 'OCI'
        ELSE 'Other'
    END as cloud_provider,
    COUNT(DISTINCT subscription_id) as accounts,
    COUNT(*) as cost_records,
    ROUND(SUM(cost)::numeric, 2) as total_cost
FROM cost_records 
GROUP BY cloud_provider
ORDER BY total_cost DESC;

SELECT 'Total Recommendations:' as info;
SELECT COUNT(*) as total, ROUND(SUM(estimated_monthly_savings)::numeric, 2) as monthly_savings
FROM recommendations;
