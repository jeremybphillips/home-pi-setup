#!/bin/bash

# ==============================================================================
# PROJECT: Denver Lean-Server (Pi 5)
# AUTHOR:  Custom Build based on Eddie's Seven Wonders
# DATE:    December 2025 (Christmas Build)
#
# MAINTENANCE NOTES:
# 1. RUN COMMAND:
#    curl -sSL https://raw.githubusercontent.com/jeremybphillips/home-pi-setup/refs/heads/main/setup.sh?token=GHSAT0AAAAAADRLNRKSOMCHZLMFHZ6KMWYC2KN2A2A | sudo bash
#
# 2. TEST BEFORE RUNNING (Dry Run):
#    curl -sSL https://raw.githubusercontent.com/jeremybphillips/home-pi-setup/refs/heads/main/setup.sh?token=GHSAT0AAAAAADRLNRKSOMCHZLMFHZ6KMWYC2KN2A2A
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

# Set the System Timezone for the Host Pi
echo "Setting timezone to America/Denver..."
sudo timedatectl set-timezone America/Denver

echo "Starting the Lean Pi Server Installation..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker if not already present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -sSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
fi

# ================================================================
# 1. PORTAINER (Admin Panel - Port 9443/9000)
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
# 2. HOME ASSISTANT (Port 8123)
# ================================================================
echo "Installing Home Assistant..."
mkdir -p /home/pi/homeassistant
docker run -d \
  --name homeassistant \
  --restart unless-stopped \
  --privileged \
  --net host \
  -v /home/pi/homeassistant:/config \
  -e TZ=America/Denver \
  ghcr.io/home-assistant/home-assistant:stable

# ================================================================
# 3. HOMEBRIDGE (Port 8581 - Running in Detached Mode)
# ================================================================
echo "Installing Homebridge..."
mkdir -p /home/pi/homebridge
docker run -d \
  --name homebridge \
  --restart unless-stopped \
  --net host \
  -v /home/pi/homebridge:/homebridge \
  homebridge/homebridge:latest

# ================================================================
# 4. METUBE (YouTube Downloader - Port 8085)
# ================================================================
echo "Installing MeTube..."
mkdir -p /home/pi/downloads
docker run -d \
  --name metube \
  --restart unless-stopped \
  -p 8085:8081 \
  -v /home/pi/downloads:/downloads \
  -e DOWNLOAD_DIR=/downloads \
  -e STATE_DIR=/downloads/.metube \
  alexta69/metube:latest

# ================================================================
# 5. WATCHTOWER (Auto-Updater)
# ================================================================
echo "Installing Watchtower..."
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower

# ================================================================
# 6. HEIMDALL (Dashboard - Port 80/443)
# ================================================================
echo "Installing Heimdall..."
mkdir -p /home/pi/heimdall
docker run -d \
  --name heimdall \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -v /home/pi/heimdall:/config \
  -e PUID=1000 -e PGID=1000 -e TZ=America/Denver \
  linuxserver/heimdall:latest

# ================================================================
# FINAL SUMMARY & NETWORK LOGIC
# ================================================================
HOST_NAME=$(hostname)
PRIMARY_URL="${HOST_NAME}.local"

# Fallback IP detection
IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
if [ -z "$IP_ADDR" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
fi

echo ""
echo "================================================================"
echo "         🚀 ALL SYSTEMS ARE GO! YOUR PI IS READY 🚀             "
echo "================================================================"
echo ""
echo " Primary Access:  http://${PRIMARY_URL}"
echo " Fallback IP:     http://${IP_ADDR}"
echo ""
echo "----------------------------------------------------------------"
echo " INSTALLED SERVICES"
echo "----------------------------------------------------------------"
echo " 🟢 Portainer (Admin):      https://${PRIMARY_URL}:9443"
echo " 🟢 MeTube (Downloads):     http://${PRIMARY_URL}:8085"
echo " 🟢 Home Assistant:         http://${PRIMARY_URL}:8123"
echo " 🟢 Homebridge:             http://${PRIMARY_URL}:8581"
echo " 🟢 Heimdall (Home Page):   http://${PRIMARY_URL}:80"
echo ""
echo "----------------------------------------------------------------"
echo " 📂 Storage: Your videos are at /home/pi/downloads"
echo " 💡 Tip: If ${PRIMARY_URL} fails, use the IP: ${IP_ADDR}"
echo "================================================================"
echo ""