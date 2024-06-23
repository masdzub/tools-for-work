#!/bin/bash
# anti-flood script
# Example usage: ./log_flood_block.sh /home/portalwakatobika/access-logs/portal.wakatobikab.go.id-ssl_log
# the script will:
# - filter out any CloudFlare owned IPs and any IPs already present in /etc/csf/csf.deny
# - anything else from that log file will be added to /etc/csf/csf.deny
# - the access-log logfile will be truncated afterwards so the script don't have to process the same IPs again
# - all IPs listed by LiteSpeed (in the /tmp/lshttpd/.rtreport* files under the BLOCKED_IP section) will be blocked,
#   excluding CloudFlare IPs and IPs that are already blocked
# - it runs in a loop with 30 seconds pause per round until stopped
#
# 19-11-2023 lukasz@worldhost.group
##
log_file=$1

bin_grepcidr=$(which grepcidr)
if [[ ! -x ${bin_grepcidr} ]]; then
        echo "grepcidr missing, try: yum install grepcidr (epel)"
        exit 1
fi

is_ipset=$(egrep "^LF_IPSET(=|\s)" /etc/csf/csf.conf|sed 's/"//g'|awk '{print $NF}'|cut -d'=' -f2)
if [[ ! ${is_ipset} -eq 1 ]]; then
        echo "error: LF_IPSET must be enabled in /etc/csf/csf.conf and DENY_IP_LIMIT adjusted."
        exit 1
fi

# parse httpd log file, ban any non-cloudflare IPs
function log_parse_and_ban() {
        csf_blocked=$(grep "^[1-9]" /etc/csf/csf.deny|awk '{print $1}'|grep ':' -v)
        for cur_logline in $(awk '{print $1}' ${log_file} |sort|uniq|egrep -v '(:|127.0.0)'); do
#               echo "processing ${cur_logline}"
                is_cf=$(${bin_grepcidr} 1>/dev/null -f /root/cf_ips.txt <<<${cur_logline};echo $?)
                if [[ ${is_cf} -eq 0 ]]; then
                        echo "${cur_logline} skipped, CloudFlare IP"
                  else
#                       echo -n "checking if ${cur_logline} is already in csf.deny: "
                        is_csf_blocked=$(egrep -q "^${cur_logline}$" <<<"${csf_blocked}";echo $?)
                        if [[ ${is_csf_blocked} -eq 0 ]]; then
                                echo "${cur_logline} already blocked, skipped"
                          else
                                new_block=1
                                echo "${cur_logline} # log_flood_block.sh: $(date)" >>/etc/csf/csf.deny
                                echo "${cur_logline} blocked"
                        fi
                fi
        done
        # flush log file to avoid processing the same IPs
        >${log_file}
}

# parse litespeed rtreport files - BLOCKED_IP section and block as well
function rtreport_parse_and_ban() {
        csf_blocked=$(grep "^[1-9]" /etc/csf/csf.deny|awk '{print $1}'|grep ':' -v)
        for cur_rtreport in $(find /tmp/lshttpd/.rtreport*); do

                while read -r cur_ip; do
#                       echo "debug: cur_ip: ${cur_ip}"
                        is_cf=$(${bin_grepcidr} 1>/dev/null -f /root/cf_ips.txt <<<${cur_ip};echo $?)
                        if [[ ${is_cf} -eq 0 ]]; then
                                echo "${cur_ip} skipped, CloudFlare IP"
                        fi
#                       echo -n "checking if ${cur_ip} is already in csf.deny: "
                        is_csf_blocked=$(egrep -q "^${cur_ip}$" <<<"${csf_blocked}";echo $?)
                        if [[ ${is_csf_blocked} -eq 0 ]]; then
                                echo "${cur_ip} already blocked, skipped"
                          else
                                new_block=1
                                echo "${cur_ip} # log_flood_block.sh - lsws rtreport: $(date)" >>/etc/csf/csf.deny
                                echo "${cur_ip} blocked"
                        fi
                done <<< "$(grep BLOCKED_IP ${cur_rtreport}|awk '{print $2}'|sed 's/;[A-Z]/\n/g'|sed 's/,//g'|grep "^[1-9]"|sort)"

        done
}

##main
# get cloudflare ips
curl -s https://www.cloudflare.com/ips-v4 >/root/cf_ips.txt

while [ -true ]; do
        new_block=0
        log_parse_and_ban
        echo "--- rtreport:"
#       rtreport_parse_and_ban
        if [[ ${new_block} -eq 1 ]]; then
                csf -r
        fi
        echo -e "\nsleeping 30s..\n"
        sleep 30
done