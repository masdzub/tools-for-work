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

# Create or empty the temporary file
> .resellers.tmp

# Loop through each unique reseller (excluding 'root')
for reseller in $(cut -d' ' -f2 /etc/trueuserowners | grep -v "^root$" | sort | uniq); do
    # Display the current reseller being checked
    echo -en "Checking reseller ${reseller}\033[0K\r"
    
    # Calculate total disk used by the reseller in MB
    total_disk_mb=$(whmapi1 --output=jsonpretty listaccts search=${reseller} searchtype=owner searchmethod=exact want=diskused \
        | grep diskused | cut -d'"' -f4 | cut -d'M' -f1 | paste -sd+ - | bc)
    
    # Convert MB to GB
    total_disk_gb=$(bc <<< "scale=2; ${total_disk_mb} / 1024")
    
    # Get the list of accounts for the reseller
    accounts=$(whmapi1 listaccts search=${reseller} searchtype=owner --output=json | jq -r '.data.acct[] | .user')

    # Count the number of accounts
    account_count=$(echo "$accounts" | wc -l)

    # Append reseller and their disk usage to the temporary file
    echo "${reseller} - ${total_disk_gb} GB - ${account_count} Accounts" >> .resellers.tmp
done

# Indicate completion
echo -e "\nDone"

# Sort the temporary file by the disk usage in ascending order and display the results
sort -k2 -n .resellers.tmp

# Remove the temporary file
rm -f .resellers.tmp
