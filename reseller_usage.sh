#!/bin/bash

# Function to display help information
show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Calculate and display disk usage for each reseller (excluding 'root')."
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
}

# Check if the user has passed the help option
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Create a temporary file
temp_file=$(mktemp)

# Loop through each unique reseller (excluding 'root')
for reseller in $(cut -d' ' -f2 /etc/trueuserowners | grep -v "^root$" | sort | uniq); do
    # Display the current reseller being checked
    echo -en "Checking reseller ${reseller}\033[0K\r"
    
    # Get the list of accounts for the reseller and their disk usage
    accounts_json=$(whmapi1 --output=jsonpretty listaccts search=${reseller} searchtype=owner searchmethod=exact want=diskused)
    
    if [[ $? -ne 0 ]]; then
        echo "Error fetching accounts for reseller ${reseller}" >&2
        continue
    fi
    
    # Extract disk usage in MB and calculate total
    total_disk_mb=$(echo "$accounts_json" | grep diskused | cut -d'"' -f4 | cut -d'M' -f1 | paste -sd+ - | bc)
    
    # Handle case where total_disk_mb is empty
    if [[ -z "$total_disk_mb" ]]; then
        total_disk_mb=0
    fi
    
    # Convert MB to GB
    total_disk_gb=$(bc <<< "scale=2; ${total_disk_mb} / 1024")
    
    # Get the list of accounts for the reseller
    accounts=$(echo "$accounts_json" | jq -r '.data.acct[] | .user')
    
    # Count the number of accounts
    account_count=$(echo "$accounts" | wc -l)
    
    # Append reseller and their disk usage to the temporary file
    echo "$total_disk_gb GB - ${reseller} - ${account_count} Accounts" >> "$temp_file"
done

# Indicate completion
echo -e "\nDone"

# Sort the temporary file by the disk usage (first field) in ascending order and display the results
sort -k1,1n "$temp_file"

# Remove the temporary file
rm -f "$temp_file"
