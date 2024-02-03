#!/usr/bin/bash

# Transfer Tools 
# (c) 2023 

## set -x

# Check if file exists
if [ ! -f $HOME/.who ]; then
    echo "Nama Agent : "
    read who
    echo "$who" > $HOME/.who
else
    who=$(cat $HOME/.who)
fi

RED=$(tput bold; tput setaf 1)
BLUE=$(tput bold; tput setaf 4)
GREEN=$(tput bold; tput setaf 2)
YELLOW=$(tput bold; tput setaf 3)
PURPLE=$(tput bold; tput setaf 5)
ENDCOLOR=$(tput sgr0)

clear
echo -e "${PURPLE}-----------------------------------"
echo -e "===| Migration Tools |==="
echo -e "-----------------------------------${ENDCOLOR}\n\n"

reason_why() {
    # Display options for migration reasons
    echo "${BLUE}Choose a migration reason:${ENDCOLOR}"
    echo "${YELLOW}1.${ENDCOLOR} Upgrade (3.0/CH)"
    echo "${YELLOW}2.${ENDCOLOR} Customer Request"
    echo "${YELLOW}3.${ENDCOLOR} Resource Balancing"
    echo "${YELLOW}4.${ENDCOLOR} Abuse Migration"
    echo "${YELLOW}5.${ENDCOLOR} Other"

    # Read user input for the migration reason choice
    read -p "${GREEN}Enter the number of your migration reason choice: ${ENDCOLOR}" choice

    case $choice in
        1) 
            reason="Upgrade (3.0/CH)"
            ;;
        2) 
            reason="Customer Request"
            ;;
        3) 
            reason="Resource Balancing"
            ;;
        4) 
            reason="Abuse Migration"
            ;;
        5) 
            # If 'Other' is chosen, prompt the user to input their custom reason
            read -p "${GREEN}Please specify another reason: ${ENDCOLOR}" custom_reason
            if [ -z "$custom_reason" ]; then
                # Check if the custom reason is empty; if so, display an error message and restart the function
                echo "${RED}Error: Reason cannot be empty. Please try again.${ENDCOLOR}"
                reason_why # Restart the function to begin from the start
                return
            fi
            reason="Other: $custom_reason"
            ;;
        *) 
            # Display an error message for an invalid choice and restart the function
            echo "${RED}Error: Invalid choice. Please select a number from 1 to 5.${ENDCOLOR}"
            reason_why # Restart the function to begin from the start
            return
            ;;
    esac

    # Display the selected migration reason
    echo -e "\n${BLUE}Selected migration reason:${ENDCOLOR} ${YELLOW}$reason${ENDCOLOR}"
}

# Start the reason_why function
reason_why

# input source server
echo ""
read -p "Enter the source server (make sure cPanel Server): " source_server
echo ""

# validate SSH connection to source server
echo -e "\nValidating SSH connection to $source_server.."
ssh -l root $source_server exit >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "${PURPLE}Failed to establish SSH connection to source server.${ENDCOLOR}"
    exit 1
fi
echo -e "${GREEN}SSH connection to source server successful.${ENDCOLOR}\n"

# input destination server
echo ""
read -p "Enter the destination server (make sure cPanel Serverm): " destination_server
echo ""
# validate SSH connection to destination server
echo -e "\nValidating SSH connection to $destination_server.."
ssh -l root $destination_server exit >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "${PURPLE}Failed to establish SSH connection to destionation server.${ENDCOLOR}"
    exit 1
fi
echo -e "${GREEN}SSH connection to destionation server successful.${ENDCOLOR}\n"

# input username
read -p  "Enter the cPanel username: " username

## Define Variable
slack_url=
slack_url_failed=
SLACK_API_TOKEN=
CHANNEL_ID=
whmcs_url=https://panel.masdzub.com/admin/index.php?rp=/admin
REMINDER_TEXT="ssh -l root $source_server '/scripts/removeacct --keepdns $username --force'"


# Get the current timestamp and add 1 hour (3600 seconds) to it for the reminder time
# 32H
REMINDER_TIME=$(($(date +'%s') + 115200))
REMINDER_TIME_15=$(($(date +'%s') + 54000))

