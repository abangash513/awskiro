-- CloudOptima AI - Complete Database Schema
-- PostgreSQL 15+ with TimescaleDB extension
-- Version: 1.0.0
-- Created: 2026-02-13

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "timescaledb";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    subscription_tier VARCHAR(50) NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'business', 'enterprise')),
    settings JSONB DEFAULT '{}',
    max_subscriptions INT DEFAULT 1,
    max_resources INT DEFAULT 100,
    features JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_settings CHECK (jsonb_typeof(settings) = 'object')
);

CREATE INDEX idx_organizations_tier ON organizations(subscription_tier);
CREATE INDEX idx_organizations_created ON organizations(created_at DESC);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member', 'viewer', 'auditor')),
    avatar_url VARCHAR(500),
    preferences JSONB DEFAULT '{}',
    last_login TIMESTAMP WITH TIME ZONE,
    email_verified BOOLEAN DEFAULT FALSE,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_org ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- API Keys (for programmatic access)
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL UNIQUE,
    key_prefix VARCHAR(20) NOT NULL,
    permissions JSONB DEFAULT '[]',
    last_used TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_api_keys_user ON api_keys(user_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);

-- ============================================================================
-- CLOUD CONNECTIONS
-- ============================================================================

CREATE TABLE cloud_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    cloud_provider VARCHAR(50) NOT NULL CHECK (cloud_provider IN ('azure', 'aws', 'gcp')),
    connection_name VARCHAR(255) NOT NULL,
    credentials_encrypted TEXT NOT NULL,
    subscription_id VARCHAR(255),  -- Azure
    tenant_id VARCHAR(255),        -- Azure
    account_id VARCHAR(255),       -- AWS
    project_id VARCHAR(255),       -- GCP
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'error', 'disconnected', 'testing')),
    error_message TEXT,
    last_sync TIMESTAMP WITH TIME ZONE,
    sync_frequency_minutes INT DEFAULT 60,
    auto_sync BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, connection_name)
);

CREATE INDEX idx_connections_org ON cloud_connections(organization_id);
CREATE INDEX idx_connections_provider ON cloud_connections(cloud_provider);
CREATE INDEX idx_connections_status ON cloud_connections(status);

-- ============================================================================
-- RESOURCES
-- ============================================================================

CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    connection_id UUID NOT NULL REFERENCES cloud_connections(id) ON DELETE CASCADE,
    cloud_provider VARCHAR(50) NOT NULL,
    resource_type VARCHAR(255) NOT NULL,
    resource_id VARCHAR(500) NOT NULL,  -- Cloud provider's resource ID
    name VARCHAR(500),
    region VARCHAR(100),
    resource_group VARCHAR(255),
    subscription_id VARCHAR(255),
    tags JSONB DEFAULT '{}',
    properties JSONB DEFAULT '{}',
    cost_monthly DECIMAL(12,2),
    cost_daily DECIMAL(12,2),
    currency VARCHAR(10) DEFAULT 'USD',
    state VARCHAR(50),  -- running, stopped, deallocated, etc.
    discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(organization_id, resource_id)
);

CREATE INDEX idx_resources_org ON resources(organization_id);
CREATE INDEX idx_resources_connection ON resources(connection_id);
CREATE INDEX idx_resources_type ON resources(resource_type);
CREATE INDEX idx_resources_region ON resources(region);
CREATE INDEX idx_resources_tags ON resources USING GIN(tags);
CREATE INDEX idx_resources_properties ON resources USING GIN(properties);
CREATE INDEX idx_resources_cost ON resources(cost_monthly DESC NULLS LAST);
CREATE INDEX idx_resources_name_trgm ON resources USING GIN(name gin_trgm_ops);

-- Resource relationships (dependencies)
CREATE TABLE resource_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    child_resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    relationship_type VARCHAR(100) NOT NULL,  -- depends_on, attached_to, part_of, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parent_resource_id, child_resource_id, relationship_type)
);

