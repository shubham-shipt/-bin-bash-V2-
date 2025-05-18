#!/bin/bash
#!/bin/bash

# auto_archive_cleaner.sh
# Archives old files, deletes stale ones, colorful summary

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
ARCHIVE_DIR="/archive"
LOG_FILE="/tmp/archive_cleaner.log"
ARCHIVE_AGE=30 # Days
DELETE_AGE=60 # Days

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, archive cleaner band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== Auto Archive Cleaner ===${NC}"
    echo -e "${GREEN}Processing $SOURCE_DIR${NC}\n"
}

# Display actions
display_actions() {
    display_header
    printf "${BLUE}%-30s %-10s %-20s${NC}\n" "File" "Action" "Timestamp"
    printf "${BLUE}%s${NC}\n" "-------------------------------------------------"
    tail -n 5 "$LOG_FILE" | while IFS='|' read -r file action time; do
        printf "${YELLOW}%-30s %-10s %-20s${NC}\n" "$file" "$action" "$time"
    done
}

# Archive file
archive_file() {
    local file=$1
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    mkdir -p "$ARCHIVE_DIR"
    tar -czf "$ARCHIVE_DIR/$(basename "$file")_$timestamp.tar.gz" "$file" 2>/dev/null
    echo "$file|Archived|$timestamp" >> "$LOG_FILE"
    rm -f "$file"
}

# Process files
process_files() {
    local dir=$1
    find "$dir" -type f -mtime +$ARCHIVE_AGE | while read -r file; do
        archive_file "$file"
    done
    find "$dir" -type f -mtime +$DELETE_AGE | while read -r file; do
        rm -f "$file"
        echo "$file|Deleted|$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    done
    display_actions
}

# Main
main() {
    if [ $# -ne 1 ]; then
        echo -e "${RED}Bhai, dir de! Usage: $0 <source_dir>${NC}"
        echo -e "${YELLOW}Example: $0 /var/log${NC}"
        exit 1
    fi
    SOURCE_DIR=$1
    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}Dir nahi hai!${NC}"
        exit 1
    fi
    touch "$LOG_FILE"
    echo -e "${GREEN}Starting archive cleaner...${NC}"
    process_files "$SOURCE_DIR"
}

main "$@"