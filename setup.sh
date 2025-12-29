#!/bin/bash

# ==============================================================================
# PROJECT: Denver Lean-Server (Pi 5)
# USER:    worm
# DATE:    December 2025
#
# MAINTENANCE NOTES:
# 1. RUN COMMAND:
#    curl -sSL https://raw.githubusercontent.com/jeremybphillips/home-pi-setup/main/setup.sh | sudo bash
#
# 2. TEST BEFORE RUNNING (Dry Run):
#    curl -sSL https://raw.githubusercontent.com/jeremybphillips/home-pi-setup/main/setup.sh
#
# 3. FIX WINDOWS LINE ENDINGS (If you see ^M or errors):
#    sed -i 's/\r$//' setup.sh
#
# 4. MONITOR LOGS:
#    docker logs -f metube
# ==============================================================================

# ================================================================
# PRE-INSTALL SETUP (Denver, CO)
# ================================================================
export DEBIAN_FRONTEND=noninteractive

# Set the System Timezone
echo "Setting timezone to America/Denver..."
sudo timedatectl set-timezone America/Denver

echo "Starting the Lean Pi Server Installation..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker if not already present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -sSL https://get.docker.com | sh
    sudo usermod -aG docker worm
fi

# ================================================================
# 1. PORTAINER (Admin Panel)
# ================================================================
echo "Installing Portainer..."
docker volume create portainer_data
docker run -d \
  --name portainer \
  --restart always \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# ================================================================
# 2. HOME ASSISTANT
# ================================================================
echo "Installing Home Assistant..."
mkdir -p /home/worm/homeassistant
docker run -d \
  --name homeassistant \
  --restart unless-stopped \
  --privileged \
  --net host \
  -v /home/worm/homeassistant:/config \
  -e TZ=America/Denver \
  ghcr.io/home-assistant/home-assistant:stable

# ================================================================
# 3. HOMEBRIDGE
# ================================================================
echo "Installing Homebridge..."
mkdir -p /home/worm/homebridge
docker run -d \
  --name homebridge \
  --restart unless-stopped \
  --net host \
  -v /home/worm/homebridge:/homebridge \
  homebridge/homebridge:latest

# ================================================================
# 4. METUBE (YouTube Downloader)
# ================================================================
echo "Installing MeTube..."
mkdir -p /home/worm/downloads
docker run -d \
  --name metube \
  --restart unless-stopped \
  -p 8085:8081 \
  -v /home/worm/downloads:/downloads \
  -e DOWNLOAD_DIR=/downloads \
  -e STATE_DIR=/downloads/.metube \
  alexta69/metube:latest

# ================================================================
# 5. WATCHTOWER
# ================================================================
echo "Installing Watchtower..."
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower

# ================================================================
# 6. HEIMDALL (Dashboard)
# ================================================================
echo "Installing Heimdall..."
mkdir -p /home/worm/heimdall
docker run -d \
  --name heimdall \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v /home/worm/heimdall:/config \
  -e PUID=$(id -u worm) -e PGID=$(id -g worm) -e TZ=America/Denver \
  linuxserver/heimdall:latest

# ================================================================
# FINAL SUMMARY
# ================================================================
HOST_NAME=$(hostname)
PRIMARY_URL="${HOST_NAME}.local"
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo "================================================================"
echo "         🚀 ALL SYSTEMS ARE GO! YOUR PI IS READY 🚀             "
echo "================================================================"
echo " Primary Access:  http://${PRIMARY_URL}"
echo " Fallback IP:     http://${IP_ADDR}"
echo "----------------------------------------------------------------"
echo "----------------------------------------------------------------"
echo " INSTALLED SERVICES"
echo "----------------------------------------------------------------"
echo " 🟢 Portainer (Admin):      https://${PRIMARY_URL}:9443"
echo " 🟢 Heimdall (Dashboard):   http://${PRIMARY_URL}:80"
echo " 🟢 Home Assistant:         http://${PRIMARY_URL}:8123"
echo " 🟢 Homebridge:             http://${PRIMARY_URL}:8581"
echo " 🟢 MeTube (Downloads):     http://${PRIMARY_URL}:8085"
echo "----------------------------------------------------------------"
echo " 📂 Storage: Your videos are at /home/worm/downloads"
echo "================================================================"