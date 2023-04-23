#!/bin/bash

set -e
trap 'echo "Error: $BASH_SOURCE:$LINENO $BASH_COMMAND" >&2' ERR

# Set default values for environment variables
export UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
export VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
export TROJAN_WSPATH=${TROJAN_WSPATH:-'/trojan'}

# Generate Xray config file
cat > /etc/xray/config.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3003
                    },
                    {
                        "path":"${TROJAN_WSPATH}",
                        "dest":3004
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${VMESS_WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"${TROJAN_WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        }
    ],
    "outbounds":[
        {
            "protocol":"freedom"
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "domain": [
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag": "default-outbound"
            }
        ]
    },
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    }
}
EOF

# Remove old files from nginx directory
rm -rf /usr/share/nginx/*

# Download and extract new files to nginx directory
wget -q https://github.com/Saviorhoss/htmlzip/raw/main/savior.zip -O /usr/share/nginx/savior.zip
unzip -o /usr/share/nginx/savior.zip -d /usr/share/nginx/html
rm -f /usr/share/nginx/savior.zip

# Install dependencies
apt-get update -qq && apt-get install -y -qq wget unzip nginx

# Download and extract Xray binary to /usr/local/bin
XRAY_LINK="https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip"
XRAY_ZIP_FILE=$(basename "$XRAY_LINK")
wget -q "$XRAY_LINK" -O "/tmp/${XRAY_ZIP_FILE}"
unzip -o "/tmp/${XRAY_ZIP_FILE}" -d "/tmp/"
rm -f "/tmp/${XRAY_ZIP_FILE}"
mv "/tmp/xray" /usr/local/bin/

# Set permissions for executable files
chmod +x /usr/local/bin/xray

# Create systemd service for Xray
cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
User=root
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=Nginx HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable xray nginx
systemctl restart xray nginx

echo "Xray and Nginx have been successfully installed and configured
