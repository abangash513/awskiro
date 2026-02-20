#!/bin/bash
# Setup automated productivity tracking with cron

echo "Setting up Clawbot productivity automation..."

# Create cron jobs
(crontab -l 2>/dev/null; echo "# Clawbot Productivity Automation") | crontab -

# Daily session initialization (9 AM on weekdays)
(crontab -l 2>/dev/null; echo "0 9 * * 1-5 $HOME/init-clawbot-session.sh") | crontab -

# Daily end-of-day summary (6 PM on weekdays)
(crontab -l 2>/dev/null; echo "0 18 * * 1-5 clawdbot agent --session-id daily-\$(date +\%Y-\%m-\%d) --message 'End of day. Summarize today\\'s accomplishments and send via WhatsApp.'") | crontab -

# Weekly summary (Friday at 5 PM)
(crontab -l 2>/dev/null; echo "0 17 * * 5 $HOME/generate-weekly-summary.sh") | crontab -

# Monthly review (Last day of month at 5 PM)
(crontab -l 2>/dev/null; echo "0 17 28-31 * * [ \$(date -d tomorrow +\%d) -eq 1 ] && $HOME/generate-monthly-review.sh") | crontab -

echo "✅ Automation setup complete!"
echo ""
echo "Scheduled tasks:"
echo "  - Daily session start: 9 AM (Mon-Fri)"
echo "  - Daily summary: 6 PM (Mon-Fri)"
echo "  - Weekly summary: Friday 5 PM"
echo "  - Monthly review: Last day of month 5 PM"
echo ""
echo "View cron jobs: crontab -l"
echo "Edit cron jobs: crontab -e"
