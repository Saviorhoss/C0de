FROM nginx:latest

LABEL maintainer="Savior_128"
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80

ENV UUID='de04add9-5c68-8bab-950c-08cd5320df18' \
    VMESS_WSPATH='/vmess' \
    VLESS_WSPATH='/vless' \
    TROJAN_WSPATH='/trojan' \
    SS_WSPATH='/shadowsocks'

RUN apt-get update && apt-get install -y wget unzip nginx && \
    rm -rf /var/lib/apt/lists/*

COPY script.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/script.sh

WORKDIR /usr/share/nginx/html
RUN wget -O Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d . && \
    rm -f Xray-linux-64.zip

WORKDIR /var/www/html/savior
RUN wget https://github.com/Saviorhoss/htmlzip/raw/main/savior.zip -O /tmp/savior.zip && \
    unzip /tmp/savior.zip -d . && \
    rm -f /tmp/savior.zip

RUN chown -R www-data:www-data /var/www/html/savior && \
    chmod -R 755 /var/www/html/savior

CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
ENTRYPOINT ["/usr/local/bin/script.sh"]
