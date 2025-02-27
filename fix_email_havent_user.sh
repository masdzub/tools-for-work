#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 <cpuser>"
    echo
    echo "This script checks and creates missing email directories for a given cPanel user."
    echo
    echo "Arguments:"
    echo "  <cpuser>  The cPanel username whose email directories should be verified and fixed."
    echo
    echo "Example:"
    echo "  $0 ahmedksm"
    exit 0
}

# Check if user requested help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# Check if cpuser is provided
if [[ -z "$1" ]]; then
    echo "Error: No cPanel username provided."
    echo "Run '$0 --help' for usage details."
    exit 1
fi

# Define cPanel user from input argument
cpuser="$1"

# Fetch email list dynamically
emails=$(uapi --user=$cpuser Email list_pops | grep "email:" | awk '{print $2}' | sort -h)

# Check if emails were retrieved
if [[ -z "$emails" ]]; then
    echo "No email accounts found for user: $cpuser"
    exit 1
fi

# Loop through each email
for email in $emails; do
    # Extract domain and user
    user=$(echo "$email" | cut -d'@' -f1)
    domain=$(echo "$email" | cut -d'@' -f2)

    # Define mail directory path
    maildir="/home/$cpuser/mail/$domain/$user"

    # Check if the folder exists
    if [ ! -d "$maildir" ]; then
        echo "Directory $maildir does not exist. Creating..."
        mkdir -p "$maildir"
        chown $cpuser. -R "$maildir"
    else
        echo "Directory $maildir already exists."
    fi

    # Check folder status
    stat "$maildir"
done

# Run mailperm script at the end
/usr/local/cpanel/scripts/mailperm $cpuser

echo "Process completed!"
