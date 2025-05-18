#!/bin/bash

# smart_resource_limiter.sh
# Dynamically limits CPU/RAM for processes with a colorful dashboard

# Check dependencies
command -v cpulimit >/dev/null 2>&1 || { echo -e "${RED}cpulimit required!${NC}"; exit 1; }
command -v cgcreate >/dev/null 2>&1 || { echo -e "${RED}cgroups tools required!${NC}"; exit 1; }

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Trap Ctrl+C
trap cleanup SIGINT

# Global variables
CGROUP_NAME="smart_limiter"
declare -A PIDS
declare -A LIMITS

# Cleanup function
cleanup() {
    echo -e "\n${RED}Cleaning up...${NC}"
    for pid in "${!PIDS[@]}"; do
        kill -TERM "$pid" 2>/dev/null
    done
    cgdelete -g cpu,memory:/$CGROUP_NAME 2>/dev/null
    exit 0
}

# Function to draw progress bar
draw_bar() {
    local value=$1
    local max=$2
    local width=20
    local filled=$((value * width / max))
    local empty=$((width - filled))
    printf "${GREEN}"
    printf "%${filled}s" | tr ' ' '█'
    printf "${NC}"
    printf "%${empty}s" | tr ' ' ' '
}

# Function to display dashboard
display_dashboard() {
    clear
    echo -e "${BLUE}=== Smart Resource Limiter ===${NC}"
    printf "${YELLOW}%-10s %-10s %-10s %-20s %-20s${NC}\n" "PID" "CPU%" "Mem%" "CPU Limit" "Mem Limit"
    printf "${BLUE}%s${NC}\n" "-------------------------------------------------------------"
    for pid in "${!PIDS[@]}"; do
        cpu=$(ps -p "$pid" -o %cpu | tail -n 1 | awk '{print $1}')
        mem=$(ps -p "$pid" -o %mem | tail -n 1 | awk '{print $1}')
        cpu_limit=${LIMITS[$pid,cpu]}
        mem_limit=${LIMITS[$pid,mem]}
        printf "%-10s %-10s %-10s " "$pid" "$cpu" "$mem"
        draw_bar "$cpu" 100
        printf " "
        draw_bar "$mem" 100
        printf "\n"
    done
}

# Function to apply limits
apply_limits() {
    local pid=$1
    local cpu_limit=$2
    local mem_limit=$3

    # Apply CPU limit using cpulimit
    cpulimit -p "$pid" -l "$cpu_limit" &
    LIMITS[$pid,cpu]=$cpu_limit

    # Apply memory limit using cgroups
    cgset -r memory.limit_in_bytes=$((mem_limit * 1024 * 1024)) /$CGROUP_NAME
    echo "$pid" > /sys/fs/cgroup/memory/$CGROUP_NAME/tasks
    LIMITS[$pid,mem]=$mem_limit
}

# Main function
main() {
    if [ $# -lt 3 ]; then
        echo -e "${RED}Usage: $0 <pid> <cpu_limit%> <mem_limit_MB> [...]${NC}"
        echo -e "${YELLOW}Example: $0 12345 50 100 12346 30 200${NC}"
        exit 1
    fi

    # Setup cgroup
    cgcreate -g cpu,memory:/$CGROUP_NAME

    # Parse arguments
    while [ $# -ge 3 ]; do
        pid=$1
        cpu_limit=$2
        mem_limit=$3
        if ! kill -0 "$pid" 2>/dev/null; then
            echo -e "${RED}PID $pid not found!${NC}"
            shift 3
            continue
        fi
        PIDS[$pid]=$pid
        apply_limits "$pid" "$cpu_limit" "$mem_limit"
        shift 3
    done

    # Monitor
    while [ ${#PIDS[@]} -gt 0 ]; do
        for pid in "${!PIDS[@]}"; do
            if ! kill -0 "$pid" 2>/dev/null; then
                unset PIDS[$pid]
                unset LIMITS[$pid,cpu]
                unset LIMITS[$pid,mem]
            fi
        done
        display_dashboard
        sleep 1
    done

    cleanup
}

# Run main
main "$@"