CREATE INDEX idx_relationships_parent ON resource_relationships(parent_resource_id);
CREATE INDEX idx_relationships_child ON resource_relationships(child_resource_id);

-- ============================================================================
-- TIME-SERIES DATA (TimescaleDB Hypertables)
-- ============================================================================

-- Resource Metrics (CPU, Memory, Network, etc.)
CREATE TABLE resource_metrics (
    time TIMESTAMPTZ NOT NULL,
    resource_id UUID NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(50),
    aggregation VARCHAR(20) DEFAULT 'average',  -- average, min, max, sum
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE CASCADE
);

SELECT create_hypertable('resource_metrics', 'time');
CREATE INDEX idx_metrics_resource_time ON resource_metrics(resource_id, time DESC);
CREATE INDEX idx_metrics_name ON resource_metrics(metric_name, time DESC);

-- Retention policy: Keep metrics for 90 days
SELECT add_retention_policy('resource_metrics', INTERVAL '90 days');

-- Cost Data (Daily granularity)
CREATE TABLE cost_data (
    time TIMESTAMPTZ NOT NULL,
    organization_id UUID NOT NULL,
    connection_id UUID NOT NULL,
    resource_id UUID,
    service_name VARCHAR(255),
    service_category VARCHAR(100),
    meter_name VARCHAR(255),
    cost DECIMAL(12,4) NOT NULL,
    usage_quantity DECIMAL(20,4),
    usage_unit VARCHAR(50),
    currency VARCHAR(10) DEFAULT 'USD',
    tags JSONB DEFAULT '{}',
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (connection_id) REFERENCES cloud_connections(id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE SET NULL
);

SELECT create_hypertable('cost_data', 'time');
CREATE INDEX idx_cost_org_time ON cost_data(organization_id, time DESC);
CREATE INDEX idx_cost_connection_time ON cost_data(connection_id, time DESC);
CREATE INDEX idx_cost_resource_time ON cost_data(resource_id, time DESC) WHERE resource_id IS NOT NULL;
CREATE INDEX idx_cost_service ON cost_data(service_name, time DESC);
CREATE INDEX idx_cost_tags ON cost_data USING GIN(tags);

-- Retention policy: Keep cost data for 13 months
SELECT add_retention_policy('cost_data', INTERVAL '13 months');

-- Continuous aggregates for performance
CREATE MATERIALIZED VIEW daily_cost_summary
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    organization_id,
    connection_id,
    service_name,
    SUM(cost) as total_cost,
    SUM(usage_quantity) as total_usage,
    COUNT(DISTINCT resource_id) as resource_count,
    currency
FROM cost_data
GROUP BY day, organization_id, connection_id, service_name, currency;

SELECT add_continuous_aggregate_policy('daily_cost_summary',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

CREATE MATERIALIZED VIEW monthly_cost_summary
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 month', time) AS month,
    organization_id,
    connection_id,
    service_name,
    SUM(cost) as total_cost,
    AVG(cost) as avg_daily_cost,
    COUNT(DISTINCT resource_id) as resource_count,
    currency
FROM cost_data
GROUP BY month, organization_id, connection_id, service_name, currency;

SELECT add_continuous_aggregate_policy('monthly_cost_summary',
    start_offset => INTERVAL '1 month',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day');

-- ============================================================================
-- RECOMMENDATIONS
-- ============================================================================

CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,  -- cost, security, reliability, performance, operations
    title VARCHAR(500) NOT NULL,
    description TEXT,
    impact VARCHAR(20) NOT NULL CHECK (impact IN ('critical', 'high', 'medium', 'low')),
    effort VARCHAR(20) NOT NULL CHECK (effort IN ('easy', 'medium', 'hard')),
    monthly_savings DECIMAL(12,2),
    annual_savings DECIMAL(12,2),
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high')),
    confidence_score DECIMAL(3,2) CHECK (confidence_score BETWEEN 0 AND 1),
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'implemented', 'dismissed', 'expired')),
    priority_score INT,
    metadata JSONB DEFAULT '{}',
    remediation_steps JSONB DEFAULT '[]',
    auto_remediable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    implemented_at TIMESTAMP WITH TIME ZONE,
    dismissed_at TIMESTAMP WITH TIME ZONE,
    dismissed_reason TEXT
);

