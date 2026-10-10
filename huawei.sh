#!/bin/bash
# GPIO Founder Lutfa Ilham
# Internet Monitor for Huawei
# by Aryo Brokolly (youtube)
# 1.1 - Dengan Logging

DIR=/usr/bin
CONF=/etc/config
MODEL=/usr/lib/lua/luci/model/cbi
CON=/usr/lib/lua/luci/controller
URL=https://raw.githubusercontent.com/saputribosen/1clickhuawei/main

LOG_FILE="/var/log/huawei_monitor.log"
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

retry_download() {
    local file_path=$1
    local url=$2
    local max_retries=5
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        wget -O "$file_path" "$url"
        if [ -s "$file_path" ]; then
            echo "Download successful: $file_path"
            return 0
        else
            echo "Download failed or file size 0 KB. Retrying ($attempt/$max_retries)..."
            rm -f "$file_path"
            attempt=$((attempt + 1))
            sleep 2
        fi
    done

    echo "Failed to download $file_path after $max_retries attempts."
    echo "Check your internet connection and try again. Exiting."
    exit 1
}


if [ "$(id -u)" != "0" ]; then
  log "This script must be run as root"
  exit 1
fi

SERVICE_NAME="Huawei Monitor"
CONFIG_FILE="/etc/config/huawey"
DEFAULT_CHECK_INTERVAL=1

if [ -f "$CONFIG_FILE" ]; then
  source <(grep -E "^\s*option" "$CONFIG_FILE" | sed -E 's/option ([^ ]+) (.+)/\1=\2/')
else
  log "Config file $CONFIG_FILE not found. Exiting."
  exit 1
fi

LAN_OFF_DURATION=${lan_off_duration:-5}
MODEM_PATH=${modem_path}
CHECK_INTERVAL=$DEFAULT_CHECK_INTERVAL

function loop() {
  log "Monitoring LAN status..."
  lan_off_timer=0
  while true; do
    if curl -X "HEAD" --connect-timeout 3 -so /dev/null "http://bing.com"; then
      if [ "$lan_off_timer" -ne 0 ]; then
        log "Internet kembali normal."
      fi
      lan_off_timer=0
    else
      lan_off_timer=$((lan_off_timer + CHECK_INTERVAL))
      log "Internet tidak terdeteksi. Timer: $lan_off_timer detik."
    fi

    if [ "$lan_off_timer" -ge "$LAN_OFF_DURATION" ]; then
      log "LAN off selama $LAN_OFF_DURATION detik, menjalankan script pergantian IP ..."
      python3 /usr/bin/huawey.py &>> "$LOG_FILE"
      lan_off_timer=0 
    fi

    sleep "$CHECK_INTERVAL"
  done
}

function start() {
  log "Starting ${SERVICE_NAME} service ..."
  screen -AmdS huawei-monitor "${0}" -l
}

function stop() {
  log "Stopping ${SERVICE_NAME} service ..."
  kill $(screen -list | grep huawei-monitor | awk -F '[.]' {'print $1'}) 2>/dev/null || log "Service not running"
}

function usage() {
  cat <<EOF
Usage:
  -r  Run ${SERVICE_NAME} service
  -s  Stop ${SERVICE_NAME} service
  -u  Update ${SERVICE_NAME} service
  -x  Uninstall ${SERVICE_NAME} service
EOF
}

function update(){
clear
    echo "Updating..."
    sleep 3
    clear
    retry_download "$MODEL/huawey.lua" "$URL/cbi_model/huawey.lua"
    retry_download "$DIR/huawei.py" "$URL/huawei.py"
    chmod +x "$DIR/huawei.py"
    
    retry_download "$DIR/huawei" "$URL/huawei.sh"
    chmod +x "$DIR/huawei"
    
    retry_download "$CON/huawey.lua" "$URL/controller/huawey.lua"
    chmod +x "$CON/huawey.lua"
    clear
    echo " Update Huawei Monitor succesfully..."
    sleep 4
}

function uninstall()
{		

	echo "deleting file huawei monitor..."
    	clear
	echo "Remove file huawei.py..."
        rm -f $DIR/huawei.py
        mv $DIR/huawei_x.py $DIR/huawei.py
	sleep 1
	echo "Remove file huawey.lua..."
	rm -f $MODEL/huawey.lua
	clear
	sleep 1
	echo "Remove file huawei..."
	rm -f $DIR/huawei
	clear
	sleep 1
	echo "Remove file huawey..."
	rm -f $CONF/huawey
        clear
        sleep 1
	echo "Remove file huawey.lua..."
  	rm -f $CON/huawey.lua
 	sleep1
       clear
  echo " Uninstall Huawei Monitor succesfully..."
  sleep 5
  exit
}

case "${1}" in
  -l)
    loop
    ;;
  -r)
    start
    ;;
  -s)
    stop
    ;;
  -u)
    update
    ;;
  -x)
    uninstall
    ;;
  *)
    usage
    ;;
esac
