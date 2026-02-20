#!/bin/bash
# Generate monthly productivity review

MONTH=$(date +%m)
YEAR=$(date +%Y)
MONTH_NAME=$(date +%B)
REPORT_DIR="$HOME/clawd/02-Analysis-Reports"
PRODUCTIVITY_DIR="$HOME/.clawdbot/productivity"
REPORT_FILE="$REPORT_DIR/Monthly-Review-$YEAR-$MONTH.md"

mkdir -p "$REPORT_DIR"

# Send request to Clawbot to generate review
clawdbot agent --session-id "monthly-review-$YEAR-$MONTH" --message "Generate a monthly productivity review for $MONTH_NAME $YEAR. Review all daily logs and weekly summaries from $PRODUCTIVITY_DIR for this month. Create a comprehensive review at $REPORT_FILE. Include: monthly achievements, cost optimization impact, infrastructure changes, automation added, skills developed, time analysis, ROI analysis, and next month's goals. Send the review to me via WhatsApp when done."

echo "Monthly review generation requested!"
echo "Report will be saved to: $REPORT_FILE"