# timestamp start
timestart=$(date)
timestart_formated=$(date +"%Y-%m-%d %H:%M:%S")
        
# create hash
hashmig=$(echo "$username" | md5sum | awk '{print $1}')

# check user at this server
echo -e "\n${RED}==| User Status${ENDCOLOR}"

# check size of backup on source server
quota_output=$(ssh -l root $source_server "cat /home/$username/.cpanel/datastore/_Cpanel::Quota.pm__$username| jq '.data[0]'")

result=$(echo "scale=2; $quota_output / 1073741824" | bc)

if (( $(echo "$result < 1" | bc -l) )); then
    result_mb=$(echo "scale=2; $result * 1024" | bc)
    disk_usage=$(echo $result_mb MB)
    echo "Ukuran $result_mb MB"
else
    disk_usage=$(echo $result GB)
    echo "Ukuran $result GB"
fi



migrating_process() {
    # check user is suspend ?
    echo -e "\nChecking account suspension status.."
    ssh -l root $source_server "grep -q "^SUSPENDED=1" /var/cpanel/users/$username"
    if [ $? -eq 0 ]; then
        echo "The account is suspended."
    else
        read -p "The account is not suspended, do you want to suspend it before migrating? (y/n) "  suspend_choice
        if [ $suspend_choice == "y" ]; then
            ssh -l root $source_server "/scripts/suspendacct $username"
            if [ $? -eq 0 ]; then
                echo -e "\n\nThe account has been successfully suspended."
            else
                echo -e "\n\nAn error occurred while suspending the account."
                exit 1
            fi
        fi
    fi
    
    # create backup file to source server
    echo -e "\n${RED}==| Create Backup File at $source_server..\n${ENDCOLOR}"

    ssh -l root $source_server "/scripts/pkgacct $username /var/www/html/"
    if [ $? -eq 0 ]; then
        echo "The account has been successfully backed up."

        # rename during transfer
        ssh -l root $source_server "mv /var/www/html/cpmove-$username.tar.gz /var/www/html/cpmove-$username$hashmig.tar.gz"

        # give permission to download
        ssh -l root $source_server "chmod 644 /var/www/html/cpmove-$username$hashmig.tar.gz"
    else
        echo -e "\n\nAn error occurred while creating the backup."
        exit 1
    fi
}

restore_process() {
    # download file backup into destination server
    echo -e "\n${BLUE}==| Downloading File Backup at $destination_server..\n${ENDCOLOR}"

    ssh -l root $destination_server "wget -c -6 --no-check-certificate --progress=bar:force http://$source_server/cpmove-$username$hashmig.tar.gz -P /web"

    # rename during restore
    ssh -l root  $destination_server "mv -fv /web/cpmove-$username$hashmig.tar.gz /web/cpmove-$username.tar.gz"

    if [ $? -eq 0 ]; then
        echo -e "\n\nThe backup has been successfully downloaded on the destination server."
    else
        echo -e "\n\nAn error occurred while downloading the backup on the destination server."
        exit 1
    fi

    # restore file backup into destination server
    echo -e "\n${BLUE}==| Restore File Backup at $destination_server..\n${ENDCOLOR}"

    ssh -l root $destination_server "/scripts/restorepkg /web/cpmove-$username.tar.gz"
    if [ $? -eq 0 ]; then
        echo -e "\n\nThe backup has been restored on the destination server."
    else
        echo -e "\n\nAn error occurred while restoring the backup on the destination server."
        exit 1
    fi

}

post_migration() {

    # change detail hosting at WHMCS
    echo -e "\n${YELLOW}==| Change Detail at WHMCS\n${ENDCOLOR}"

    xdg-open "$whmcs_url/services&username=$username"
}

