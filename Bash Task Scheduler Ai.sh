#!/bin/bash
#!/bin/bash

# bash_task_scheduler_ai.sh
# Reschedules tasks based on runtimes with colorful schedule

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/task_scheduler.log"
TASK_LOG="/tmp/task_times.txt"

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, scheduler band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== AI Task Scheduler ===${NC}"
    echo -e "${GREEN}Optimized task schedule${NC}\n"
}

# Display schedule
display_schedule() {
    display_header
    printf "${BLUE}%-30s %-15s %-20s${NC}\n" "Task" "Next Run" "Avg Runtime"
    printf "${BLUE}%s${NC}\n" "-------------------------------------------------"
    while IFS='|' read -r task next_run runtime; do
        printf "${YELLOW}%-30s %-15s %-20s${NC}\n" "$task" "$next_run" "$runtime"
    done < /tmp/schedule.txt
}

# Reschedule task
reschedule_task() {
    local task=$1 runtime=$2
    # Simple heuristic: run every runtime*2 minutes
    interval=$(bc -l <<< "$runtime * 2")
    minute=$((RANDOM % 60))
    schedule="$minute */${interval%.*} * * * $task"
    (crontab -l 2>/dev/null | grep -v "$task"; echo "$schedule") | crontab -
    next_run=$(date -d "+${interval%.*} minutes" '+%H:%M')
    echo "$task|$next_run|${runtime}s" >> /tmp/schedule.txt
    echo "$(date '+%Y-%m-%d %H:%M:%S') Rescheduled $task to $schedule" >> "$LOG_FILE"
}

# Analyze tasks
analyze_tasks() {
    local tasks=("$@")
    touch "$LOG_FILE" "$TASK_LOG" /tmp/schedule.txt
    > /tmp/schedule.txt
    for task in "${tasks[@]}"; do
        runtime=$(grep "$task" "$TASK_LOG" | awk '{sum+=$2; n++} END {if (n>0) print sum/n; else print 60}')
        reschedule_task "$task" "$runtime"
    done
    display_schedule
}

# Main
main() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}Bhai, tasks de! Usage: $0 <task1> <task2> ...${NC}"
        echo -e "${YELLOW}Example: $0 'backup.sh' 'clean.sh'${NC}"
        exit 1
    fi
    echo -e "${GREEN}Scheduling tasks...${NC}"
    analyze_tasks "$@"
}

main "$@"