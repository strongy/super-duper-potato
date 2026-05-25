sudo cat /etc/letsencrypt/live/adrian.marsh1.net/privkey.pem \
           /etc/letsencrypt/live/adrian.marsh1.net/cert.pem | \
  sudo tee /etc/letsencrypt/live/adrian.marsh1.net/combined.pem

cat /etc/letsencrypt/live/adrian.marsh1.net/fullchain.pem > /mnt/usb/adguard/config/data/fullchain.pem
cat /etc/letsencrypt/live/adrian.marsh1.net/privkey.pem > /mnt/usb/adguard/config/data/privkey.pem
chmod 0600 /mnt/usb/adguard/config/data/privkey.pem

cat /etc/letsencrypt/live/adrian.marsh1.net/fullchain.pem > /mnt/usb/portainer/data/certs/fullchain.pem
cat /etc/letsencrypt/live/adrian.marsh1.net/privkey.pem > /mnt/usb/portainer/data/certs/privkey.pem
chmod 0600 /mnt/usb/portainer/data/certs/privkey.pem
