#!/bin/bash

# Example email.txt

# FORMAT : 
# <email> <password> <SRC_SERVER> <DST_SERVER> #
# user1@example.com pass1 imap.oldserver.com imap.newserver.com
# user2@example.com pass2 mail.a mail.b

EMAIL_FILE="email.txt"

# Ensure the email file exists
if [[ ! -f "$EMAIL_FILE" ]]; then
    echo "❌ Error: $EMAIL_FILE not found."
    exit 1
fi

# Check if imapsync is installed
if ! command -v imapsync &>/dev/null; then
    echo "❌ Error: imapsync is not installed."
    exit 1
fi

# Spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid &>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
}

# Process each line
while IFS=' ' read -r email password src_server dst_server; do
    if [[ -n "$email" && -n "$password" && -n "$src_server" && -n "$dst_server" ]]; then
        echo -n "🔄 Processing $email from $src_server to $dst_server..."

        # Start imapsync in background
        imapsync \
            --host1 "$src_server" --user1 "$email" --password1 "$password" \
            --host2 "$dst_server" --user2 "$email" --password2 "$password" \
            --ssl1 --ssl2 \
            --automap --syncinternaldates --skipsize > /dev/null 2>&1 &

        pid=$!
        spinner $pid
        wait $pid

        if [[ $? -eq 0 ]]; then
            echo " ✅ Done syncing $email"
        else
            echo " ❌ Failed syncing $email"
        fi
        echo "------------------------------------------"
    else
        echo "⚠️ Skipping invalid line: $email $password $src_server $dst_server"
    fi
done < "$EMAIL_FILE"
