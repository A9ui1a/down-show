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
    echo $url > "$3.strm"

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
cd "$DOWNLOAD_DIR"
get_json_data $URL