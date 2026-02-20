-- CloudOptima AI - Mock Data Script
-- This script adds sample cost and recommendation data for demo purposes

-- Clear existing data (optional)
TRUNCATE TABLE budget_alerts CASCADE;
TRUNCATE TABLE budgets CASCADE;
TRUNCATE TABLE recommendations CASCADE;
TRUNCATE TABLE cost_summaries CASCADE;
TRUNCATE TABLE cost_records CASCADE;

-- ============================================
-- COST RECORDS - Sample Azure costs
-- ============================================

-- Virtual Machines costs (last 7 days)
INSERT INTO cost_records (subscription_id, resource_group, resource_name, resource_type, service_name, meter_category, cost, currency, usage_date, created_at, updated_at) VALUES
('sub-12345-prod', 'production-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 152.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 148.20, 'USD', '2026-02-15', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 150.75, 'USD', '2026-02-14', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'web-vm-02', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 95.30, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'web-vm-02', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 92.80, 'USD', '2026-02-15', NOW(), NOW()),

-- SQL Database costs
('sub-12345-prod', 'production-rg', 'db-sql-prod', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 325.75, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'db-sql-prod', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 320.50, 'USD', '2026-02-15', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'db-sql-prod', 'Microsoft.Sql/servers/databases', 'SQL Database', 'SQL Database', 318.90, 'USD', '2026-02-14', NOW(), NOW()),

-- Storage costs
('sub-12345-prod', 'production-rg', 'storage-prod-01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 48.20, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'storage-prod-01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 45.80, 'USD', '2026-02-15', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'storage-prod-01', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 47.10, 'USD', '2026-02-14', NOW(), NOW()),

-- App Service costs
('sub-12345-prod', 'production-rg', 'app-service-web', 'Microsoft.Web/sites', 'App Service', 'App Service', 125.00, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'app-service-web', 'Microsoft.Web/sites', 'App Service', 'App Service', 125.00, 'USD', '2026-02-15', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'app-service-web', 'Microsoft.Web/sites', 'App Service', 'App Service', 125.00, 'USD', '2026-02-14', NOW(), NOW()),

-- Azure Kubernetes Service
('sub-12345-prod', 'production-rg', 'aks-cluster-01', 'Microsoft.ContainerService/managedClusters', 'Azure Kubernetes Service', 'Container Service', 285.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-prod', 'production-rg', 'aks-cluster-01', 'Microsoft.ContainerService/managedClusters', 'Azure Kubernetes Service', 'Container Service', 280.20, 'USD', '2026-02-15', NOW(), NOW()),

-- Development environment costs
('sub-12345-dev', 'development-rg', 'dev-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 85.30, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-dev', 'development-rg', 'dev-vm-01', 'Microsoft.Compute/virtualMachines', 'Virtual Machines', 'Virtual Machines', 82.50, 'USD', '2026-02-15', NOW(), NOW()),
('sub-12345-dev', 'development-rg', 'dev-storage', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 12.50, 'USD', '2026-02-16', NOW(), NOW()),
('sub-12345-dev', 'development-rg', 'dev-storage', 'Microsoft.Storage/storageAccounts', 'Storage', 'Storage', 11.80, 'USD', '2026-02-15', NOW(), NOW());

-- ============================================
-- RECOMMENDATIONS - Cost optimization suggestions
-- ============================================

INSERT INTO recommendations (
    subscription_id, resource_group, resource_name, resource_type,
    title, description, category, impact,
    estimated_monthly_savings, estimated_annual_savings, currency, confidence_score,
    current_config, recommended_config,
    implementation_effort, implementation_steps, risk_level,
    status, source, valid_from, is_stale, created_at, updated_at
) VALUES
-- Recommendation 1: VM Rightsizing
('sub-12345-prod', 'production-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines',
 'Rightsize VM: Standard_D4s_v3 → Standard_D2s_v3',
 'This VM is consistently underutilized with average CPU usage of 15% and memory usage of 25% over the past 30 days. Downsizing to Standard_D2s_v3 will maintain performance while reducing costs by 50%.',
 'RIGHTSIZING', 'HIGH',
 75.25, 903.00, 'USD', 0.85,
 'Standard_D4s_v3 (4 vCPUs, 16 GB RAM)',
 'Standard_D2s_v3 (2 vCPUs, 8 GB RAM)',
 'medium', '1. Take VM snapshot for backup\n2. Stop VM during maintenance window\n3. Resize to Standard_D2s_v3\n4. Start VM and verify application performance\n5. Monitor for 48 hours',
 'low',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Recommendation 2: Reserved Instance
('sub-12345-prod', 'production-rg', 'db-sql-prod', 'Microsoft.Sql/servers/databases',
 'Purchase 1-Year Reserved Instance for SQL Database',
 'This SQL Database runs 24/7 with consistent usage. A 1-year reserved instance commitment would save 40% compared to pay-as-you-go pricing. Based on current usage of $320/day, estimated savings are significant.',
 'RESERVED_INSTANCES', 'HIGH',
 128.30, 1539.60, 'USD', 0.90,
 'Pay-as-you-go: $320/day average',
 '1-Year Reserved Instance: $192/day (40% savings)',
 'medium', '1. Review commitment terms\n2. Purchase reserved instance through Azure Portal\n3. Apply reservation to database\n4. Verify billing reflects discount\n5. Set calendar reminder for renewal',
 'low',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Recommendation 3: Storage Optimization
('sub-12345-prod', 'production-rg', 'storage-prod-01', 'Microsoft.Storage/storageAccounts',
 'Move Infrequently Accessed Data to Cool Tier',
 'Analysis shows 65% of blob storage (approximately 2.5 TB) has not been accessed in the last 90 days. Moving this data to Cool storage tier would reduce costs by 50% for storage, with minimal impact on access costs.',
 'STORAGE_OPTIMIZATION', 'MEDIUM',
 24.50, 294.00, 'USD', 0.75,
 'Hot tier: $0.0184/GB/month for 2.5 TB',
 'Cool tier: $0.0092/GB/month for 2.5 TB',
 'low', '1. Identify blobs not accessed in 90+ days\n2. Create lifecycle management policy\n3. Test policy on small subset\n4. Apply policy to move data to Cool tier\n5. Monitor access patterns',
 'low',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Recommendation 4: Idle Resource
('sub-12345-dev', 'development-rg', 'dev-vm-01', 'Microsoft.Compute/virtualMachines',
 'Deallocate or Delete Idle Development VM',
 'This development VM has been running continuously but shows no activity (0% CPU, no network traffic) for the past 14 days. Consider deallocating when not in use or deleting if no longer needed.',
 'IDLE_RESOURCES', 'MEDIUM',
 85.30, 1023.60, 'USD', 0.80,
 'Running 24/7: $85.30/day',
 'Deallocate when not in use: $0/day compute + minimal storage',
 'low', '1. Verify VM is not needed\n2. Contact development team for confirmation\n3. Take snapshot for backup\n4. Deallocate or delete VM\n5. Document decision',
 'low',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),

-- Recommendation 5: Savings Plan
('sub-12345-prod', 'production-rg', 'aks-cluster-01', 'Microsoft.ContainerService/managedClusters',
 'Apply Azure Savings Plan for Compute',
 'Your compute usage is consistent across multiple services. An Azure Savings Plan (1-year commitment) would provide 17% savings across VMs, App Services, and AKS. Based on current monthly compute spend of $1,850.',
 'SAVINGS_PLANS', 'HIGH',
 314.50, 3774.00, 'USD', 0.88,
 'Pay-as-you-go: $1,850/month average',
 'Savings Plan (1-year): $1,535.50/month (17% savings)',
 'medium', '1. Review compute usage patterns\n2. Calculate optimal commitment amount\n3. Purchase Savings Plan through Azure Portal\n4. Monitor utilization monthly\n5. Adjust commitment at renewal',
 'low',
 'NEW', 'cloudoptima', '2026-02-16', false, NOW(), NOW());

-- ============================================
-- BUDGETS - Sample budget configurations
-- ============================================

INSERT INTO budgets (
    name, description, subscription_id, resource_group,
    amount, currency, time_grain, alert_thresholds,
    current_spend, spend_percentage,
    start_date, end_date, is_active,
    created_at, updated_at
) VALUES
('Production Monthly Budget', 'Monthly budget for production resource group', 'sub-12345-prod', 'production-rg',
 5000.00, 'USD', 'MONTHLY', '50,80,100',
 3245.75, 64.92,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('Development Monthly Budget', 'Monthly budget for development environment', 'sub-12345-dev', 'development-rg',
 1000.00, 'USD', 'MONTHLY', '75,90,100',
 287.40, 28.74,
 '2026-02-01', '2026-02-28', true, NOW(), NOW()),

('Annual Infrastructure Budget', 'Annual budget for all infrastructure', 'sub-12345-prod', NULL,
 50000.00, 'USD', 'ANNUALLY', '50,75,90,100',
 8234.50, 16.47,
 '2026-01-01', '2026-12-31', true, NOW(), NOW());

-- ============================================
-- COST SUMMARIES - Aggregated data
-- ============================================

INSERT INTO cost_summaries (
    subscription_id, resource_group,
    period_start, period_end, granularity,
    total_cost, currency,
    cost_by_service, cost_by_resource_type,
    previous_period_cost, cost_change_percent,
    created_at
) VALUES
('sub-12345-prod', 'production-rg',
 '2026-02-16', '2026-02-16', 'daily',
 1032.25, 'USD',
 '{"Virtual Machines": 247.80, "SQL Database": 325.75, "Storage": 48.20, "App Service": 125.00, "Azure Kubernetes Service": 285.50}',
 '{"Microsoft.Compute/virtualMachines": 247.80, "Microsoft.Sql/servers/databases": 325.75, "Microsoft.Storage/storageAccounts": 48.20}',
 998.40, 3.39,
 NOW());

-- Verify data was inserted
SELECT 'Cost Records Inserted: ' || COUNT(*) FROM cost_records;
SELECT 'Recommendations Inserted: ' || COUNT(*) FROM recommendations;
SELECT 'Budgets Inserted: ' || COUNT(*) FROM budgets;
SELECT 'Cost Summaries Inserted: ' || COUNT(*) FROM cost_summaries;

-- Show summary
SELECT 
    service_name,
    COUNT(*) as record_count,
    ROUND(SUM(cost)::numeric, 2) as total_cost
FROM cost_records 
GROUP BY service_name 
ORDER BY total_cost DESC;
