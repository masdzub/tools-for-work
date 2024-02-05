#!/bin/bash

# Color codes
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
red='\033[1;31m'
purple='\033[0;35m'
cyan='\033[0;36m'
reset='\033[0m'

# Function to prompt for domain if not provided
prompt_for_domain() {
  if [ -z "$user_input" ]; then
    read -p "$(echo -e 'Enter the domain: ')" user_input
  fi
}

# Function to display error message and exit
display_error() {
  echo -e "${red}Error: $1${reset}"
}

# Function to display error message and exit
display_help() {
  echo -e "${purple}Usage: $0 [-d <Domain>] [-c] [-h]${reset}"
  echo -e "\n${cyan}Options:${reset}"
  echo -e "  ${blue}-d <domain or IP>${reset}\tPerform DNS lookup for the specified domain."
  echo -e "  ${blue}-c${reset}\t\t\tCustom user and port to SSH after performing DNS lookup."
  echo -e "  ${blue}-h${reset}\t\t\tDisplay this help message."
  echo -e "\n${cyan}Example:${reset}"
  echo -e "  ${yellow}$0 -d example.com -c${reset}"
  exit 1
}

# Function for DNS lookup
perform_dns_lookup() {
  ip_address=$(dig +short "$1" | head -n 1)
  hostname=$(dig +short "$1" | xargs host | awk '{print $5}' | sed 's/\.$//')

  [ -z "$ip_address" ] && { display_error "Unable to determine the IP address for${reset} ${yellow}$1${reset} \n${red}Please check record domain"; exit 0; }
  echo "$hostname" | grep -qE '^[a-zA-Z0-9.-]+$' || display_error "Invalid hostname: $hostname"
}

# Function to display SSH connection message
ssh_connect() {
  echo -e "${purple}\033[0;35mConnecting to ${yellow}$hostname${reset} ${purple}via SSH...${reset}"

  # Prompt for SSH port
  read -p "$(echo -e 'Enter the SSH port (press Enter for default 22): ')" ssh_port
  ssh_port=${ssh_port:-22}

  # Prompt for SSH username
  read -p "$(echo -e 'Enter the SSH username (press Enter for default adzubayyan): ')" ssh_username
  ssh_username=${ssh_username:-adzubayyan}

  # Attempt SSH connection with specified port and username
  ssh -p "$ssh_port" "$ssh_username@$hostname"
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
  read -p "$(echo -e 'Enter the domain: ')" user_input
  [ -z "$user_input" ] && { display_error "Domain is required"; }
else
  while getopts ":d:ch" opt; do
    case $opt in
      d)
        user_input="$OPTARG"
        ;;
      c)
        connect_option=true
        ;;
      h)
        display_help
        ;;
      *)
        display_error "Invalid option: -$OPTARG"
        display_help
        ;;
      :)
        display_error "Option -$OPTARG requires an argument."
        display_help
        ;;
    esac
  done
fi

# Perform DNS lookup and extract the hostname and IP address
prompt_for_domain
# Title
echo -e "\n${blue}\033[1;34m======= Domain Lookup and Connect to SSH =======${reset}"
perform_dns_lookup "$user_input"

# Display information with colored output
echo -e "Domain Name \t:${yellow}$user_input${reset}"
echo -e "IP Address \t:${yellow}$ip_address${reset}"
echo -e "Hostname \t:${yellow}$hostname${reset}\n"

if [ "$connect_option" = true ]; then
  read -p "$(echo -e 'Do you want to connect to '${yellow}$hostname${reset}' via SSH? (\033[0;32my\033[0m/\033[1;31mn\033[0m): ')" choice
  if [ "$choice" = "y" ]; then
    [ -z "$ip_address" ] && { display_error "IP address is blank. Cannot continue."; exit 0;} 
    ssh_connect
  else
    echo -e "${red}The SSH connection was not established and is being skipped. SSH is not currently running.${reset}"
    exit 0
  fi
else
  read -p "$(echo -e 'Do you want to connect to '${yellow}$hostname${reset}' via SSH? (\033[0;32my\033[0m/\033[1;31mn\033[0m): ')" choice
  if [ "$choice" = "y" ]; then
    [ -z "$ip_address" ] && { display_error "IP address is blank. Cannot continue."; exit 0;} 
    # If -c option is not specified, perform default SSH connection
    echo -e "${purple}\033[0;35mConnecting to ${yellow}$hostname${reset} ${purple}via SSH...${reset}"
    # Attempt SSH connection with default settings
    ssh "$hostname"
  else
    echo -e "${red}The SSH connection was not established and is being skipped. SSH is not currently running.${reset}"
    exit 0  
  fi
fi
