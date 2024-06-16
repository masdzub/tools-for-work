#!/bin/bash

# Function to display usage information
display_usage() {
    echo "Usage: $0 <reseller> <mail|non-mail>"
    echo "  <reseller>: Specify the reseller name."
    echo "  <mail|non-mail>: Specify whether to calculate 'mail' or 'non-mail' usage."
    echo "Example: $0 myreseller mail"
}

# Check if arguments are provided
if [[ $# -ne 2 ]]; then
    display_usage
    exit 1
fi

reseller="$1"
type="$2"

if [[ ! "${type}" = "mail" && ! "${type}" = "non-mail" ]]; then
    display_usage
    exit 1
fi

echo "gathering ${type} usage for ${reseller}.."

# Gather accounts owned by reseller
grep "\s${reseller}$" /etc/trueuserowners | cut -d':' -f1 > accts

# Validate owner of each account
echo -n "validating account owner: "
err_cnt=0
while IFS= read -r cur_acct; do
    cp_owner=$(grep "^OWNER=" "/var/cpanel/users/${cur_acct}" | cut -d'=' -f2)
    if [[ "${reseller}" = "${cp_owner}" ]]; then
        echo -n "+"
    else
        echo -e "failed:\naccount ${cur_acct}, owner mismatch: ${cp_owner}"
        let err_cnt++
    fi
done < accts

if [[ ${err_cnt} -gt 0 ]]; then
    echo "fatal: owner mismatch, exiting"
    exit 1
fi

echo

# Calculate usage for each account
> tmp_calc
while IFS= read -r i; do
    homedir=$(grep "^${i}:" /etc/passwd | cut -d':' -f6)
    for d in $(find "${homedir}" -mindepth 0 -maxdepth 0 -type d -not -type l); do
        echo -en "checking account ${i}\033[0K\r"
        if [[ "${type}" = "mail" ]]; then
            cur_size=$(du -sm "${d}/mail" 2>/dev/null)
        else
            cur_size=$(du -sm --exclude=mail "${d}"/* 2>/dev/null)
        fi
        if [[ -z ${cur_size} ]]; then
            break
        fi
        echo "${cur_size}" >> tmp_calc
    done
done < accts

echo

# Display results larger than 10M
awk '$1 >= 10 {print $0}' tmp_calc | sort -n

# Calculate total usage in GB
sz=$(awk '{ sum += $1 } END { printf "%.3f", sum / 1024 }' tmp_calc)
echo "total ${type} usage for accounts under reseller ${reseller}: ${sz} GB (output above doesn't include results smaller than 10M)"

rm -f tmp_calc
