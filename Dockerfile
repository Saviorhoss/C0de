FROM debian:latest

ENV UUID='de04add9-5c68-8bab-950c-08cd5320df18'
ENV VMESS_WSPATH='/vmess'
ENV TROJAN_WSPATH='/trojan'

RUN rm -rf /usr/share/nginx/*

RUN apt-get update && apt-get install -y wget unzip nginx

WORKDIR /usr/share/nginx/

RUN wget https://github.com/Saviorhoss/htmlzip/raw/main/savior.zip -O /usr/share/nginx/savior.zip
RUN unzip -o "/usr/share/nginx/savior.zip" -d /usr/share/nginx/html
RUN rm -f /usr/share/nginx/savior.zip

RUN wget https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip -O /tmp/xray.zip
RUN unzip -o /tmp/xray.zip -d /tmp/
RUN mv /tmp/xray /usr/local/bin/
RUN chmod +x /usr/local/bin/xray

COPY ./config.json /etc/xray/config.json
COPY ./xray.service /etc/systemd/system/xray.service
COPY ./nginx.service /etc/systemd/system/nginx.service

RUN systemctl daemon-reload
RUN systemctl enable xray
RUN systemctl enable nginx

CMD ["bash", "-c", "systemctl start xray && systemctl start nginx && tail -f /var/log/nginx/access.log"]
