#!/bin/bash


# DynamicMarqueeZero Install Script (v2)
# Installs necessary packages, sets up cache, configures display, SSH keys, and systemd service.

set -e

echo "=== DynamicMarqueeZero Setup Script ==="


# 1. Prompt for display resolution
echo "[1/11] Gather information."
read -p "Enter your screen width (e.g., 1920): " screen_width
read -p "Enter your screen height (e.g., 360): " screen_height
read -p "Enter your remote host (e.g., pi@retropie.local): " remote_host

# 2. Pick locale
echo "[2/11] [Locale Setup] Configure system locale."
echo "Available UTF-8 Locales:"
available_locales=$(locale -a | grep -i utf)
select chosen_locale in $available_locales; do
  if [[ -n "$chosen_locale" ]]; then
    echo "You chose: $chosen_locale"
    break
  else
    echo "Invalid selection, try again."
  fi
done

# 3. Set locale
echo "[3/11] [Locale Setup] Generate system locale."
echo "$chosen_locale UTF-8" | sudo tee -a /etc/locale.gen >/dev/null
sudo locale-gen "$chosen_locale"
sudo update-locale LANG=$chosen_locale

# 4. SSH key setup
echo "[4/11] Setting up SSH access..."
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi
ssh-copy-id "$remote_host"
# 5. Update /boot/config.txt
boot_config="/boot/config.txt"
gpu_mem_line="gpu_mem=128"
display_block="hdmi_drive=2
hdmi_group=2
hdmi_mode=87
hdmi_cvt=${screen_width} ${screen_height} 60"

echo "[5/11] Configuring $boot_config for display..."

# Only append lines if they don't already exist
for line in "$gpu_mem_line" $display_block; do
  if ! grep -qF "$line" "$boot_config"; then
    echo "$line" | sudo tee -a "$boot_config" >/dev/null
  fi
done

# 6. Install Python and Pygame
echo "[6/11] Updating package list and installing required software..."
sudo apt update
sudo apt install -y python3 python3-pip
pip3 install pygame

# 7. Create cache directory
echo "[7/11] Creating ~/cache directory..."
mkdir -p ~/cache

# 8. Download files from GitHub
echo "[8/11] Downloading Marquee files..."
GITHUB_REPO="https://raw.githubusercontent.com/LeatherWing70/DynamicMarqueeZero/tree/main/Marquee"
curl -fsSL "$GITHUB_REPO/marquee_daemon.py" -o ~/marquee_daemon.py
curl -fsSL "$GITHUB_REPO/marquee.service" -o ~/marquee.service
curl -fsSL "$GITHUB_REPO/retropie.png" -o ~/cache/retropie.png

# 9. Inject remote_host into daemon
echo "[9/11] Configureing daemon..."
sed -i "s/^remote_host = .*/remote_host = \"$remote_host\"/" ~/marquee_daemon.py

# 10. Adjust service file
echo "[10/11] Configureing daemon service..."
current_user=$(whoami)
user_home=$(eval echo "~$current_user")
sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $user_home/marquee_daemon.py|" ~/marquee.service
sed -i "s|User=.*|User=$current_user|" ~/marquee.service

# 11. Install systemd service
echo "[11/11] Installing daemon service..."
sudo mv ~/dynamic_marquee.service /etc/systemd/system/dynamic_marquee.service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable dynamic_marquee
sudo systemctl start dynamic_marquee

echo "✅ Installation complete! Reboot recommended."
