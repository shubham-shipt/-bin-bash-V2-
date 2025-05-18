#!/bin/bash
#!/bin/bash

# bash_reverse_shell_orchestrator.sh
# Manages reverse shells with colorful dashboard

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/shell_orchestrator.log"
declare -A SHELLS

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, shell orchestrator band!${NC}"
    for pid in "${!SHELLS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== Reverse Shell Orcheuator ===${NC}"
    echo -e "${GREEN}Managing shells on port $PORT${NC}\n"
}

# Display shells
display_shells() {
    display_header
    printf "${BLUE}%-15s %-10s %-15s${NC}\n" "IP" "Port" "Status"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------"
    for pid in "${!SHELLS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            status="${GREEN}Active${NC}"
        else
            status="${RED}Disconnected${NC}"
            unset SHELLS[$pid]
        fi
        ip_port=${SHELLS[$pid]}
        ip=$(echo "$ip_port" | cut -d'|' -f1)
        port=$(echo "$ip_port" | cut -d'|' -f2)
        printf "${YELLOW}%-15s %-10s %-15s${NC}\n" "$ip" "$port" "$status"
    done
}

# Listen for shells
listen_shells() {
    local port=$1
    while true; do
        nc -l -p "$port" | while read -r line; do
            ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            SHELLS[$$]="$ip|$port"
            echo "$timestamp New shell: $ip:$port" >> "$LOG_FILE"
            display_shells
        done &
        pid=$!
        SHELLS[$pid]="unknown|$port"
        wait $pid
    done
}

# Main
main() {
    if [ $# -ne 1 ]; then
        echo -e "${RED}Bhai, port de! Usage: $0 <port>${NC}"
        echo -e "${YELLOW}Example: $0 4444${NC}"
        exit 1
    fi
    PORT=$1
    if ! command -v nc >/dev/null 2>&1; then
        echo -e "${RED}Bhai, netcat chahiye!${NC}"
        exit 1
    fi
    touch "$LOG_FILE"
    echo -e "${GREEN}Starting shell orchestrator on port $PORT...${NC}"
    listen_shells "$PORT"
}

main "$@"