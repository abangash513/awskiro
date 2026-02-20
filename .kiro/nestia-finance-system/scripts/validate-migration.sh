#!/bin/bash
# OpenSearch Migration Validation Script
# Purpose: Validate domain health after migration/changes
# Usage: ./validate-migration.sh <domain-name> [region]

set -e

DOMAIN_NAME=$1
REGION=${2:-us-east-1}

if [ -z "$DOMAIN_NAME" ]; then
    echo "Usage: $0 <domain-name> [region]"
    exit 1
fi

echo "========================================="
echo "OpenSearch Migration Validation"
echo "========================================="
echo "Domain: $DOMAIN_NAME"
echo "Region: $REGION"
echo "Timestamp: $(date)"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Function to print test result
print_result() {
    local test_name=$1
    local status=$2
    local message=$3
    
    if [ "$status" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name: PASS"
        ((PASSED++))
    elif [ "$status" == "FAIL" ]; then
        echo -e "${RED}✗${NC} $test_name: FAIL - $message"
        ((FAILED++))
    else
        echo -e "${YELLOW}⚠${NC} $test_name: WARNING - $message"
        ((WARNINGS++))
    fi
}

echo "Running validation checks..."
echo ""

# Test 1: Domain exists and is accessible
echo "1. Checking domain existence..."
if aws opensearch describe-domain --domain-name "$DOMAIN_NAME" --region $REGION &>/dev/null; then
    print_result "Domain Exists" "PASS"
else
    print_result "Domain Exists" "FAIL" "Domain not found or not accessible"
    exit 1
fi

# Test 2: Domain is active
echo "2. Checking domain status..."
DOMAIN_STATUS=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.Processing' \
    --output text)

if [ "$DOMAIN_STATUS" == "False" ]; then
    print_result "Domain Active" "PASS"
else
    print_result "Domain Active" "WARN" "Domain is currently processing changes"
fi

# Test 3: Cluster health
echo "3. Checking cluster health..."
ENDPOINT=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.Endpoint' \
    --output text)

if [ ! -z "$ENDPOINT" ] && [ "$ENDPOINT" != "None" ]; then
    print_result "Endpoint Available" "PASS"
    echo "   Endpoint: $ENDPOINT"
    
    # Try to get cluster health (requires authentication)
    # Note: This requires proper credentials/signing
    # CLUSTER_HEALTH=$(curl -s "https://$ENDPOINT/_cluster/health" | jq -r '.status')
    # if [ "$CLUSTER_HEALTH" == "green" ]; then
    #     print_result "Cluster Health" "PASS"
    # elif [ "$CLUSTER_HEALTH" == "yellow" ]; then
    #     print_result "Cluster Health" "WARN" "Cluster status is yellow"
    # else
    #     print_result "Cluster Health" "FAIL" "Cluster status is red"
    # fi
else
    print_result "Endpoint Available" "FAIL" "No endpoint found"
fi

# Test 4: Node configuration
echo "4. Checking node configuration..."
INSTANCE_COUNT=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.ClusterConfig.InstanceCount' \
    --output text)

INSTANCE_TYPE=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.ClusterConfig.InstanceType' \
    --output text)

if [ "$INSTANCE_COUNT" -ge 1 ]; then
    print_result "Node Count" "PASS"
    echo "   Instances: $INSTANCE_COUNT x $INSTANCE_TYPE"
else
    print_result "Node Count" "FAIL" "No instances found"
fi

# Test 5: Storage configuration
echo "5. Checking storage configuration..."
EBS_ENABLED=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.EBSOptions.EBSEnabled' \
    --output text)

if [ "$EBS_ENABLED" == "True" ]; then
    VOLUME_TYPE=$(aws opensearch describe-domain \
        --domain-name "$DOMAIN_NAME" \
        --region $REGION \
        --query 'DomainStatus.EBSOptions.VolumeType' \
        --output text)
    
    VOLUME_SIZE=$(aws opensearch describe-domain \
        --domain-name "$DOMAIN_NAME" \
        --region $REGION \
        --query 'DomainStatus.EBSOptions.VolumeSize' \
        --output text)
    
    print_result "EBS Storage" "PASS"
    echo "   Type: $VOLUME_TYPE, Size: ${VOLUME_SIZE}GB"
    
    # Check if using gp3 (recommended)
    if [ "$VOLUME_TYPE" == "gp3" ]; then
        print_result "Storage Type" "PASS"
    else
        print_result "Storage Type" "WARN" "Consider migrating to gp3"
    fi
else
    print_result "EBS Storage" "FAIL" "EBS not enabled"
fi

# Test 6: Encryption
echo "6. Checking encryption settings..."
ENCRYPTION_AT_REST=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.EncryptionAtRestOptions.Enabled' \
    --output text)

NODE_TO_NODE=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.NodeToNodeEncryptionOptions.Enabled' \
    --output text)

ENFORCE_HTTPS=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.DomainEndpointOptions.EnforceHTTPS' \
    --output text)

if [ "$ENCRYPTION_AT_REST" == "True" ]; then
    print_result "Encryption at Rest" "PASS"
else
    print_result "Encryption at Rest" "WARN" "Not enabled - security risk"
fi

if [ "$NODE_TO_NODE" == "True" ]; then
    print_result "Node-to-Node Encryption" "PASS"
else
    print_result "Node-to-Node Encryption" "WARN" "Not enabled - security risk"
fi

if [ "$ENFORCE_HTTPS" == "True" ]; then
    print_result "HTTPS Enforcement" "PASS"
else
    print_result "HTTPS Enforcement" "WARN" "Not enabled - security risk"
fi

# Test 7: High Availability
echo "7. Checking high availability configuration..."
ZONE_AWARENESS=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.ClusterConfig.ZoneAwarenessEnabled' \
    --output text)

DEDICATED_MASTER=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.ClusterConfig.DedicatedMasterEnabled' \
    --output text)

if [ "$ZONE_AWARENESS" == "True" ]; then
    print_result "Multi-AZ" "PASS"
else
    print_result "Multi-AZ" "WARN" "Single-AZ deployment - consider Multi-AZ for production"
fi

if [ "$DEDICATED_MASTER" == "True" ]; then
    MASTER_COUNT=$(aws opensearch describe-domain \
        --domain-name "$DOMAIN_NAME" \
        --region $REGION \
        --query 'DomainStatus.ClusterConfig.DedicatedMasterCount' \
        --output text)
    print_result "Dedicated Masters" "PASS"
    echo "   Master Nodes: $MASTER_COUNT"
else
    print_result "Dedicated Masters" "WARN" "No dedicated master nodes"
fi

# Test 8: Auto-Tune
echo "8. Checking Auto-Tune configuration..."
AUTOTUNE_STATE=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.AutoTuneOptions.State' \
    --output text)

if [ "$AUTOTUNE_STATE" == "ENABLED" ]; then
    print_result "Auto-Tune" "PASS"
else
    print_result "Auto-Tune" "WARN" "Not enabled - consider enabling for performance optimization"
fi

# Test 9: Service Updates
echo "9. Checking for available service updates..."
UPDATE_AVAILABLE=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.ServiceSoftwareOptions.UpdateAvailable' \
    --output text)

if [ "$UPDATE_AVAILABLE" == "True" ]; then
    NEW_VERSION=$(aws opensearch describe-domain \
        --domain-name "$DOMAIN_NAME" \
        --region $REGION \
        --query 'DomainStatus.ServiceSoftwareOptions.NewVersion' \
        --output text)
    print_result "Service Updates" "WARN" "Update available: $NEW_VERSION"
else
    print_result "Service Updates" "PASS"
fi

# Test 10: Snapshots
echo "10. Checking snapshot configuration..."
SNAPSHOT_HOUR=$(aws opensearch describe-domain \
    --domain-name "$DOMAIN_NAME" \
    --region $REGION \
    --query 'DomainStatus.SnapshotOptions.AutomatedSnapshotStartHour' \
    --output text 2>/dev/null || echo "None")

if [ "$SNAPSHOT_HOUR" != "None" ] && [ ! -z "$SNAPSHOT_HOUR" ]; then
    print_result "Automated Snapshots" "PASS"
    echo "   Snapshot Hour: $SNAPSHOT_HOUR UTC"
else
    print_result "Automated Snapshots" "WARN" "Automated snapshots may not be configured"
fi

echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}⚠ VALIDATION FAILED${NC}"
    echo "Please review failed checks and take corrective action."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ VALIDATION PASSED WITH WARNINGS${NC}"
    echo "Domain is operational but has configuration warnings."
    exit 0
else
    echo -e "${GREEN}✓ VALIDATION PASSED${NC}"
    echo "Domain is healthy and properly configured."
    exit 0
fi
