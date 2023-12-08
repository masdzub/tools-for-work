#!/bin/bash

# Set Cloudflare authentication details
CLOUDFLARE_API_TOKEN="fill_with_your_api_token" # Replace with your Cloudflare API Token -- https://dnva.me/Z1H8daPCCg --
ACCOUNT_ID="fill_with_Cloudflare_Account_id" # Replace with your Cloudflare Account ID

# Default domain
domain=""

# Parsing options
while getopts ":d:" opt; do
  case $opt in
    d)
      domain="$OPTARG"
      ;;
    \?)
      echo "Usage: $0 -d <domain>"
      exit 1
      ;;
  esac
done

# Check if the domain is provided
if [ -z "$domain" ]; then
  echo "Domain not provided. Usage: $0 -d <domain>"
  exit 1
fi

ipv4=$(dig +short A $domain @ns1.domainesia.net)
ipv6=$(dig +short AAAA $domain @ns1.domainesia.net)
server=$(dig +short -x $ipv4)

echo -e "IP $domain at $server : $ipv4 and $ipv6 \n"

# DDOS on @server
echo -e "DDOS-on the domain $domain on thes server\n"
/usr/bin/curl $server/ddos_on?domain=$domain

# Add domain to Cloudflare
add_output=$(curl -s https://api.cloudflare.com/client/v4/zones \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  --data '{
  "account": {
    "id":"'"$ACCOUNT_ID"'"
  },
  "name": "'"$domain"'",
  "type": "full"
}')

echo $add_output | jq .

# Get domain_id from the added domain
domain_id=$(echo $add_output | jq -r .result.id)

printf "\n\n"
printf "DNS quick scanning ${domain}:\n"

# Perform DNS scan for the added domain
scan_output=$(curl -s -X POST https://api.cloudflare.com/client/v4/zones/$domain_id/dns_records/scan \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

echo $scan_output | jq .

# Set WAF to Under Attack mode for the domain
waf_output=$(curl -s -X PATCH https://api.cloudflare.com/client/v4/zones/$domain_id/settings/security_level \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  --data '{
  "value": "under_attack"
}')

echo $waf_output | jq .

# Enable Bot Fight Mode for the domain
bot_fight_output=$(curl -s -X PUT https://api.cloudflare.com/client/v4/zones/$domain_id/bot_management \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  --data '{
    "fight_mode": true
  }')

echo $bot_fight_output | jq .

# Make a GET request to fetch zone details
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

# Check the response
zone_identifier=$(echo "$response" | jq -r '.result[0].id')
echo -e "Zone Identifier for $domain is: $zone_identifier \n"

# Make API call to set firewall rules block country
block_country=$(curl -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/firewall/rules" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    --data '[{
    "action": "block",
    "description": "block country",
    "priority": 50,
    "filter": {
        "description": "block country",
        "expression": "(not ip.geoip.country in {\"ID\"} and ip.geoip.country in {\"CA\" \"CN\" \"IE\" \"NL\" \"RO\" \"RU\" \"TT\" \"GB\" \"US\"} and not ip.geoip.asnum in {32934 394699 15169 22577} and not ip.src in {'$ipv4' '$ipv6'})",
        "paused": false
    }
}]')

echo -e "Set Firewall Rules for Block Country : $block_country"

# Make API call to set firewall rules challenge_id
challenge_id=$(curl -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/firewall/rules" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    --data '[{
    "action": "challenge",
    "description": "challenge from ID SG",
    "priority": 40,
    "filter": {
        "description": "challange from ID SG",
        "expression": "(ip.geoip.country in {\"ID\" \"SG\"} and not ip.src in {'$ipv4' '$ipv6'})",
        "paused": false
    }
}]')

echo -e "Set Firewall Rules for Challange ID: $challenge_id"

# Make API call to set firewall rules only_id
only_id=$(curl -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/firewall/rules" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    --data '[{
    "action": "block",
    "description": "only ID SG",
    "priority": 60,
    "filter": {
        "description": "only ID SG",
        "expression": "(ip.geoip.country ne \"ID\" and not ip.geoip.asnum in {32934 394699 15169 22577} and not ip.src in {'$ipv4' '$ipv6'})",
        "paused": false
    }
}]')

echo -e "Set Firewall Rules for Challange ID: $only_id"

echo -e "\n\n --- Wes rampung sing masang rule, lak di ganti NS domain ---\n\n"
echo -e "\n dora.ns.cloudflare.com"
echo -e "\n jasper.ns.cloudflare.com"
