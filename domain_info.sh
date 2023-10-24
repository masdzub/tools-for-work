#!/bin/bash

# ANSI color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# Default DNS server for A, AAAA, MX, NS, TXT records
default_dns="8.8.8.8"

# Function to prompt for domain if not provided
prompt_for_domain() {
  if [ -z "$domain" ]; then
    read -p "Masukkan nama domain: " domain
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
    echo -e "${RED}$record_type record : - ${RESET}"
  fi
}

# Function to display PTR records
display_ptr_records() {
  local ip_address=$1
  local ptr_info=$(dig +short -x $ip_address)
  display_records "PTR" "$ptr_info"
}

# Function to display SSL information
display_ssl_info() {
  local openssl_info=$(openssl s_client -showcerts -connect $domain:443 </dev/null 2>/dev/null | openssl x509 -noout -issuer -dates -subject)
  if [ $? -eq 0 ]; then
    echo -e "\n${CYAN}[Informasi SSL]${RESET}"
    echo "$openssl_info" | sed 's/^/  /'
  else
    echo -e "${RED}Tidak ada informasi SSL yang tersedia atau tidak dapat dibaca untuk $domain pada port 443.${RESET}"
  fi
}

# Function to display DNS information
display_dns_info() {
  local dns_server=$1

  a_record=$(dig +short @$dns_server $domain A)
  display_records "A" "$a_record"

  aaaa_record=$(dig +short @$dns_server $domain AAAA)
  display_records "AAAA" "$aaaa_record"

  mx_record=$(dig +short @$dns_server $domain MX)
  display_records "MX" "$mx_record"

  # Display TXT Record
  txt_record=$(dig +short @$dns_server $domain TXT)
  display_records "TXT" "$txt_record"

  ns_record=$(dig +short @$dns_server $domain NS)
  display_records "NS" "$ns_record"

  if [ -n "$a_record" ]; then
    echo -e "\n${CYAN}[Informasi PTR untuk IPv4]${RESET}"
    display_ptr_records "$a_record"
  fi

  if [ -n "$aaaa_record" ]; then
    echo -e "\n${CYAN}[Informasi PTR untuk IPv6]${RESET}"
    display_ptr_records "$aaaa_record"
  fi
}

# Function to print help
print_help() {
  echo -e "${CYAN}Usage:${RESET} $(basename "$0") ${YELLOW}[-d|--domain domain] [-s|--server dns_server] [-h|--help]${RESET}"
  echo -e "  ${YELLOW}-d, --domain domain${RESET}       Nama domain yang akan diquery"
  echo -e "  ${YELLOW}-s, --server dns_server${RESET}   DNS server kustom untuk A, AAAA, MX, NS, TXT records (opsional)"
  echo -e "  ${YELLOW}-h, --help${RESET}                Menampilkan informasi bantuan"
  echo ""
  echo -e "Contoh Penggunaan:"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com${RESET}"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com -s 1.1.1.1${RESET}"
  exit 0
}

# Function to check domain status
check_domain_status() {
  local domain_status=$(whois $domain | grep "serverHold\|clientHold")

  if [[ $domain_status == *"clientHold"* ]]; then
    echo -e "\n${RED}[Status Domain]${RESET}"
    echo -e "${YELLOW}Status:${RESET} ${RED}clientHold${RESET}\n\n[Ditangguhkan oleh registrar atau penyedia domain]\n"
  elif [[ $domain_status == *"serverHold"* ]]; then
    echo -e "\n${RED}[Status Domain]${RESET}"
    echo -e "${YELLOW}Status:${RESET} ${RED}serverHold${RESET}\n\n[Ditangguhkan oleh registry]\n"
  fi
}

# Function to check domain status registration
check_status_registration() {
  local domain_regist=$(whois $domain | grep -Ei "(No match for domain|DOMAIN NOT FOUND|No Data Found|Domain not found|is available|The queried object does not exist|is not registered|not been registered)")

  if [[ -n "$domain_regist" ]]; then
    echo "Domain belum terdaftar"
  else
    display_dns_info $dns_server
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domain)
      domain=$2
      shift 2
      ;;
    -s|--server)
      dns_server=$2
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Pilihan yang tidak valid: $1${RESET}" >&2
      print_help
      exit 1
      ;;
  esac
done

prompt_for_domain

# Set default DNS server if not provided
dns_server=${dns_server:-$default_dns}

echo -e "\n${YELLOW}============================${RESET}"
echo -e "${CYAN}Domain Info${RESET}\t: ${GREEN}$domain${RESET}"
echo -e "${CYAN}DNS Server\t:${RESET} ${GREEN}$dns_server${RESET}"
echo -e "${YELLOW}============================\n${RESET}"

if command -v dig &> /dev/null && command -v whois &> /dev/null; then
  check_status_registration
elif ! command -v dig &> /dev/null && ! command -v whois &> /dev/null; then
  echo -e "${RED}Error: Perintah 'dig' dan 'whois' tidak ditemukan.${RESET}"
  echo "Instal 'dig' dan 'whois' terlebih dahulu sebelum menjalankan skrip ini."
elif ! command -v dig &> /dev/null; then
  echo -e "${RED}Error: Perintah 'dig' tidak ditemukan.${RESET}"
  echo "Instal 'dig' terlebih dahulu sebelum menjalankan skrip ini."
else
  echo -e "${RED}Error: Perintah 'whois' tidak ditemukan.${RESET}"
  echo "Instal 'whois' terlebih dahulu sebelum menjalankan skrip ini."
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
