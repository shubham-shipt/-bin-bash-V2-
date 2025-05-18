#!/bin/bash
#!/bin/bash

# bash_nmap_wrapper_ai.sh
# Customizes nmap scans with colorful report

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/nmap_wrapper.log"

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, nmap wrapper band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== Nmap AI Wrapper ===${NC}"
    echo -e "${GREEN}Scanning targets${NC}\n"
}

# Display results
display_results() {
    display_header
    printf "${BLUE}%-20s %-10s %-30s${NC}\n" "Target" "Port" "Service"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------"
    cat /tmp/nmap_results.txt | while IFS='|' read -r target port service; do
        printf "${YELLOW}%-20s %-10s %-30s${NC}\n" "$target" "$port" "$service"
    done
}

# Choose scan type
choose_scan() {
    local target=$1
    # Simple heuristic: fast scan for IPs, full for domains
    if [[ $target =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "-F" # Fast scan
    else
        echo "-sV" # Service version
    fi
}

# Run scan
run_scan() {
    local target=$1
    options=$(choose_scan "$target")
    nmap $options "$target" | grep "open" | while read -r line; do
        port=$(echo "$line" | awk '{print $1}')
        service=$(echo "$line" | awk '{print $3}')
        echo "$target|$port|$service" >> /tmp/nmap_results.txt
        echo "$(date '+%Y-%m-%d %H:%M:%S') $target $port $service" >> "$LOG_FILE"
    done
    display_results
}

# Main
main() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}Bhai, targets de! Usage: $0 <target1> <target2> ...${NC}"
        echo -e "${YELLOW}Example: $0 192.168.1.1 google.com${NC}"
        exit 1
    fi
    if ! command -v nmap >/dev/null 2>&1; then
        echo -e "${RED}Bhai, nmap chahiye!${NC}"
        exit 1
    fi
    touch "$LOG_FILE" /tmp/nmap_results.txt
    echo -e "${GREEN}Starting nmap scans...${NC}"
    for target in "$@"; do
        run_scan "$target"
    done
}

main "$@"