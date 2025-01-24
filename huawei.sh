#!/bin/bash

# Internet Indicator for HG680P Wrapper with Manual Menu
# by Lutfa Ilham & Modified by Aryo
# v2.0
# GPIO Founder Lutfa Ilham

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

SERVICE_NAME="Internet Indicator"
DEFAULT_LAN_OFF_DURATION=20 # Default durasi waktu untuk LAN off (detik)
DEFAULT_CHECK_INTERVAL=1    # Default interval pengecekan (detik)

LAN_OFF_DURATION=$DEFAULT_LAN_OFF_DURATION
CHECK_INTERVAL=$DEFAULT_CHECK_INTERVAL

function loop() {
  echo "Monitoring LAN status..."
  lan_off_timer=0
  while true; do
    hgledon -lan dis
    if curl -X "HEAD" --connect-timeout 3 -so /dev/null "http://bing.com"; then
      lan_off_timer=0
    else
      lan_off_timer=$((lan_off_timer + CHECK_INTERVAL))
    fi

    # Jika LAN off lebih dari waktu yang ditentukan, jalankan script Python
    if [ "$lan_off_timer" -ge "$LAN_OFF_DURATION" ]; then
      echo "LAN off selama $LAN_OFF_DURATION detik, menjalankan /usr/bin/huawei.py ..."
      python3 /usr/bin/huawei.py
      lan_off_timer=0 # Reset timer setelah menjalankan script
    fi

    sleep "$CHECK_INTERVAL"
  done
}

function start() {
  echo -e "Starting ${SERVICE_NAME} service ..."
  screen -AmdS internet-indicator "${0}" -l
}

function stop() {
  echo -e "Stopping ${SERVICE_NAME} service ..."
  kill $(screen -list | grep internet-indicator | awk -F '[.]' {'print $1'}) 2>/dev/null || echo "Service not running"
}

function configure() {
  echo "Konfigurasi Interval Pengecekan dan Durasi LAN Off"
  read -p "Masukkan interval pengecekan (detik, default $DEFAULT_CHECK_INTERVAL): " input_interval
  CHECK_INTERVAL=${input_interval:-$DEFAULT_CHECK_INTERVAL}

  read -p "Masukkan durasi LAN off sebelum menjalankan script (detik, default $DEFAULT_LAN_OFF_DURATION): " input_duration
  LAN_OFF_DURATION=${input_duration:-$DEFAULT_LAN_OFF_DURATION}

  echo "Konfigurasi berhasil diperbarui:"
  echo " - Interval Pengecekan: $CHECK_INTERVAL detik"
  echo " - Durasi LAN Off: $LAN_OFF_DURATION detik"
}

function manual_run() {
  echo "Menjalankan monitor secara manual dengan interval $CHECK_INTERVAL detik dan durasi LAN off $LAN_OFF_DURATION detik ..."
  loop
}

function menu() {
  while true; do
    echo -e "\n===== ${SERVICE_NAME} Menu ====="
    echo "1. Jalankan Service"
    echo "2. Hentikan Service"
    echo "3. Konfigurasi Interval dan Durasi"
    echo "4. Jalankan Manual (Foreground)"
    echo "5. Keluar"
    echo "============================"
    read -p "Pilih opsi [1-5]: " choice

    case $choice in
      1)
        start
        ;;
      2)
        stop
        ;;
      3)
        configure
        ;;
      4)
        manual_run
        ;;
      5)
        echo "Keluar dari menu."
        exit 0
        ;;
      *)
        echo "Pilihan tidak valid, coba lagi."
        ;;
    esac
  done
}

function usage() {
  cat <<EOF
Usage:
  -r  Run ${SERVICE_NAME} service
  -s  Stop ${SERVICE_NAME} service
  -m  Open menu
EOF
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
  -m)
    menu
    ;;
  *)
    usage
    ;;
esac