CREATE INDEX idx_recommendations_org ON recommendations(organization_id);
CREATE INDEX idx_recommendations_resource ON recommendations(resource_id);
CREATE INDEX idx_recommendations_status ON recommendations(status);
CREATE INDEX idx_recommendations_category ON recommendations(category);
CREATE INDEX idx_recommendations_savings ON recommendations(annual_savings DESC NULLS LAST);
CREATE INDEX idx_recommendations_priority ON recommendations(priority_score DESC NULLS LAST);
CREATE INDEX idx_recommendations_created ON recommendations(created_at DESC);

-- Recommendation feedback (for ML training)
CREATE TABLE recommendation_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_id UUID NOT NULL REFERENCES recommendations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feedback_type VARCHAR(50) NOT NULL CHECK (feedback_type IN ('helpful', 'not_helpful', 'implemented', 'not_applicable')),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_feedback_recommendation ON recommendation_feedback(recommendation_id);
CREATE INDEX idx_feedback_user ON recommendation_feedback(user_id);

-- ============================================================================
-- POLICIES & COMPLIANCE
-- ============================================================================

CREATE TABLE policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    policy_yaml TEXT NOT NULL,
    category VARCHAR(100),
    severity VARCHAR(20) CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')),
    enabled BOOLEAN DEFAULT TRUE,
    auto_remediate BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, name)
);

CREATE INDEX idx_policies_org ON policies(organization_id);
CREATE INDEX idx_policies_enabled ON policies(enabled);
CREATE INDEX idx_policies_category ON policies(category);

CREATE TABLE policy_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'ignored', 'false_positive')),
    details JSONB DEFAULT '{}',
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT
);

CREATE INDEX idx_violations_org ON policy_violations(organization_id);
CREATE INDEX idx_violations_policy ON policy_violations(policy_id);
CREATE INDEX idx_violations_resource ON policy_violations(resource_id);
CREATE INDEX idx_violations_status ON policy_violations(status);
CREATE INDEX idx_violations_severity ON policy_violations(severity);
CREATE INDEX idx_violations_detected ON policy_violations(detected_at DESC);

-- ============================================================================
-- REMEDIATION
-- ============================================================================

CREATE TABLE remediation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_id UUID REFERENCES recommendations(id) ON DELETE CASCADE,
    policy_violation_id UUID REFERENCES policy_violations(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL,
    parameters JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'executing', 'completed', 'failed', 'rolled_back')),
    approval_required BOOLEAN DEFAULT TRUE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    executed_by UUID REFERENCES users(id),
    executed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    result JSONB DEFAULT '{}',
    error_message TEXT,
    rollback_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_recommendation_or_violation CHECK (
        (recommendation_id IS NOT NULL AND policy_violation_id IS NULL) OR
        (recommendation_id IS NULL AND policy_violation_id IS NOT NULL)
    )
);

CREATE INDEX idx_remediation_recommendation ON remediation_actions(recommendation_id);
CREATE INDEX idx_remediation_violation ON remediation_actions(policy_violation_id);
CREATE INDEX idx_remediation_status ON remediation_actions(status);
CREATE INDEX idx_remediation_executed ON remediation_actions(executed_at DESC);

-- ============================================================================
-- AI & ANALYTICS
-- ============================================================================

CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500),
    context JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_conversations_org ON ai_conversations(organization_id);
CREATE INDEX idx_conversations_user ON ai_conversations(user_id);
CREATE INDEX idx_conversations_updated ON ai_conversations(updated_at DESC);

CREATE TABLE ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    tokens_used INT,
    model_used VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON ai_messages(conversation_id, created_at);

