#!/usr/bin/env python3
# Script by https://bit.ly/aryochannel

import logging
from huawei_lte_api.Client import Client
from huawei_lte_api.Connection import Connection
import time
import telegram
import socket
import requests
import re
from telegram import Bot

def get_wan_info(client):
    """Get WAN IP address and device name."""
    wan_info = client.device.information()
    wan_ip_address = wan_info.get('WanIPAddress')
    device_name = wan_info.get('DeviceName')
    return wan_ip_address, device_name

def send_telegram_message(token, chat_id, message, message_thread_id=None):
    """Send message to Telegram, with optional message_thread_id."""
    url = f'https://api.telegram.org/bot{token}/sendMessage'
    data = {'chat_id': chat_id, 'text': message}

    # Tambahkan message_thread_id jika disediakan
    if message_thread_id is not None:
        data['message_thread_id'] = message_thread_id

    response = requests.post(url, data=data)
    if response.status_code != 200:
        raise Exception(f"Error sending message: {response.text}")

def load_openwrt_config(config_file="/etc/config/huawey"):
    """Load OpenWRT config file."""
    config = {}
    try:
        with open(config_file, "r") as file:
            for line in file:
                match = re.match(r"\s*option\s+(\w+)\s+'([^']+)'", line)
                if match:
                    key, value = match.groups()
                    config[key] = value
    except FileNotFoundError:
        raise Exception(f"Configuration file {config_file} not found.")
    return config

def main():
    """Main function."""
    config = load_openwrt_config()

    # Extract configuration values
    router_ip = config.get('router_ip', '192.168.8.1')
    username = config.get('username', 'admin')
    password = config.get('password', 'admin')
    telegram_token = config.get('telegram_token', '')
    chat_id = config.get('chat_id', '')
    message_thread_id = config.get('message_thread_id')

    hostname = socket.gethostname()
    connection_url = f"http://{username}:{password}@{router_ip}/"

    with Connection(connection_url) as connection:
        client = Client(connection)
        try:
            print_header("Get a new WAN IP Address", "")

            wan_ip_address, device_name = fetch_wan_info(client)
            print_result("Modem Name", device_name)
            print_result("Current IP", wan_ip_address)

            print("Initiating IP change process...")
            initiate_ip_change(client)

            time.sleep(5)

            print("Waiting for the IP to be changed...")
            wan_ip_address_after_plmn, _ = fetch_wan_info(client)
            print_result("New IP", wan_ip_address_after_plmn)
            send_telegram_message(telegram_token, chat_id, f"⚙️ Change IP-{hostname}.\n===============\n🔰 Modem Name: {device_name}\n🔰 Current IP: {wan_ip_address}\n🔰 New IP: {wan_ip_address_after_plmn} \n\n✅ IP change successfully.\n===============\n👨‍🔧 By Aryo Brokolly",
                message_thread_id=message_thread_id
            )

            print_success("IP has been successfully changed.")

        except Exception as e:
            print_error(f"An error occurred: {e}")
            send_telegram_message(telegram_token, chat_id, f"An error occurred: {e}", message_thread_id=message_thread_id)

def fetch_wan_info(client):
    """Fetch WAN IP address and device name."""
    wan_ip_address = None
    device_name = None
    while not (wan_ip_address and device_name):
        wan_ip_address, device_name = get_wan_info(client)
    return wan_ip_address, device_name

def initiate_ip_change(client):
    """Initiate IP change process."""
    response = client.net.plmn_list()

def print_header(title, creator):
    """Print section header."""
    print(f"{'=' * 40}")
    print(f"{title.center(40)}")
    print(f"{'=' * 40}")
    """print(f"Script created by: {creator}\n")"""

def print_result(label, value):
    """Print result."""
    print(f"{label}: {value}")

def print_success(message):
    """Print success message."""
    print("\n\033[92m" + message + "\033[0m")

def print_error(message):
    """Print error message."""
    print("\n\033[91m" + message + "\033[0m")

if __name__ == "__main__":
    main()