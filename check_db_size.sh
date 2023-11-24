#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display help
display_help() {
    echo -e "${YELLOW}Usage: $0 [-m/-g] schema_name${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "${YELLOW}  -m    ${NC}Display size in ${GREEN}MB${NC} (default if no option provided)"
    echo -e "${YELLOW}  -g    ${NC}Display size in ${GREEN}GB${NC}"
    echo -e "${YELLOW}  -h    ${NC}Display this ${GREEN}help${NC} message"
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "${GREEN}  $0 -m my_schema       ${NC}# Display size in ${GREEN}MB${NC} for 'my_schema'"
    echo -e "${GREEN}  $0 -g another_schema  ${NC}# Display size in ${GREEN}GB${NC} for 'another_schema'"
    exit 0
}

# Function to execute SQL queries and display results based on the option
execute_query() {
    local schema="$1"
    local option="$2"
    local query=""

    if [[ "$option" == "-g" ]]; then
        # Query to get size in GB
        query="SELECT table_schema AS \`Database\`, 
            ROUND(SUM(data_length + index_length) / (1024 * 1024 * 1024), 2) AS \`Size_in_GB\`
            FROM information_schema.tables
            WHERE table_schema LIKE '${schema}%'
            GROUP BY table_schema;"
    else
        # Default: Query to get size in MB
        query="SELECT table_schema AS \`Database\`, 
            SUM(data_length + index_length) / (1024 * 1024) AS \`Size_in_MB\`
            FROM information_schema.tables
            WHERE table_schema LIKE '${schema}%'
            GROUP BY table_schema;"
    fi

    # Execute the query using mysql command-line tool and color the output
    mysql -e "$query" 
}

# Check if no arguments provided or too many arguments
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo -e "${RED}Error: Incorrect number of arguments.${NC}"
    display_help
fi

# Parse command-line options
while getopts ":hmg" option; do
    case "$option" in
        m)
            selected_option="-m"
            ;;
        g)
            selected_option="-g"
            ;;
        h)
            display_help
            ;;
        *)
            echo -e "${RED}Error: Invalid option. Please use -m for MB, -g for GB, or -h for help.${NC}"
            exit 1
            ;;
    esac
done

# Check if an option is provided, if not, default to MB
if [ -z "$selected_option" ]; then
    selected_option="-m"
fi

# Set the schema name based on the provided argument
schema_index=$((OPTIND))
schema_name="${!schema_index}"

# Call the function with the specified schema name and option
execute_query "$schema_name" "$selected_option"

