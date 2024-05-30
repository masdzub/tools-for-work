#!/bin/bash

# Initialize domain variable
server_domain=""

# Function to display usage information
usage() {
    echo "Usage: $0 [-d <domain_name>] [-h]" 1>&2
    exit 1
}

# Parse command line options
while getopts ":d:h" opt; do
    case $opt in
        d)
            server_domain="$OPTARG"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Prompt for domain name if not provided as an option
if [ -z "$server_domain" ]; then
    read -p "Enter server domain: " server_domain
fi

# Check if domain name is still empty
if [ -z "$server_domain" ]; then
    echo "Error: Domain name is required." >&2
    usage
fi

echo -e "\n# open restriction"
echo -e "plesk bin poweruser --off -lock false"
echo -e "plesk bin poweruser --on -simple false -lock false"

echo -e "\n# Backup Plesk sys db"
echo -e "plesk db dump psa > C:\psa_dump.sql\n\n"

echo -e "# Make admin owner of all subscriptions "
echo -e "foreach (\$subscription in plesk bin subscription --list) {plesk bin subscription --change-owner \$subscription -owner admin}\n\n"

# Generate a random password
password=$(openssl rand -base64 18)

echo -e "# Create a new end client user"
short_hostname=$(echo "$server_domain" | cut -d'.' -f1)
username="${short_hostname}n"
email="${username}@${server_domain}"

echo -e "plesk bin user --create \"$username\" -owner admin -passwd \"$password\" -cname \"$username\" -email \"$email\" -role webmaster\n\n"
