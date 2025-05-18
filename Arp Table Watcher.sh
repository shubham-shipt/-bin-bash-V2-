#!/bin/bash

# arp_table_watcher.sh
# Watches ARP table for new devices with colorful alerts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file
LOG_FILE="/tmp/arp_watcher.log"

# Store known devices
KNOWN_DEVICES="/tmp/arp_known.txt"

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, watching band! Cleaning up...${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== ARP Table Watcher ===${NC}"
    echo -e "${GREEN}Monitoring new devices on LAN${NC}\n"
}

# Display new devices
display_new_devices() {
    display_header
    printf "${BLUE}%-15s %-20s %-20s${NC}\n" "IP" "MAC" "Timestamp"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------"
    tail -n 5 "$LOG_FILE" | while IFS='|' read -r ip mac time; do
        printf "${YELLOW}%-15s %-20s %-20s${NC}\n" "$ip" "$mac" "$time"
    done
}

# Check ARP table
check_arp() {
    touch "$KNOWN_DEVICES" "$LOG_FILE"
    arp -n | awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1" "$3}' | while read -r ip mac; do
        if ! grep -q "$ip $mac" "$KNOWN_DEVICES"; then
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            echo "$ip|$mac|$timestamp" >> "$LOG_FILE"
            echo "$ip $mac" >> "$KNOWN_DEVICES"
            echo -e "${RED}New device detected: IP=$ip MAC=$mac${NC}"
        fi
    done
    display_new_devices
}

# Main
main() {
    echo -e "${GREEN}Starting ARP watcher...${NC}"
    while true; do
        check_arp
        sleep 10
    done
}

main