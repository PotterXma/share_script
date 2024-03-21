#!/bin/bash

# Prompt user for server IP, port, and user ID
read -p "请输入您的服务器IP: " server_ip
read -p "请输入您的端口: " server_port
read -p "请输入您的用户ID: " user_id

# JSON template
config_template='{
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "auth": "noauth"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "%s",
            "port": %d,
            "users": [
              {
                "id": "%s",
                "alterId": 0
              }
            ]
          }
        ]
      }
    }
  ]
}'

# Replace placeholders with user input
config_json=$(printf "$config_template" "$server_ip" "$server_port" "$user_id")

# Write JSON to file
echo "$config_json" > /usr/local/etc/v2ray/config.json

echo "配置文件已生成并保存到 /usr/local/etc/v2ray/config.json"

apt install -y curl 

curl https://ipinfo.io
