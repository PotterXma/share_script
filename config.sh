#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
sudo systemctl enable docker --now

# Create Docker configuration file for SOCKS5 proxy
# echo '[Service]
# Environment="HTTP_PROXY=socks5://127.0.0.1:1080"
# Environment="HTTPS_PROXY=socks5://127.0.0.1:1080"' | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null


# Reload systemd configuration
sudo systemctl daemon-reload


# Restart Docker service to apply changes
sudo systemctl restart docker
echo "docker 服务已启动"

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

# Restart v2ray service
sudo systemctl restart v2ray

# Add export line to /etc/profile
echo "export ALL_PROXY=socks5://127.0.0.1:1080" | sudo tee -a /etc/profile

# Source /etc/profile
source /etc/profile

echo "配置文件已生成并保存到 /usr/local/etc/v2ray/config.json"
echo "v2ray 服务已重新启动，并已将代理设置添加到 /etc/profile。"