backup_migration() {
    # move file backup from source server to /sharedfs/support
    echo -e "\n${RED}==| Move File Backup to /sharedfs/support..\n${ENDCOLOR}"

    ssh -l root  $source_server "rsync --no-owner -Paz /var/www/html/cpmove-$username$hashmig.tar.gz /sharedfs/support/cpmove-$username.tar.gz"
    
    if [ $? -eq 0 ]; then
        echo -e "\n\nThe backup file has been moved to /sharedfs/support."
    else
        echo -e "\n\nAn error occurred while moving the backup file."
    fi

    # delete file backup from source server `/var/www/html`
    echo -e "\n${RED}==| Delete File Backup /var/www/html/..\n${ENDCOLOR}"

    ssh -l root $source_server "rm -fv /var/www/html/cpmove-$username$hashmig.tar.gz"

    if [ $? -eq 0 ]; then
        echo -e "\n\nThe backup file has been deleted."
    else
        echo -e "\n\nAn error occurred while delete the backup file."
    fi

    # delete file backup from destination server
    echo -e "\n${BLUE}==| Delete File Backup from /web..\n${ENDCOLOR}"

    ssh -l root  $destination_server "rm -fv /web/cpmove-$username.tar.gz"
    if [ $? -eq 0 ]; then
        echo -e "\n\nThe backup file has been deleted."
    else
        echo -e "\n\nAn error occurred while deleting the backup file from the destination server."
    fi
}

unsuspend(){
    # Unsuspend user
    echo -e "\n${YELLOW}==| Unsuspend User\n${ENDCOLOR}"
    read -p "Do you want to unsuspend user (y/n)? : " unsuspend_choice
    if [ $unsuspend_choice == "y" ]; then
        ssh -l root $destination_server "/scripts/unsuspendacct $username"
        if [ $? -eq 0 ]; then
            echo -e "\n\nThe account has been successfully unsuspended."
        else
            echo -e "\n\nAn error occurred while unsuspending the account."
        fi
    fi
}

ssh -l root $source_server "grep -q $username /etc/trueuserdomains"
if [ $? -eq 0 ]; then
    echo -e "\nUser found on the source server."
    
    migrating_process

    restore_process

    post_migration

    #timestap finish
    timefinish=$(date)
    timefinish_formated=$(date +"%Y-%m-%d %H:%M:%S")


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
    
    migrasi="success"
    echo " "
    echo " "
else
    echo -e "\nThe account does not exist.\n\n"
    migrasi="failed"
fi

# Summary Success
summary_success() {
cat <<EOF
{
  "username": "$username",
  "old_server": "$source_server",
  "reason": "$reason",
  "who": "$who",
  "time_start": "$timestart",
  "time_finish": "$timefinish",
  "duration": "$duration_formatted",
  "new_server": "$destination_server",
  "size": "$disk_usage"
}
EOF
}

# Summary Failed
summary_failed(){
cat <<EOF
{
  "who": "$who",
  "username": "$username",
  "old_server": "$source_server",
  "reason": "$reason"
}
EOF
}

# reminder
reminder_set(){
# Create the JSON payload for the reminder
payload='{
  "text": "'"$REMINDER_TEXT"'",
  "time": '"$REMINDER_TIME"',
  "channel": "'"$CHANNEL_ID"'",
  "creator": "'"$who"'",

}'
# Make the API request to create the reminder
curl -X POST -H "Content-type: application/json" -H "Authorization: Bearer $SLACK_API_TOKEN" -d "$payload" https://slack.com/api/reminders.add
}

# reminder for resource balance
reminder_set_15(){
# Create the JSON payload for the reminder
payload='{
  "text": "'"$REMINDER_TEXT"'",
  "time": '"$REMINDER_TIME_15"',
  "channel": "'"$CHANNEL_ID"'",
  "creator": "'"$who"'",

}'

# Make the API request to create the reminder
curl -X POST -H "Content-type: application/json" -H "Authorization: Bearer $SLACK_API_TOKEN" -d "$payload" https://slack.com/api/reminders.add
}

notif_success(){
    echo -e "Sending summary to Slack"
    curl -X POST -H 'Content-type: application/json' --data "$(summary_success)" $slack_url
}

notif_gagal(){
    echo -e "Sending summary to Slack"
    curl -X POST -H 'Content-type: application/json' --data "$(summary_failed)" $slack_url_failed
}

if [ "$migrasi" = "success" ]; then
    echo "Migration Success, $who"
    notif_success

    if [ "$choice" = 3 ]; then
        reminder_set_15
    else
        reminder_set
    fi

    unsuspend
    
    # Call backup migration
    backup_migration
elif [ "$migrasi" = "failed" ]; then
    echo "Migration Failed"
    notif_gagal
else
    echo "Status migrasi tidak dikenali."
fi
