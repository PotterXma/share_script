#!/bin/bash

# 读取配置文件
config_file="config"

if [ -f "$config_file" ]; then
    v2ray_address=$(sed -n '1p' "$config_file")
    v2ray_port=$(sed -n '2p' "$config_file")
    v2ray_id=$(sed -n '3p' "$config_file")
else
    echo "配置文件 '$config_file' 不存在。请确保文件存在并包含正确的信息。"
    exit 1
fi

# 安装 V2Ray
# Add V2Ray's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://apt.v2raya.org/key/public-key.asc -o /etc/apt/keyrings/v2raya.asc
sudo chmod a+r /etc/apt/keyrings/v2raya.asc

# Add the repository to Apt sources
echo "deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list > /dev/null
sudo apt-get update

# Install V2Ray
sudo apt-get install -y v2raya v2ray

# 配置文件内容
config_json=$(cat <<EOF
{
    "inbounds": [
        {
            "port": 1080,
            "protocol": "socks",
            "settings": {
                "auth": "noauth"
            },
            "tag": "socks-in"
        }
    ],
    "outbounds": [
        {
            "protocol": "vmess",
            "settings": {
                "vnext": [
                    {
                        "address": "$v2ray_address",
                        "port": $v2ray_port,
                        "users": [
                            {
                                "id": "$v2ray_id",
                                "alterId": 0
                            }
                        ]
                    }
                ]
            }
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "inboundTag": ["socks-in"],
                "outboundTag": "vmess-out"
            }
        ]
    }
}
EOF
)

# 将配置文件写入 /etc/v2ray/config.json
echo "$config_json" | sudo tee /etc/v2ray/config.json > /dev/null

# 启动 v2ray 服务
sudo systemctl enable v2raya.service --now

echo "V2Ray 已成功配置并启动。"

# 安装 Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 获取本机 IP 地址
local_ip=$(hostname -I | awk '{print $1}')

# 添加 Docker 的代理设置到 systemd 配置文件
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=socks5://$local_ip:1080"
Environment="HTTPS_PROXY=socks5://$local_ip:1080"
EOF

# 重载 systemd 配置
sudo systemctl daemon-reload

# 创建 Docker 配置文件
mkdir -p ~/.docker
cat > ~/.docker/config.json <<EOF
{
    "proxies": {
        "default": {
            "httpProxy": "socks5://$local_ip:1080/",
            "httpsProxy": "socks5://$local_ip:1080/",
            "noProxy": "*.test.example.com,.example.org,127.0.0.0/8"
        }
    }
}
EOF

# 启动 Docker 并设置为开机自启
sudo systemctl enable docker --now

echo "Docker 代理设置完成。"
