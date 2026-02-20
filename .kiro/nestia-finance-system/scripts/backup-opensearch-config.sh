#!/bin/bash
# OpenSearch Configuration Backup Script
# Purpose: Export all domain configurations to JSON files
# Usage: ./backup-opensearch-config.sh [region]

set -e

REGION=${1:-us-east-1}
BACKUP_DIR="opensearch-backups/$(date +%Y%m%d_%H%M%S)"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "========================================="
echo "OpenSearch Configuration Backup"
echo "========================================="
echo "Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo "Backup Directory: $BACKUP_DIR"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Get list of all OpenSearch domains
echo "Discovering OpenSearch domains..."
DOMAINS=$(aws opensearch list-domain-names --region $REGION --query 'DomainNames[*].DomainName' --output text)

if [ -z "$DOMAINS" ]; then
    echo "No OpenSearch domains found in region $REGION"
    exit 0
fi

echo "Found domains: $DOMAINS"
echo ""

# Backup each domain configuration
for DOMAIN in $DOMAINS; do
    echo "Backing up domain: $DOMAIN"
    
    # Get domain configuration
    aws opensearch describe-domain \
        --domain-name "$DOMAIN" \
        --region $REGION \
        --output json > "$BACKUP_DIR/${DOMAIN}_config.json"
    
    # Get domain tags
    DOMAIN_ARN=$(aws opensearch describe-domain \
        --domain-name "$DOMAIN" \
        --region $REGION \
        --query 'DomainStatus.ARN' \
        --output text)
    
    aws opensearch list-tags \
        --arn "$DOMAIN_ARN" \
        --region $REGION \
        --output json > "$BACKUP_DIR/${DOMAIN}_tags.json"
    
    # Create snapshot (if automated snapshots enabled)
    echo "  - Configuration saved"
    echo "  - Tags saved"
    
    # Get cluster stats
    ENDPOINT=$(aws opensearch describe-domain \
        --domain-name "$DOMAIN" \
        --region $REGION \
        --query 'DomainStatus.Endpoint' \
        --output text)
    
    if [ ! -z "$ENDPOINT" ]; then
        echo "  - Endpoint: $ENDPOINT"
        # Note: Actual cluster stats require authentication
        # curl -X GET "https://$ENDPOINT/_cluster/stats" > "$BACKUP_DIR/${DOMAIN}_cluster_stats.json"
    fi
    
    echo "  ✓ Backup complete"
    echo ""
done

# Create summary report
cat > "$BACKUP_DIR/backup_summary.txt" << EOF
OpenSearch Configuration Backup Summary
========================================
Date: $(date)
Account: $ACCOUNT_ID
Region: $REGION
Domains Backed Up: $(echo $DOMAINS | wc -w)

Domains:
$(echo "$DOMAINS" | tr ' ' '\n' | sed 's/^/  - /')

Files Created:
$(ls -lh "$BACKUP_DIR" | tail -n +2)
EOF

echo "========================================="
echo "Backup Complete!"
echo "========================================="
echo "Location: $BACKUP_DIR"
echo "Files: $(ls "$BACKUP_DIR" | wc -l)"
echo ""
echo "To restore a domain configuration, use:"
echo "  aws opensearch create-domain --cli-input-json file://$BACKUP_DIR/<domain>_config.json"
echo ""
