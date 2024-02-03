#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

while getopts ":u:f:h" opt; do
    case $opt in
        u)
            user="$OPTARG"
            ;;
        f)
            file="$OPTARG"
            ;;
        h)
            echo -e "Usage: $0 -u <username> OR -f <file_path>"
            echo -e "Options:"
            echo -e "  -u <username>   Specify a single username to search for"
            echo -e "  -f <file_path>  Specify a file containing multiple usernames (one per line)"
            echo -e "  -h              Display this help message"
            echo -e "\nExample:"
            echo -e "  $0 -u john_doe       # Search for files related to a single username"
            echo -e "  $0 -f usernames.txt  # Bulk search for files for multiple usernames from a file"
            exit 0
            ;;
        \?)
            echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
            exit 1
            ;;
        :)
            echo -e "${RED}Option -$OPTARG requires an argument.${NC}" >&2
            exit 1
            ;;
    esac
done

if [ -z "$user" ] && [ -z "$file" ]; then
    echo -e "${RED}Error: Username or file path is required. Use '-h' for help.${NC}"
    exit 1
fi

# Function to search for files related to a username
search_files() {
    local username="$1"
    local document_root="$2"

    matches=$(grep -ril -e "${username}_" --include="*.php" --include=".env" --include="config*.json" --include="config*.js" --include="server*.js" --exclude="*.js" --exclude="*.sql" --exclude="*.zip" --exclude="*.txt" --exclude="*.log" --exclude=error_log --exclude=".htaccess" "$document_root")

    if [ -n "$matches" ]; then
        echo -e "${GREEN}Files found in $document_root:${NC}"
        echo -e "$matches\n"
    fi
}

# If usernames are provided as a file
if [ -n "$file" ]; then
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File '$file' not found.${NC}"
        exit 1
    fi

    while IFS= read -r username; do
        echo -e "${GREEN}Searching for files related to username: $username${NC}"

        # Perform the search for each username in the file
        docs=$(uapi --user="$username" DomainInfo domains_data --output=json | jq -r -c '.result.data | .main_domain, .sub_domains[], .addon_domains[] | .documentroot' | paste -sd " ")

        for i in $docs; do
            search_files "$username" "$i"
        done

    done < "$file"

# If a single username is provided
elif [ -n "$user" ]; then
    echo -e "${GREEN}Searching for files related to username: $user${NC}"

    # Perform the search for the single username
    docs=$(uapi --user="$user" DomainInfo domains_data --output=json | jq -r -c '.result.data | .main_domain, .sub_domains[], .addon_domains[] | .documentroot' | paste -sd " ")

    for i in $docs; do
        search_files "$user" "$i"
    done
fi
