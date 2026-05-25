#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/strongy/super-duper-potato/master"

echo "================================"
echo " AdGuard Homelab Deploy Script"
echo "================================"
echo ""

# Prompt for variables
read -p "Enter hostname for this machine (e.g. adguard, orion): " HOSTNAME
read -p "Enter AdGuard hostname (e.g. adguard.adrian.marsh1.net): " ADGUARD_HOSTNAME
read -p "Enter gateway IP (e.g. 192.168.6.1): " GATEWAY_IP
read -p "Enter DHCP start IP (e.g. 192.168.6.6): " DHCP_START
read -p "Enter DHCP end IP (e.g. 192.168.6.254): " DHCP_FINISH
read -s -p "Enter AdGuard admin password: " AGPASSWORD
echo ""

echo ""
echo ">> Setting hostname to $HOSTNAME..."
hostnamectl set-hostname "$HOSTNAME"
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts

echo ">> Updating system..."
apt-get update -qq

echo ">> Installing dependencies..."
apt-get install -y -qq apache2-utils python3-pip python3-certbot-dns-cloudflare git

echo ">> Installing Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker peter

echo ">> Pinning Cloudflare Python package..."
pip install cloudflare==2.19.* --break-system-packages

echo ">> Setting up folder structure..."
mkdir -p /home/peter/docker/adguard/config/AdGuardHome
mkdir -p /home/peter/docker/adguard/config/data
mkdir -p /home/peter/docker/portainer/data/certs
mkdir -p /mnt/usb
ln -sfn /home/peter/docker /mnt/usb

echo ">> Downloading files from GitHub..."
curl -fsSL "$REPO/AdGuardHome_github.yaml" -o /mnt/usb/adguard/config/AdGuardHome/AdGuardHome.yaml
curl -fsSL "$REPO/docker-compose.yaml" -o /home/peter/docker-compose.yaml
curl -fsSL "$REPO/combine-ssl.sh" -o /root/combine-ssl.sh
curl -fsSL "$REPO/renew.sh" -o /root/renew.sh
curl -fsSL "$REPO/renew-test.sh" -o /root/renew-test.sh
curl -fsSL "$REPO/sys-update.sh" -o /root/sys-update.sh
curl -fsSL "$REPO/clean.sh" -o /root/clean.sh
chmod +x /root/combine-ssl.sh /root/renew.sh /root/renew-test.sh /root/sys-update.sh /root/clean.sh

echo ">> Generating password hash..."
AGHASH=$(htpasswd -bnBC 10 "" "$AGPASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')

echo ">> Applying configuration..."
sed -i "s|PASSWORDHASH|$AGHASH|g" /mnt/usb/adguard/config/AdGuardHome/AdGuardHome.yaml
sed -i "s|ADGUARD_HOSTNAME|$ADGUARD_HOSTNAME|g" /mnt/usb/adguard/config/AdGuardHome/AdGuardHome.yaml
sed -i "s|GATEWAY_IP|$GATEWAY_IP|g" /mnt/usb/adguard/config/AdGuardHome/AdGuardHome.yaml
sed -i "s|DHCP_START|$DHCP_START|g" /mnt/usb/adguard/config/AdGuardHome/AdGuardHome.yaml
sed -i "s|DHCP_FINISH|$DHCP_FINISH|g" /mnt/usb/adguard/config/AdGuardHome/AdGuardHome.yaml

echo ">> Setting up Cloudflare credentials..."
mkdir -p /root/.secrets
chmod 700 /root/.secrets
if [ ! -f /root/.secrets/cloudflare.ini ]; then
    echo "!! cloudflare.ini not found at /root/.secrets/cloudflare.ini"
    echo "!! Please copy it across and re-run from the certbot step"
    exit 1
fi
chmod 0600 /root/.secrets/cloudflare.ini

echo ">> Running Certbot..."
certbot certonly \
  --agree-tos \
  --no-eff-email \
  --email strongy_p@yahoo.com \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
  -d "*.adrian.marsh1.net" \
  -d "*.home.marsh1.net"

echo ">> Copying certs into place..."
/root/combine-ssl.sh

echo ">> Setting up crontab..."
(crontab -l 2>/dev/null; echo "0 3 * * * /root/renew.sh") | crontab -

echo ">> Starting Docker containers..."
cd /home/peter
docker compose up -d

echo ""
echo "================================"
echo " Deploy complete!"
echo " AdGuard: https://$ADGUARD_HOSTNAME"
echo " Portainer: https://$(hostname -I | awk '{print $1}'):9443"
echo "================================"
