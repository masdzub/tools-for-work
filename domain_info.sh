#!/bin/bash

# domain information
# (c) 2023 Dzubayyan Ahmad
# tools for work

# ANSI color codes
#RED='\033[1;31m'
#GREEN='\033[1;32m'
#YELLOW='\033[1;33m'
#CYAN='\033[1;36m'
#RESET='\033[0m'

# ANSI color codes using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
PURPLE=$(tput setaf 5)
RESET=$(tput sgr0)
BOLD=$(tput bold)

# Default DNS server for A, AAAA, MX, NS, TXT records
default_dns="1.1.1.1"

# Function to prompt for domain if not provided
prompt_for_domain() {
  if [ -z "$domain" ]; then
    read -p "Enter the domain name: " domain
  fi
}

# Function to display records
display_records() {
  local record_type=$1
  local record_data=$2
  if [ -n "$record_data" ]; then
    echo -e "${CYAN}$record_type record:${RESET}"
    echo "$record_data" | sed 's/^/  /'
  else
    echo -e "${RED}$record_type record: - ${RESET}"
  fi
}

# Function to display IP and PTR records
display_a-ptr_records() {
  local record_type=$1
  local ip_addresses=$2
  [ -z "${ip_addresses}" ] && printf "${RED}%4s record: -${RESET}\n" ${record_type} && return
  
  printf "${CYAN}%s record:${RESET}\n" ${record_type}
  
  for ip in $ip_addresses ; do
     local ptr_info=$(dig +short -x $ip)
     if [ -z "${ptr_info}" ] ; then
        printf "  %-39s\t${RED}%s${RESET}\n" ${ip} "-"
    else
        printf "  %-39s\t${PURPLE}%s${RESET}\n" ${ip} ${ptr_info}
     fi
  done
}

# Function to display SSL information
display_ssl_info() {
  local openssl_info=$(openssl s_client -showcerts -connect $domain:443 -servername $domain </dev/null 2>/dev/null | openssl x509 -noout -subject -dates -ext subjectAltName -issuer 2>/dev/null | grep -v X509v3)
  if [ $? -eq 0 ]; then
    echo -e "${CYAN}[SSL Information]${RESET}"
    echo "$openssl_info" | sed 's/^/  /'
  else
    echo -e "${RED}No SSL information available or cannot be read for $domain on port 443.${RESET}"
  fi
}

# Function to display DNS information
display_dns_info() {
  local dns_server=$1

  a_record=$(dig +short @$dns_server $domain A)
  display_a-ptr_records "A" "$a_record"

  aaaa_record=$(dig +short @$dns_server $domain AAAA)
  display_a-ptr_records "AAAA" "$aaaa_record"

  www_record=$(dig +noall +answer @$dns_server www.$domain A | awk '{print $4 "\t" $5}')
  display_records "WWW" "$www_record"

  mail_record=$(dig +noall +answer @$dns_server mail.$domain A | awk '{print $4 "\t" $5}')
  display_records "MAIL" "$mail_record"


  mx_record=$(dig +short @$dns_server $domain MX | sort -n)
  display_records "MX" "$mx_record"

  txt_record=$(dig +short @$dns_server $domain TXT)
  display_records "TXT" "$txt_record"

  ns_record=$(dig +short @$dns_server $domain NS)
  display_records "NS" "$ns_record"
}

# Function to print help
print_help() {
  echo ""
  echo -e "${CYAN}Usage:${RESET} $(basename "$0") ${YELLOW}[-d domain] [-s dns_server] [-h]${RESET}"
  echo -e "${CYAN}Usage:${RESET} $(basename "$0") ${YELLOW}[domain] [@dns_server] [-h]${RESET}"
  echo -e "  ${YELLOW}domain${RESET}       Domain name to be queried"
  echo -e "  ${YELLOW}dns_server${RESET}   Optional custom DNS server to query"
  echo ""
  echo -e "Example Usage:"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com${RESET}"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com -s 1.1.1.1${RESET}"
  echo ""
}

