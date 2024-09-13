# 下載采集站用工具
- 有排除廣告功能(尚未完善)
- 不會重複下載
- 有設定ffmpeg 指令，請根據個人喜好調整(目前設定是有用的nvidia-gpu)\
  如果不想轉碼，把指令改成=>`ffmpeg -protocol_whitelist file,http,https,tcp,tls,crypto -i "$3.m" -c copy "$DOWNLOAD_FILE"` 即可
## 使用方式
1. 去尋找影視資源站(請自行GOOGLE) 提示：<-
2. 找到該資源站尋找提供的接口請找json為主
3. 將接口網址放入 SOURCE_URL即可
4. 並在采集站找到影片ID，並放入 VIDEO_ID（有可能在網址，有可能要從json裡面找）
5. 執行

## ps
- 不提倡盜版，請看完自行刪除
- 如果影片本身已經把廣告嵌入在影片裡，是無法排除廣告(就是播放正片時，出現浮水印無法移除)
- only linux