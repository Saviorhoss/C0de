UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
TROJAN_WSPATH=${TROJAN_WSPATH:-'/trojan'}
SS_WSPATH=${SS_WSPATH:-'/shadowsocks'}
apt-get update && apt-get install -y wget unzip

generate_config() {
  cat > config.json << EOF
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
                        "dest":3001
                    },
                    {
                        "path":"${VLESS_WSPATH}",
                        "dest":3002
                    },
                    {
                        "path":"${VMESS_WSPATH}",
                        "dest":3003
                    },
                    {
                        "path":"${TROJAN_WSPATH}",
                        "dest":3004
                    },
                    {
                        "path":"${SS_WSPATH}",
                        "dest":3005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"${VLESS_WSPATH}"
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
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${SS_WSPATH}"
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
        },
        {
            "tag": "WARP",
            "protocol":"wireguard",
"settings": {
"secretKey": "GAl2z55U2UzNU5FG+LW3kowK+BA/WGMi1dWYwx20pWk=",
"address": [
"172.16.0.2/32",
"2606:4700:110:8f0a:fcdb:db2f:3b3:4d49/128"
],
"peers": [
{
"publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
"endpoint": "engage.cloudflareclient.com:2408"
}
]
}
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
"outboundTag": "WARP"
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
}

rm -rf /usr/share/nginx/html/*
wget -O /usr/share/nginx/html/Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip
unzip /usr/share/nginx/html/Xray-linux-64.zip -d /usr/share/nginx/html
rm -f /usr/share/nginx/html/Xray-linux-64.zip
generate_config

mkdir -p /var/www/html/savior
wget https://github.com/Saviorhoss/htmlzip/raw/main/savior.zip -O /tmp/savior.zip
unzip /tmp/savior.zip -d /var/www/html/savior

chown -R www-data:www-data /var/www/html/savior
chmod -R 755 /var/www/html/savior

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html/savior;
    index index.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

systemctl restart nginx
