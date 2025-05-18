#!/bin/bash
#!/bin/bash

# file_metadata_reporter.sh
# Generates file metadata reports with colorful output

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/metadata_report.log"

# Trap Ctrl+C
trap cleanup SIGINT

cleanup() {
    echo -e "\n${RED}Bhai, metadata report band!${NC}"
    exit 0
}

# Fancy header
display_header() {
    clear
    echo -e "${BLUE}=== File Metadata Reporter ===${NC}"
    echo -e "${GREEN}Generating file reports${NC}\n"
}

# Display metadata
display_metadata() {
    display_header
    printf "${BLUE}%-30s %-15s %-15s %-20s${NC}\n" "File" "Size" "Perms" "ACL/EXIF"
    printf "${BLUE}%s${NC}\n" "-------------------------------------------------"
    while IFS='|' read -r file size perms extra; do
        printf "${YELLOW}%-30s %-15s %-15s %-20s${NC}\n" "$file" "$size" "$perms" "$extra"
    done < /tmp/metadata.txt
}

# Generate report
generate_report() {
    local files=("$@")
    touch "$LOG_FILE" /tmp/metadata.txt
    > /tmp/metadata.txt
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "$file|N/A|N/A|Not found" >> /tmp/metadata.txt
            continue
        fi
        size=$(stat -c %s "$file")
        perms=$(stat -c %A "$file")
        extra=""
        # Check ACL
        acl=$(getfacl "$file" 2>/dev/null | grep -c "user:")
        [ $acl -gt 0 ] && extra="ACL:$acl "
        # Check EXIF
        if command -v exiftool >/dev/null 2>&1; then
            exif=$(exiftool "$file" 2>/dev/null | grep -c "EXIF")
            [ $exif -gt 0 ] && extra="${extra}EXIF:Yes"
        fi
        [ -z "$extra" ] && extra="None"
        echo "$file|$size|$perms|$extra" >> /tmp/metadata.txt
        echo "$(date '+%Y-%m-%d %H:%M:%S') $file: $size bytes, $perms, $extra" >> "$LOG_FILE"
    done
    display_metadata
}

# Main
main() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}Bhai, files de! Usage: $0 <file1> <file2> ...${NC}"
        echo -e "${YELLOW}Example: $0 image.jpg doc.txt${NC}"
        exit 1
    fi
    echo -e "${GREEN}Starting metadata reporter...${NC}"
    generate_report "$@"
}

main "$@"