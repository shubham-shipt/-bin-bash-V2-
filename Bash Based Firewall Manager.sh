#!/bin/bash
#!/bin/bash

# bash_based_firewall_manager.sh
# Manages iptables rules with colorful output

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
BACKUP_FILE="/tmp/iptables_backup_$(date +%Y%m%d_%H%M%S).rules"

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, firewall manager band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== Firewall Manager ===${NC}"
    echo -e "${GREEN}Managing iptables rules${NC}\n"
}

# Display rules
display_rules() {
    display_header
    printf "${BLUE}%-10s %-15s %-10s %-15s${NC}\n" "Chain" "Source" "Dest" "Action"
    printf "${BLUE}%s${NC}\n" "---------------------------------------------"
    iptables -L INPUT -n --line-numbers | grep -v "^Chain" | grep -v "^num" | while read -r line; do
        chain="INPUT"
        src=$(echo "$line" | awk '{print $3}')
        dst=$(echo "$line" | awk '{print $4}')
        action=$(echo "$line" | awk '{print $1}')
        printf "%-10s %-15s %-10s %-15s\n" "$chain" "$src" "$dst" "$action"
    done
}

# Backup rules
backup_rules() {
    iptables-save > "$BACKUP_FILE" 2>/dev/null
    echo -e "${GREEN}Rules backed up to $BACKUP_FILE${NC}"
}

# Main
main() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Bhai, command de! Usage: $0 {add|remove|list} [args]${NC}"
        echo -e "${YELLOW}Example: $0 add 192.168.1.100 DROP${NC}"
        exit 1
    fi
    action=$1
    shift
    case "$action" in
        add)
            if [ $# -lt 2 ]; then
                echo -e "${RED}IP aur action de!${NC}"
                exit 1
            fi
            ip=$1
            act=$2
            backup_rules
            iptables -A INPUT -s "$ip" -j "$act" 2>/dev/null
            echo -e "${GREEN}Rule added for $ip${NC}"
            display_rules
            ;;
        remove)
            if [ $# -lt 1 ]; then
                echo -e "${RED}IP de!${NC}"
                exit 1
            fi
            ip=$1
            backup_rules
            iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            echo -e "${GREEN}Rule removed for $ip${NC}"
            display_rules
            ;;
        list)
            display_rules
            ;;
        *)
            echo -e "${RED}Galat action! Use add, remove, list${NC}"
            exit 1
            ;;
    esac
}

main "$@"