#!/bin/bash
# Initialize Clawbot session with system instructions

SESSION_ID="daily-$(date +%Y-%m-%d)"
PRODUCTIVITY_DIR="$HOME/.clawdbot/productivity"
TODAY_LOG="$PRODUCTIVITY_DIR/$(date +%Y-%m-%d).md"

# Create productivity directory if it doesn't exist
mkdir -p "$PRODUCTIVITY_DIR"

# Create today's log if it doesn't exist
if [ ! -f "$TODAY_LOG" ]; then
    cat > "$TODAY_LOG" << EOF
# Productivity Log - $(date +%Y-%m-%d)

## Session Started: $(date +%H:%M:%S)

## Today's Goals
- [ ] 

## Tasks Completed
- 

## Time Breakdown
- Development: 
- Debugging: 
- Documentation: 
- Meetings: 

## Blockers Encountered
- 

## Decisions Made
- 

## Files Created/Modified
- 

## Cost Impact
- 

## Learning
- 

## Tomorrow's Priority
1. 
2. 
3. 

---
EOF
fi

# Send initialization message to Clawbot
clawdbot agent --session-id "$SESSION_ID" --message "Session initialized. Review system instructions in ~/clawd/memory/system-instructions.md and today's productivity log at $TODAY_LOG. Ask me what I'm working on today and help me plan my tasks."

echo "Clawbot session initialized!"
echo "Session ID: $SESSION_ID"
echo "Today's log: $TODAY_LOG"
