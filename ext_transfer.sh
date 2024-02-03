#!/usr/bin/bash

# Transfer Tools From External

## set -x

RED=$(tput bold; tput setaf 1)
BLUE=$(tput bold; tput setaf 4)
GREEN=$(tput bold; tput setaf 2)
YELLOW=$(tput bold; tput setaf 3)
PURPLE=$(tput bold; tput setaf 5)
ENDCOLOR=$(tput sgr0)

clear
echo -e "${PURPLE}-----------------------------------"
echo -e "===| Migration Tools cPanel Server |==="
echo -e "-----------------------------------${ENDCOLOR}\n\n"

# Check if file exists
if [ ! -f $HOME/.who ]; then
    echo "Nama Agent : "
    read who
    echo "$who" > $HOME/.who
else
    who=$(cat $HOME/.who)
fi

reason_why() {
    # Display options for migration reasons
    echo "${BLUE}Choose a migration reason:${ENDCOLOR}"
    echo "${YELLOW}1.${ENDCOLOR} From Outside"
    echo "${YELLOW}2.${ENDCOLOR} Restore Terminate Hosting"

    # Read user input for the migration reason choice
    read -p "${GREEN}Enter the number of your migration reason choice: ${ENDCOLOR}" choice

    case $choice in
        1) 
            reason="From Outside"
            ;;
        2) 
            reason="Restore Terminate Hosting"
            ;;
        *) 
            # Display an error message for an invalid choice and restart the function
            echo "${RED}Error: Invalid choice. Please select a number from 1 to 2.${ENDCOLOR}"
            reason_why # Restart the function to begin from the start
            return
            ;;
    esac

    # Display the selected migration reason
    echo -e "\n${BLUE}Selected migration reason:${ENDCOLOR} ${YELLOW}$reason${ENDCOLOR}"
}
timestart(){
    # timestamp start
    timestart=$(date)
    timestart_formated=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}$timestart${ENDCOLOR}"
}
timefinish(){
    #timestap finish
    timefinish=$(date)
    timefinish_formated=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}$timefinish${ENDCOLOR}"
}


## Define Variable
slack_url=
slack_url_failed=
whmcs_url=https://panel.masdzub.com/admin/index.php?rp=/admin

timestart
echo -e "${PURPLE}\n===| Asking the reason ${ENDCOLOR}\n"
reason_why


echo -e "${PURPLE}\n===| Asking the URL ${ENDCOLOR}\n"
read -p "Enter URL backup : " url_backup
echo ""

echo -e "${PURPLE}\n===| Get Information From URL ${ENDCOLOR}\n"

# Extract the filename from the URL
filename=$(basename "$url_backup")
echo -e "Nama File : $filename"

get_username() {
    # Pola regex untuk mengekstrak nama USER
    patterns=(
        "cpmove-(.*?)\.tar\.gz"
        "cpmove-(.*?)\.tar"
        "_([[:alnum:]]+)\.tar\.gz$"
        "_([[:alnum:]]+)\.tar$"
        "(.+)\.tar\.gz$"
        "(.+)\.tar$"
    )

    for pattern in "${patterns[@]}"; do
        if [[ $filename =~ $pattern ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done

    return 1
}

username=$(get_username "$filename")
echo -e "Username : $username"

echo -e "${PURPLE}\n===| Asking the destination server ${ENDCOLOR}\n"

# input destination server
echo ""
read -p "Enter the destination server (e.g. cpanel_server): " destination_server
echo ""

# validate SSH connection to destination server
echo -e "\nValidating SSH connection to $destination_server.."
ssh -l root $destination_server exit >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Failed to establish SSH connection to destionation server."
    exit 1
fi
echo -e "SSH connection to destionation server successful.\n"

echo -e "${PURPLE}\n===| Progress restoration / migration ${ENDCOLOR}\n"

ssh -l root $destination_server "grep -w -q $username /etc/trueuserdomains"
if [ $? -eq 0 ]; then
    echo -e "\nUser found on the destination server."
    exit 1
else
    # download backup
    ssh -l root $destination_server "wget -c --no-check-certificate --progress=bar:force $url_backup -P /web"
    echo -e "\nBackup downloaded successfully."
    # Restore from the URL using /script/restorepkg
    ssh -l root $destination_server "/scripts/restorepkg --force /web/$filename"
    if [ $? -eq 0 ]; then
        echo -e "\nRestoration completed successfully."
        echo -e "\nOpen username into browser at WHMCS."
        xdg-open "$whmcs_url/services&username=$username"
        timefinish
        migration=success
    else
        echo -e "\nFailed to restore backup."
        # Send failure notification to Slack
        #curl -X POST -H 'Content-type: application/json' --data "" $slack_url_failed
        migration=failed
        exit 1
    fi
fi

# Duration
start_epoch=$(date -d "$timestart_formated" +%s)
end_epoch=$(date -d "$timefinish_formated" +%s)
duration_seconds=$((end_epoch - start_epoch))

# Calculate hours, minutes, and seconds
hours=$((duration_seconds / 3600))
minutes=$(( (duration_seconds % 3600) / 60 ))
seconds=$((duration_seconds % 60))

if [ "$hours" -gt 0 ]; then
duration_formatted=$(printf "%02d hours %02d minutes %02d seconds" "$hours" "$minutes" "$seconds")
else
duration_formatted=$(printf "%02d minutes %02d seconds" "$minutes" "$seconds")
fi

# Summary Success
summary_success() {
cat <<EOF
{
  "who": "$who",
  "username": "$username",
  "url_backup": "$url_backup",
  "new_server": "$destination_server",
  "reason": "$reason",
  "timestart": "$timestart",
  "timefinish": "$timefinish",
  "duration": "$duration_formatted"
}
EOF
}

backup(){
    echo -e "Copying $filename into /sharedfs/support/\n"
    ssh -l root  $destination_server "rsync --no-owner -Paz /web/$filename /sharedfs/support/$filename"
    ssh -l root  $destination_server "rm -f /web/$filename"
}

if [ "$migration" = "success" ]; then
    echo -e "${PURPLE}\n===| Change The reseller / owner into Root ${ENDCOLOR}\n"
    ssh -l root $destination_server "/usr/sbin/whmapi1 modifyacct --output=jsonpretty user='$username' owner=root" | /usr/bin/jq '{metadata: .metadata, messages: .metadata.output.messages}'

    echo -e "${PURPLE}\n===| Send Notification to Slack ${ENDCOLOR}\n"
    curl -X POST -H 'Content-type: application/json' --data "$(summary_success)" $slack_url | jq
    
    echo -e "${PURPLE}\n===| Backup in progress.. ${ENDCOLOR}\n"
    backup
else
    echo -e "Migration failed"
    #curl -X POST -H 'Content-type: application/json' --data "" $slack_url_failed
    exit 1
fi