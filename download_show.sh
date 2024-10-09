#!/bin/bash
VIDEO_ID=
DOWNLOAD_DIR=$(dirname "$(readlink -f "$0")")
SOURCE_URL=
URL="$SOURCE_URL?ac=videolist&ids=$VIDEO_ID"
TELEGRAM_URL=
VIDEO_NAME=
if [ -z "$VIDEO_ID" ]; then
    echo "沒有提供影片Ids"
    exit 1
fi
echo $VIDEO_ID
echo $DOWNLOAD_DIR

#init
FOUND=false

# 檢查檔名是否存在
check_filename() {
    target="$1"
    FOUND=false
    for file in *.mkv *.mp4; do
        if [[ "$file" == *$target* ]]; then
            FOUND=true
            return
        fi
    done
}

#處理m3u8
m3u8_trans() {
    m3u8_url=$1
    file_name=$2
    wget -O "$2.tm" $m3u8_url
    rm -rf "$2.m"

    url_ts=$(echo $m3u8_url | sed -E 's/(https:\/\/[^\/]+\/[^\/]+\/[^\/]+\/[^\/]+\/).*/\1/')
    echo -e $url_ts

    # init
    temp_storage=""
    write_mode=true
    last_extinf=""
    not_write=false
    maybe_no_write=true
    split_ext=false
    while IFS= read -r line; do
        # 检查是否遇到 #EXT-X-DISCONTINUITY
        if [[ "$line" == "#EXT-X-DISCONTINUITY" ]]; then
            if $write_mode; then
                write_mode=false
            else
                if ! $not_write; then
                    temp_storage="${temp_storage%\\n}"
                    echo -n "$temp_storage" >>"$2.m"
                fi
                temp_storage=""
                maybe_no_write=true
                not_write=false
            fi
            split_ext=true
        elif [[ "$line" == \#EXTINF:* ]] && ! $write_mode && ! $not_write ; then
            # 检查是否有 #EXTINF:3.366667
            if [[ "$line" == "#EXTINF:3.366667," ]]; then
                not_write=true
                split_ext=false
                continue
            fi

            #get EXTINF time
            time_value=$(echo "$line" | grep -oP '(?<=#EXTINF:)\d+\.\d+')
            if [ "$time_value" != "$last_extinf" ] && $split_ext; then
                last_extinf="$time_value"
                split_ext=false
            elif [ "$time_value" != "$last_extinf" ]; then
                maybe_no_write=false
                not_write=false
            elif [ "$time_value" == "$last_extinf" ] && $maybe_no_write; then
                not_write=true
            fi
            temp_storage+="$line"$'\n'
        else
            if [[ $line == *".ts" && $line != http* ]]; then
                line=$url_ts$line
    	    fi
            if $write_mode; then
                echo "$line" >>"$2.m"
            else
                temp_storage+="$line"$'\n'
            fi
        fi
    done <"$2.tm"
    if [ -n "$temp_storage" ]; then
        echo -n "$temp_storage" >>"$2.m"
    fi
    #rm -rf "$2.tm"

}


#正式下載檔案
download_video() {
    local url="$1"
    check_filename $2
    if $FOUND; then
        return
    fi
    check_filename $3
    if $FOUND; then
        return
    fi

    m3u8_trans $url $3

    DOWNLOAD_FILE="$DOWNLOAD_DIR/$3.mkv"
    trap 'if [ -f "$DOWNLOAD_FILE" ]; then rm -rf "$DOWNLOAD_FILE"; curl --location "$TELEGRAM_URL/sendMessage" --header "Content-Type: application/json" --data "{\"chat_id\":\"894882582\",\"text\":\"$VIDEO_NAME $3 download failed\"}"; fi' ERR
    ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i "$3.m" -c:v hevc_nvenc -cq 23 -preset p7 -rc vbr -maxrate 10M -c:a copy -c:s copy "$DOWNLOAD_FILE"
    #ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto  -i "$3.m" -c:v hevc_nvenc -cq 51 -preset p7 -ss 0 -t 60 -c:a copy -c:s copy "$DOWNLOAD_FILE"
    trap - ERR
}


# 使用 curl 下載 JSON 資料並轉換為物件
get_json_data() {
    local url="$1"
    local json_data=$(curl -s "$url")
    local video_url=$(echo "$json_data" | jq -r '.list[0].vod_play_url')
    VIDEO_NAME=$(echo "$json_data" | jq -r '.list[0].vod_name')
    IFS='#'
    # 使用 read 命令讀取分割後的結果並存入陣列
    read -r -a urls <<<"$video_url"

    #根據$區隔
    for i in "${urls[@]}"; do
        tmp_url="${i#*$}"
        get_num_str=$(echo $i | sed -E 's/(.+)\$.*/\1/')
        target_number=$(echo "$get_num_str" | grep -oE '[0-9]+')
        echo -e "e=>$target_number"
        formatted_number=$(printf "%02d" "$((10#$target_number))")
        number="EP$formatted_number"
        number_2="E$formatted_number"
        download_video $tmp_url $number $number_2
    done

}
cd $DOWNLOAD_DIR
get_json_data $URL