#!/bin/bash

# dynamic_cron_scheduler.sh
# Dynamically manages cron jobs with colorful output

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to validate cron schedule
validate_cron() {
    local schedule="$1"
    local parts=($schedule)
    [ ${#parts[@]} -eq 5 ] || return 1
    return 0
}

# Function to display cron jobs
display_crons() {
    clear
    echo -e "${BLUE}=== Dynamic Cron Scheduler ===${NC}"
    printf "${YELLOW}%-20s %-50s${NC}\n" "Schedule" "Command"
    printf "${BLUE}%s${NC}\n" "-------------------------------------------------------------"
    crontab -l 2>/dev/null | grep -v '^#' | while read -r line; do
        schedule=$(echo "$line" | awk '{print $1" "$2" "$3" "$4" "$5}')
        command=$(echo "$line" | cut -d' ' -f6-)
        printf "%-20s %-50s\n" "$schedule" "$command"
    done
}

# Function to backup crontab
backup_crontab() {
    crontab -l > "/tmp/crontab.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    echo -e "${GREEN}Crontab backed up${NC}"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Usage: $0 {add|remove|list} [schedule command]${NC}"
        echo -e "${YELLOW}Example: $0 add '* * * * *' 'echo Hello'${NC}"
        exit 1
    fi

    action=$1
    shift

    case "$action" in
        add)
            if [ $# -lt 2 ]; then
                echo -e "${RED}Schedule and command required!${NC}"
                exit 1
            fi
            schedule="$1"
            shift
            command="$@"
            if ! validate_cron "$schedule"; then
                echo -e "${RED}Invalid cron schedule!${NC}"
                exit 1
            fi
            backup_crontab
            (crontab -l 2>/dev/null; echo "$schedule $command") | crontab -
            echo -e "${GREEN}Cron job added${NC}"
            display_crons
            ;;
        remove)
            if [ $# -lt 1 ]; then
                echo -e "${RED}Command required!${NC}"
                exit 1
            fi
            command="$@"
            backup_crontab
            crontab -l 2>/dev/null | grep -v "$command" | crontab -
            echo -e "${GREEN}Cron job removed${NC}"
            display_crons
            ;;
        list)
            display_crons
            ;;
        *)
            echo -e "${RED}Invalid action! Use add, remove, or list${NC}"
            exit 1
            ;;
    esac
}

# Run main
main "$@"