#!/bin/bash
# OpenSearch Cost Tracking Script
# Purpose: Track daily OpenSearch costs and compare to baseline
# Usage: ./track-opensearch-costs.sh [days_back]

set -e

DAYS_BACK=${1:-7}
REGION=${AWS_REGION:-us-east-1}
OUTPUT_FILE="opensearch-costs-$(date +%Y%m%d).csv"

echo "========================================="
echo "OpenSearch Cost Tracking"
echo "========================================="
echo "Period: Last $DAYS_BACK days"
echo "Region: $REGION"
echo ""

# Calculate date range
START_DATE=$(date -d "$DAYS_BACK days ago" +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

echo "Fetching cost data from $START_DATE to $END_DATE..."
echo ""

# Get OpenSearch costs using Cost Explorer
aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity DAILY \
    --metrics "UnblendedCost" \
    --filter file://<(cat <<EOF
{
    "Dimensions": {
        "Key": "SERVICE",
        "Values": ["Amazon OpenSearch Service"]
    }
}
EOF
) \
    --group-by Type=DIMENSION,Key=USAGE_TYPE \
    --output json > /tmp/opensearch_costs.json

# Parse and display results
echo "Date,Service,Usage Type,Cost (USD)" > "$OUTPUT_FILE"

jq -r '.ResultsByTime[] | 
    .TimePeriod.Start as $date | 
    .Groups[] | 
    [$date, "OpenSearch", .Keys[0], .Metrics.UnblendedCost.Amount] | 
    @csv' /tmp/opensearch_costs.json >> "$OUTPUT_FILE"

# Calculate totals
TOTAL_COST=$(jq -r '[.ResultsByTime[].Groups[].Metrics.UnblendedCost.Amount | tonumber] | add' /tmp/opensearch_costs.json)
DAILY_AVG=$(echo "scale=2; $TOTAL_COST / $DAYS_BACK" | bc)
MONTHLY_PROJECTION=$(echo "scale=2; $DAILY_AVG * 30" | bc)

echo "========================================="
echo "Cost Summary"
echo "========================================="
echo "Total Cost ($DAYS_BACK days): \$$TOTAL_COST"
echo "Daily Average: \$$DAILY_AVG"
echo "Monthly Projection: \$$MONTHLY_PROJECTION"
echo ""

# Compare to baseline (if exists)
BASELINE_FILE="baseline-monthly-cost.txt"
if [ -f "$BASELINE_FILE" ]; then
    BASELINE=$(cat "$BASELINE_FILE")
    SAVINGS=$(echo "scale=2; $BASELINE - $MONTHLY_PROJECTION" | bc)
    SAVINGS_PCT=$(echo "scale=1; ($SAVINGS / $BASELINE) * 100" | bc)
    
    echo "Baseline Monthly Cost: \$$BASELINE"
    echo "Current Projection: \$$MONTHLY_PROJECTION"
    echo "Savings: \$$SAVINGS ($SAVINGS_PCT%)"
    echo ""
    
    if (( $(echo "$SAVINGS > 0" | bc -l) )); then
        echo "✓ On track for savings target!"
    else
        echo "⚠ Cost higher than baseline"
    fi
else
    echo "No baseline found. Creating baseline..."
    echo "$MONTHLY_PROJECTION" > "$BASELINE_FILE"
    echo "Baseline set to: \$$MONTHLY_PROJECTION"
fi

echo ""
echo "Detailed report saved to: $OUTPUT_FILE"
echo ""

# Display top cost drivers
echo "========================================="
echo "Top Cost Drivers"
echo "========================================="
jq -r '.ResultsByTime[].Groups[] | 
    [.Keys[0], .Metrics.UnblendedCost.Amount] | 
    @tsv' /tmp/opensearch_costs.json | \
    awk '{cost[$1]+=$2} END {for (i in cost) print cost[i], i}' | \
    sort -rn | \
    head -10 | \
    awk '{printf "%-50s $%.2f\n", $2, $1}'

echo ""

# Cleanup
rm /tmp/opensearch_costs.json