-- ML Models metadata
CREATE TABLE ml_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_type VARCHAR(100) NOT NULL,  -- forecasting, anomaly_detection, recommendation
    model_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    parameters JSONB DEFAULT '{}',
    metrics JSONB DEFAULT '{}',  -- accuracy, precision, recall, etc.
    training_data_period INTERVAL,
    trained_at TIMESTAMP WITH TIME ZONE,
    deployed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'training' CHECK (status IN ('training', 'deployed', 'deprecated')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(model_type, version)
);

CREATE INDEX idx_models_type ON ml_models(model_type);
CREATE INDEX idx_models_status ON ml_models(status);

-- Forecasts
CREATE TABLE cost_forecasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    connection_id UUID REFERENCES cloud_connections(id) ON DELETE CASCADE,
    forecast_date DATE NOT NULL,
    predicted_cost DECIMAL(12,2) NOT NULL,
    lower_bound DECIMAL(12,2),
    upper_bound DECIMAL(12,2),
    confidence_interval DECIMAL(3,2),
    model_id UUID REFERENCES ml_models(id),
    actual_cost DECIMAL(12,2),  -- Filled in after the date passes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, connection_id, forecast_date)
);

CREATE INDEX idx_forecasts_org_date ON cost_forecasts(organization_id, forecast_date);
CREATE INDEX idx_forecasts_connection ON cost_forecasts(connection_id, forecast_date);

-- Anomalies
CREATE TABLE cost_anomalies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    connection_id UUID REFERENCES cloud_connections(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES resources(id) ON DELETE SET NULL,
    anomaly_date DATE NOT NULL,
    actual_cost DECIMAL(12,2) NOT NULL,
    expected_cost DECIMAL(12,2) NOT NULL,
    deviation_percent DECIMAL(5,2) NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    confidence_score DECIMAL(3,2),
    root_cause TEXT,
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'false_positive')),
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_anomalies_org_date ON cost_anomalies(organization_id, anomaly_date DESC);
CREATE INDEX idx_anomalies_status ON cost_anomalies(status);
CREATE INDEX idx_anomalies_severity ON cost_anomalies(severity);

-- ============================================================================
-- REPORTS
-- ============================================================================

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    report_type VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    format VARCHAR(20) NOT NULL CHECK (format IN ('pdf', 'html', 'excel', 'json')),
    file_path VARCHAR(1000),
    file_size_bytes BIGINT,
    parameters JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'generating' CHECK (status IN ('generating', 'completed', 'failed')),
    error_message TEXT,
    generated_by UUID REFERENCES users(id),
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    download_count INT DEFAULT 0,
    last_downloaded_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_reports_org ON reports(organization_id);
CREATE INDEX idx_reports_type ON reports(report_type);
CREATE INDEX idx_reports_generated ON reports(generated_at DESC);
CREATE INDEX idx_reports_status ON reports(status);

-- ============================================================================
-- BUDGETS & ALERTS
-- ============================================================================

CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    connection_id UUID REFERENCES cloud_connections(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    period VARCHAR(20) NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    filters JSONB DEFAULT '{}',  -- Filter by tags, resource groups, etc.
    alert_thresholds JSONB DEFAULT '[]',  -- [50, 80, 100, 120]
    enabled BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_budgets_org ON budgets(organization_id);
CREATE INDEX idx_budgets_connection ON budgets(connection_id);
CREATE INDEX idx_budgets_enabled ON budgets(enabled);

CREATE TABLE budget_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    alert_date DATE NOT NULL,
    threshold_percent INT NOT NULL,
    actual_spend DECIMAL(12,2) NOT NULL,
    budget_amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'triggered' CHECK (status IN ('triggered', 'acknowledged', 'resolved')),
    notified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_budget_alerts_budget ON budget_alerts(budget_id);
CREATE INDEX idx_budget_alerts_date ON budget_alerts(alert_date DESC);
CREATE INDEX idx_budget_alerts_status ON budget_alerts(status);

-- ============================================================================
-- NOTIFICATIONS & INTEGRATIONS
-- ============================================================================

CREATE TABLE notification_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    channel_type VARCHAR(50) NOT NULL CHECK (channel_type IN ('email', 'slack', 'teams', 'webhook', 'sms', 'pagerduty')),
    name VARCHAR(255) NOT NULL,
    configuration JSONB NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, name)
);

