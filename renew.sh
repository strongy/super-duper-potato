certbot renew >> /var/log/letsencrypt/renew.log
/root/combine-ssl.sh >/dev/null 2>&1
/home/peter/update.sh
