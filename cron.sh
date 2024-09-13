#!/bin/bash
FOLDER=""
if [ ! -d "$FOLDER" ]; then
  echo "資料夾 $FOLDER 不存在"
  exit 1
fi
find "$FOLDER" -type f -name "download_show.sh" -exec bash {} \;
