#!/bin/bash

# domain information
# (c) 2023 Dzubayyan Ahmad
# tools for work

# ANSI color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

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

# Function to display A and PTR records
display_a-ptr_records() {
  local record_type=$1
  local ip_addresses=$2
  [ -z "${ip_addresses}" ] && printf "${RED}%4s record: -${RESET}\n" ${record_type} && return
  for ip in $ip_addresses ; do
     local ptr_info=$(dig +short -x $ip)
     if [ -z "${ptr_info}" ] ; then
        printf "${CYAN}%4s record:${RESET} %-24s \t${RED}PTR: - ${RESET}\n" ${record_type} ${ip}
    else
        printf "${CYAN}%4s record:${RESET} %-24s \t${CYAN}PTR:${RESET} %s${RESET}\n" ${record_type} ${ip} ${ptr_info}
     fi
  done
}

# Function to display SSL information
display_ssl_info() {
  local openssl_info=$(openssl s_client -showcerts -connect $domain:443 -servername $domain </dev/null 2>/dev/null | openssl x509 -noout -subject -dates -ext subjectAltName -issuer 2>/dev/null | grep -v X509v3)
  if [ $? -eq 0 ]; then
    echo -e "\n${CYAN}[SSL Information]${RESET}"
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

  echo

  mx_record=$(dig +short @$dns_server $domain MX | sort -n)
  display_records "MX" "$mx_record"

  mail_record=$(dig +noall +answer @$dns_server mail.$domain A | awk '{print $4 "\t" $5}')
  display_records "MAIL" "$mail_record"

  txt_record=$(dig +short @$dns_server $domain TXT)
  display_records "TXT" "$txt_record"

  ns_record=$(dig +short @$dns_server $domain NS)
  display_records "NS" "$ns_record"
}

# Function to print help
print_help() {
  echo ""
  echo -e "${CYAN}Usage:${RESET} $(basename "$0") ${YELLOW}[-d|--domain domain] [-s|--server dns_server] [-h|--help]${RESET}"
  echo -e "  ${YELLOW}-d, --domain domain${RESET}       Domain name to be queried"
  echo -e "  ${YELLOW}-s, --server dns_server${RESET}   Custom DNS server for A, AAAA, MX, NS, TXT records (optional)"
  echo -e "  ${YELLOW}-h, --help${RESET}                Display help information"
  echo ""
  echo -e "Example Usage:"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com${RESET}"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com -s 1.1.1.1${RESET}"
  exit 0
}

# Function to check domain status
check_domain_status() {
  local domain_status=$(whois $domain | grep "serverHold\|clientHold")

  if [[ $domain_status == *"clientHold"* ]]; then
    echo -e "\n${RED}[Domain Status]${RESET}"
    echo -e "${YELLOW}Status:${RESET} ${RED}clientHold${RESET}\n\n[Suspended by the registrar or domain provider]\n"
  elif [[ $domain_status == *"serverHold"* ]]; then
    echo -e "\n${RED}[Domain Status]${RESET}"
    echo -e "${YELLOW}Status:${RESET} ${RED}serverHold${RESET}\n\n[Suspended by the registry]\n"
  fi
}

# Function to check domain registration status
check_status_registration() {
  local domain_regist=$(whois $domain | grep -Ei "(No match for domain|DOMAIN NOT FOUND|No Data Found|Domain not found|is available|The queried object does not exist|is not registered|not been registered)")

  if [[ -n "$domain_regist" ]]; then
    echo "Domain is not registered"
  else
    display_dns_info $dns_server
  fi
}

error_flag=0  # Initialize error_flag variable

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domain)
      if [[ -n $2 ]]; then
        domain=$2
        shift 2
      else
        echo -e "${RED}Option -d|--domain requires an argument.${RESET}" >&2
        error_flag=1
        break
      fi
      ;;
    -s|--server)
      if [[ -n $2 ]]; then
        dns_server=$2
        shift 2
      else
        echo -e "${RED}Option -s|--server requires an argument.${RESET}" >&2
        error_flag=1
        break
      fi
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option: $1${RESET}" >&2
      error_flag=1
      break
      ;;
  esac
done

if [[ $error_flag -eq 1 ]]; then
  print_help
  exit 1
fi

# Ask for the domain if not provided using an option
prompt_for_domain

# Set default DNS server if not provided
dns_server=${dns_server:-$default_dns}

echo -e "\n${YELLOW}============================${RESET}"
echo -e "${CYAN}Report generated${RESET}: ${GREEN}$(date)${RESET}"
echo -e "${CYAN}Domain Info${RESET}\t: ${GREEN}$domain${RESET}"
echo -e "${CYAN}DNS Server\t${RESET}: ${GREEN}$dns_server${RESET}"
echo -e "${YELLOW}============================\n${RESET}"

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


if [ -n "$a_record" ] && [ -n "$ns_record" ]; then
  display_ssl_info
  echo -e "${YELLOW}============================\n${RESET}"
fi

# Check domain status if A and NS records are missing
if [ -z "$a_record" ] && [ -z "$ns_record" ]; then
  echo -e "\n${YELLOW}============================${RESET}"
  check_domain_status
fi
