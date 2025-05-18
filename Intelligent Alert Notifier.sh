#!/bin/bash
#!/bin/bash

# intelligent_alert_notifier.sh
# Sends alerts for anomalies with colorful log

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/alert_notifier.log"
API_URL="https://example.com/alert" # Replace with real API
THRESHOLD=80 # % for CPU/Mem

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, alert notifier band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== Intelligent Alert Notifier ===${NC}"
    echo -e "${GREEN}Monitoring for anomalies${NC}\n"
}

# Display alerts
display_alerts() {
    display_header
    printf "${BLUE}%-15s %-20s %-20s${NC}\n" "Metric" "Value" "Timestamp"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------"
    tail -n 5 "$LOG_FILE" | while IFS='|' read -r metric value time; do
        printf "${YELLOW}%-15s %-20s %-20s${NC}\n" "$metric" "$value" "$time"
    done
}

# Send alert
send_alert() {
    local metric=$1 value=$2
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # API alert
    curl -s -X POST -d "metric=$metric&value=$value&time=$timestamp" "$API_URL" 2>/dev/null
    # Email alert (if mail installed)
    if command -v mail >/dev/null 2>&1; then
        echo "Alert: $metric at $value" | mail -s "System Alert" admin@example.com 2>/dev/null
    fi
    echo "$metric|$value|$timestamp" >> "$LOG_FILE"
    display_alerts
}

# Check anomalies
check_anomalies() {
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    mem=$(free | grep Mem | awk '{print ($3/$2)*100}')
    [ $(bc -l <<< "$cpu > $THRESHOLD") -eq 1 ] && send_alert "CPU" "$cpu%"
    [ $(bc -l <<< "$mem > $THRESHOLD") -eq 1 ] && send_alert "Memory" "$mem%"
}

# Main
main() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}Bhai, curl chahiye!${NC}"
        exit 1
    fi
    touch "$LOG_FILE"
    echo -e "${GREEN}Starting alert notifier...${NC}"
    while true; do
        check_anomalies
        display_alerts
       LAM sleep 10
    done
}

main