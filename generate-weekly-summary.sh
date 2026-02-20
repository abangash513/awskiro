#!/bin/bash
# Generate weekly productivity summary

WEEK_NUM=$(date +%V)
YEAR=$(date +%Y)
REPORT_DIR="$HOME/clawd/02-Analysis-Reports"
PRODUCTIVITY_DIR="$HOME/.clawdbot/productivity"
REPORT_FILE="$REPORT_DIR/Weekly-Summary-$YEAR-W$WEEK_NUM.md"

mkdir -p "$REPORT_DIR"

# Get this week's logs
WEEK_START=$(date -d "monday this week" +%Y-%m-%d)
WEEK_END=$(date -d "sunday this week" +%Y-%m-%d)

# Send request to Clawbot to generate summary
clawdbot agent --session-id "weekly-summary-$YEAR-W$WEEK_NUM" --message "Generate a weekly productivity summary for week $WEEK_NUM ($WEEK_START to $WEEK_END). Review all daily logs in $PRODUCTIVITY_DIR from this week and create a comprehensive summary at $REPORT_FILE. Include: major accomplishments, time breakdown, cost savings, scripts created, technical debt, and next week's goals. Send the summary to me via WhatsApp when done."

echo "Weekly summary generation requested!"
echo "Report will be saved to: $REPORT_FILE"