# Function to exit
bail() {
    echo "${RED}$@${RESET}" >&2
    print_help
    exit 3
}

# Function to check domain status
check_domain_status() {
  local domain_status=$(whois $domain | grep "serverHold\|clientHold")

  if [[ $domain_status == *"clientHold"* ]]; then
    echo -e "${RED}[Domain Status]${RESET}"
    echo -e "${YELLOW}Status:${RESET} ${RED}clientHold${RESET}\n\n[Suspended by the registrar or domain provider]\n"
  elif [[ $domain_status == *"serverHold"* ]]; then
    echo -e "${RED}[Domain Status]${RESET}"
    echo -e "${YELLOW}Status:${RESET} ${RED}serverHold${RESET}\n\n[Suspended by the registry]\n"
  fi
}

# Function to check domain registration status
check_status_registration() {
  local domain_regist=$(whois $domain | grep -Ei "(No match for domain|DOMAIN NOT FOUND|No Data Found|Domain not found|is available|The queried object does not exist|is not registered|not been registered)")
  if [[ -n "$domain_regist" ]]; then
      echo -e "\nThe domain ${RED}is not registered${RESET}."
      echo "Please ensure you are using the ${RED}main domain${RESET} and correct TLD, ${RED}not a subdomain${RESET}."
  else
      display_dns_info $dns_server
  fi
}

error_flag=0  # Initialize error_flag variable

# TODO: 
# * handle "--domain domain" long options
# * resolve bug where "$0 domain -s dns_server" is interpreted as looking up
# "dns_server" as a domain, against the default dns server. 
while getopts ":d:s:h" opt ; do
    case "${opt}" in
        d)
            domain=${OPTARG}
            ;;
        s)
            dns_server=${OPTARG}
            ;;
        h)
            print_help
            exit 0
            ;;
        *)
            bail "Invalid option or missing argument"
            ;;
    esac
done

shift $((OPTIND - 1)) # remove options processed by getopts, keep non-option arguments

# process arguments that getopts didn't get (or haven't been ported up into
# getopt yet)
while [[ $# -gt 0 ]]; do
    case "$1" in
        @*) dns_server=${1#*@} ; shift ;;
        *) domain=$1 ; shift ;;
    esac
done

# Ask for the domain if not provided using an option
prompt_for_domain

# Set default DNS server if not provided
dns_server=${dns_server:-$default_dns}

# Print the table with enhanced and longer separators
echo -e "\n${YELLOW}================================================================${RESET}"
printf "${CYAN}%-20s${RESET}: ${GREEN}%s${RESET}\n" "Report generated" "$(date '+%A, %B %d, %Y at %H:%M:%S %Z')"
printf "${CYAN}%-20s${RESET}: ${GREEN}${BOLD}%s${RESET}\n" "Domain Info" "$domain"
printf "${CYAN}%-20s${RESET}: ${GREEN}%s${RESET}\n" "DNS Server" "$dns_server"
echo -e "${YELLOW}================================================================${RESET}"

if command -v dig &> /dev/null && command -v whois &> /dev/null; then
  check_status_registration
elif ! command -v dig &> /dev/null && ! command -v whois &> /dev/null; then
  echo -e "${RED}Error: Commands 'dig' and 'whois' not found.${RESET}"
  echo "Install 'dig' and 'whois' before running this script."
  exit 1
elif ! command -v dig &> /dev/null; then
  echo -e "${RED}Error: Command 'dig' not found.${RESET}"
  echo "Install 'dig' before running this script."
  exit 1
else
  echo -e "${RED}Error: Command 'whois' not found.${RESET}"
  echo "Install 'whois' before running this script."
  exit 1
fi

if [ -n "$a_record" ]; then
  display_ssl_info
  echo -e "${YELLOW}================================================================${RESET}"
fi

# Check domain status if A and NS records are missing
if [ -z "$a_record" ] && [ -z "$ns_record" ]; then
  echo -e "\n${YELLOW}================================================================${RESET}"
  check_domain_status
fi