CREATE INDEX idx_channels_org ON notification_channels(organization_id);
CREATE INDEX idx_channels_type ON notification_channels(channel_type);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('critical', 'high', 'medium', 'low', 'info')),
    related_resource_id UUID REFERENCES resources(id) ON DELETE SET NULL,
    related_recommendation_id UUID REFERENCES recommendations(id) ON DELETE SET NULL,
    metadata JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_org ON notifications(organization_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- ============================================================================
-- AUDIT LOG
-- ============================================================================

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(500),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    status VARCHAR(20) CHECK (status IN ('success', 'failure')),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_org_time ON audit_log(organization_id, created_at DESC);
CREATE INDEX idx_audit_user ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_resource ON audit_log(resource_type, resource_id);

-- Partition audit_log by month for better performance
-- (Requires manual partitioning setup or pg_partman extension)

-- ============================================================================
-- CARBON & SUSTAINABILITY
-- ============================================================================

CREATE TABLE carbon_emissions (
    time TIMESTAMPTZ NOT NULL,
    organization_id UUID NOT NULL,
    connection_id UUID NOT NULL,
    resource_id UUID,
    region VARCHAR(100),
    carbon_kg DECIMAL(12,4) NOT NULL,
    renewable_energy_percent DECIMAL(5,2),
    calculation_method VARCHAR(100),
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (connection_id) REFERENCES cloud_connections(id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE SET NULL
);

SELECT create_hypertable('carbon_emissions', 'time');
CREATE INDEX idx_carbon_org_time ON carbon_emissions(organization_id, time DESC);
CREATE INDEX idx_carbon_resource ON carbon_emissions(resource_id, time DESC);

-- ============================================================================
-- SAVED QUERIES & DASHBOARDS
-- ============================================================================

CREATE TABLE saved_queries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    query_type VARCHAR(50) NOT NULL,
    query_parameters JSONB NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_saved_queries_org ON saved_queries(organization_id);
CREATE INDEX idx_saved_queries_user ON saved_queries(user_id);

CREATE TABLE custom_dashboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    layout JSONB NOT NULL,
    widgets JSONB NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_dashboards_org ON custom_dashboards(organization_id);
CREATE INDEX idx_dashboards_user ON custom_dashboards(user_id);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_connections_updated_at BEFORE UPDATE ON cloud_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resources_updated_at BEFORE UPDATE ON resources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recommendations_updated_at BEFORE UPDATE ON recommendations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_policies_updated_at BEFORE UPDATE ON policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Calculate recommendation priority score
CREATE OR REPLACE FUNCTION calculate_recommendation_priority(
    p_impact VARCHAR,
    p_effort VARCHAR,
    p_savings DECIMAL,
    p_risk VARCHAR
) RETURNS INT AS $$
DECLARE
    impact_score INT;
    effort_score INT;
    risk_score INT;
    savings_score INT;
BEGIN
    -- Impact score (0-40 points)
    impact_score := CASE p_impact
        WHEN 'critical' THEN 40
        WHEN 'high' THEN 30
        WHEN 'medium' THEN 20
        WHEN 'low' THEN 10
        ELSE 0
    END;
    
    -- Effort score (0-20 points, inverse - easier is better)
    effort_score := CASE p_effort
        WHEN 'easy' THEN 20
        WHEN 'medium' THEN 10
        WHEN 'hard' THEN 5
        ELSE 0
    END;
    
    -- Risk score (0-20 points, inverse - lower risk is better)
    risk_score := CASE p_risk
        WHEN 'low' THEN 20
        WHEN 'medium' THEN 10
        WHEN 'high' THEN 5
        ELSE 15
    END;
    
    -- Savings score (0-20 points)
    savings_score := CASE
        WHEN p_savings >= 1000 THEN 20
        WHEN p_savings >= 500 THEN 15
        WHEN p_savings >= 100 THEN 10
        WHEN p_savings >= 50 THEN 5
        ELSE 0
    END;
    
    RETURN impact_score + effort_score + risk_score + savings_score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger to auto-calculate priority score
CREATE OR REPLACE FUNCTION set_recommendation_priority()
RETURNS TRIGGER AS $$
BEGIN
    NEW.priority_score := calculate_recommendation_priority(
        NEW.impact,
        NEW.effort,
        COALESCE(NEW.monthly_savings, 0),
        NEW.risk_level
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_priority BEFORE INSERT OR UPDATE ON recommendations
    FOR EACH ROW EXECUTE FUNCTION set_recommendation_priority();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Active recommendations with resource details
CREATE VIEW v_active_recommendations AS
SELECT
    r.id,
    r.organization_id,
    r.type,
    r.category,
    r.title,
    r.impact,
    r.effort,
    r.monthly_savings,
    r.annual_savings,
    r.priority_score,
    r.status,
    r.created_at,
    res.name as resource_name,
    res.resource_type,
    res.region,
    res.tags
FROM recommendations r
LEFT JOIN resources res ON r.resource_id = res.id
WHERE r.status IN ('open', 'in_progress')
    AND (r.expires_at IS NULL OR r.expires_at > NOW());

-- Monthly cost summary by service
CREATE VIEW v_monthly_costs_by_service AS
SELECT
    organization_id,
    connection_id,
    DATE_TRUNC('month', time) as month,
    service_name,
    SUM(cost) as total_cost,
    COUNT(DISTINCT resource_id) as resource_count,
    currency
FROM cost_data
WHERE time >= NOW() - INTERVAL '13 months'
GROUP BY organization_id, connection_id, DATE_TRUNC('month', time), service_name, currency;

-- Top cost resources
CREATE VIEW v_top_cost_resources AS
SELECT
    r.organization_id,
    r.id,
    r.name,
    r.resource_type,
    r.region,
    r.cost_monthly,
    r.tags,
    RANK() OVER (PARTITION BY r.organization_id ORDER BY r.cost_monthly DESC) as cost_rank
FROM resources r
WHERE r.deleted_at IS NULL
    AND r.cost_monthly IS NOT NULL;

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert default ML models
INSERT INTO ml_models (model_type, model_name, version, status) VALUES
('forecasting', 'Prophet + XGBoost Ensemble', '1.0.0', 'deployed'),
('anomaly_detection', 'Isolation Forest', '1.0.0', 'deployed'),
('recommendation', 'Rule-based Engine', '1.0.0', 'deployed');

-- ============================================================================
-- GRANTS (Adjust based on your security requirements)
-- ============================================================================

-- Create read-only role for reporting
CREATE ROLE cloudoptima_readonly;
GRANT CONNECT ON DATABASE cloudoptima TO cloudoptima_readonly;
GRANT USAGE ON SCHEMA public TO cloudoptima_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cloudoptima_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO cloudoptima_readonly;

-- Create application role
CREATE ROLE cloudoptima_app;
GRANT CONNECT ON DATABASE cloudoptima TO cloudoptima_app;
GRANT USAGE ON SCHEMA public TO cloudoptima_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cloudoptima_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO cloudoptima_app;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE organizations IS 'Multi-tenant organizations using the platform';
COMMENT ON TABLE resources IS 'Cloud resources discovered from connected accounts';
COMMENT ON TABLE resource_metrics IS 'Time-series performance metrics for resources';
COMMENT ON TABLE cost_data IS 'Time-series cost data from cloud providers';
COMMENT ON TABLE recommendations IS 'Optimization recommendations generated by analysis engine';
COMMENT ON TABLE policies IS 'Governance policies defined by organizations';
COMMENT ON TABLE remediation_actions IS 'Actions taken to remediate issues';
COMMENT ON TABLE ai_conversations IS 'Natural language conversations with AI assistant';
COMMENT ON TABLE audit_log IS 'Immutable audit trail of all system actions';

-- End of schema
