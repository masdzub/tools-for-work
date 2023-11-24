#!/bin/bash

# Function to display table sizes in MB
show_table_sizes_in_MB() {
    echo " "
    mysql -e "SELECT table_name AS 'Table', ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '$1' ORDER BY (data_length + index_length) DESC;"
}

# Function to display table sizes in GB
show_table_sizes_in_GB() {
    echo " "
    mysql -e "SELECT table_name AS 'Table', ROUND(((data_length + index_length) / 1024 / 1024 / 1024), 2) AS 'Size (GB)' FROM information_schema.tables WHERE table_schema = '$1' ORDER BY (data_length + index_length) DESC;"
}

# Help message
help_message() {
    echo " "
    echo "Usage: $0 [-m|-g] database_name"
    echo "Options:"
    echo "  -m    Display table sizes in megabytes (MB)"
    echo "  -g    Display table sizes in gigabytes (GB)"
    echo "  -h    Display this help message"
    exit 1
}

# Check for the number of arguments provided
if [ "$#" -lt 2 ]; then
    echo " "
    echo -e "\e[31mError: Insufficient arguments. Provide an option (-m or -g) along with a database name.\e[0m" >&2
    help_message
fi

# Check for options
while getopts ":m:g:h" opt; do
    case $opt in
        m)
            show_table_sizes_in_MB "${@: -1}"
            ;;
        g)
            show_table_sizes_in_GB "${@: -1}"
            ;;
        h)
            help_message
            ;;
        \?)
            echo -e "\e[31mError: Invalid option: -$OPTARG. Use -m for MB, -g for GB, or -h for help.\e[0m" >&2
            exit 1
            ;;
        :)
            echo -e "\e[31mError: Option -$OPTARG requires an argument. Use -m for MB, -g for GB, or -h for help.\e[0m" >&2
            exit 1
            ;;
    esac
done
