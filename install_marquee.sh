#!/bin/bash

# DynamicMarqueeZero Install Script (v2)
# Installs necessary packages, sets up cache, configures display, SSH keys, and systemd service.

set -e

echo "=== DynamicMarqueeZero Setup Script ==="
if [ -n "$SUDO_USER" ]; then
  user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  user_home="$HOME"
fi

# 1. Prompt for display resolution
echo "[1/12] Gather information."
read -p "Enter your screen width (e.g., 1920): " screen_width
read -p "Enter your screen height (e.g., 360): " screen_height
read -p "Enter your remote host (e.g., pi@retropie.local): " remote_host

# 2. Pick locale
echo "[2/12] [Locale Setup] Configure system locale."
echo "Select your preferred system locale:"
locales=("en_US.UTF-8" "en_GB.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8" "es_ES.UTF-8" "it_IT.UTF-8" "pt_BR.UTF-8" "ja_JP.UTF-8")

select chosen_locale in "${locales[@]}"; do
  if [[ -n "$chosen_locale" ]]; then
    echo "You chose: $chosen_locale"
    break
  else
    echo "Invalid selection, try again."
  fi
done

# Uncomment the chosen locale in /etc/locale.gen if needed
if grep -E -q "^[[:space:]]*#?[[:space:]]*$chosen_locale[[:space:]]+UTF-8" /etc/locale.gen; then
  if grep -E -q "^[[:space:]]*$chosen_locale[[:space:]]+UTF-8" /etc/locale.gen; then
    echo "Locale already active: $chosen_locale"
  else
    echo "Uncommenting $chosen_locale..."
    sudo sed -i "s/^[[:space:]]*#*[[:space:]]*\($chosen_locale[[:space:]]\+UTF-8\)/\1/" /etc/locale.gen
  fi
else
  echo "Appending $chosen_locale to /etc/locale.gen"
  echo "$chosen_locale UTF-8" | sudo tee -a /etc/locale.gen
fi

# 3. Set locale
echo "[3/12] [Locale Setup] Generate system locale...  $chosen_locale UTF-8"
# sudo locale-gen "$chosen_locale"
sudo update-locale LANG=$chosen_locale

# 4. SSH key setup
# may require /etc/hosts setup.
echo "[4/12] Setting up SSH access."
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi
ssh-copy-id "$remote_host"

# 5. Update /boot/config.txt
boot_config="/boot/firmware/config.txt"

# Clean and default values
screen_width=$(echo "${screen_width:-1920}" | tr -d '\r\n')
screen_height=$(echo "${screen_height:-360}" | tr -d '\r\n')
full_cvt="$screen_width $screen_height 60"

echo "[5/12] Configuring $boot_config for display..."

# Lines to manage under [all]
declare -A config_map=(
  ["gpu_mem"]="128"
  ["hdmi_drive"]="2"
  ["hdmi_group"]="2"
  ["hdmi_mode"]="87"
  ["hdmi_cvt"]="$full_cvt"
  ["hdmi_force_hotplug"]="1"
)

# If no [all] section, add it to the end
if ! grep -q "^\[all\]" "$boot_config"; then
  echo -e "\n[all]" | sudo tee -a "$boot_config" > /dev/null
fi

# Loop over each setting and add or update
for key in "${!config_map[@]}"; do
  value="${config_map[$key]}"
  if grep -A10 "^\[all\]" "$boot_config" | grep -q "^$key="; then
    # Replace existing key=value under [all]
    sudo sed -i "/^\[all\]/,/^\[/ s|^$key=.*|$key=$value|" "$boot_config"
  else
    # Append under [all]
    sudo sed -i "/^\[all\]/a $key=$value" "$boot_config"
  fi
done

# 6. Install Python and Pygame
echo "[6/12] Updating package list and installing required software..."
sudo apt update
sudo apt upgrade
echo "Installing Python3"
sudo apt install -y python3 python3-pip
echo "seting up pygame"
#pip3 install pygame
sudo apt install -y python3-pygame
echo "Installing libegl-dev"
sudo apt install libegl-dev
# 7. Create cache directory
echo "[7/12] Creating ~/cache directory..."
mkdir -p "$user_home/cache"

# 8. Download files from GitHub
echo "[8/12] Downloading Marquee files..."
GITHUB_REPO="https://raw.githubusercontent.com/LeatherWing70/DynamicMarqueeZero/main/Marquee"
curl -fsSL "$GITHUB_REPO/marquee_daemon.py" -o "$user_home/marquee_daemon.py"
curl -fsSL "$GITHUB_REPO/marquee.service" -o "$user_home/marquee.service"
curl -fsSL "$GITHUB_REPO/retropie.png" -o "$user_home/cache/retropie.png"


real_user="${SUDO_USER:-$USER}"
sudo chown $real_user:$real_user $user_home/marquee_daemon.py $user_home/cache/retropie.png $user_home/cache $user_home/cache/retropie.png


# 9. Inject remote_host into daemon
echo "[9/12] Configureing daemon..."
sed -i "s/^remote_host = .*/remote_host = \"$remote_host\"/" "$user_home/marquee_daemon.py"
sed -i "s|cache_path = .*|cache_path = \"$user_home/cache\"|" "$user_home/marquee_daemon.py"
sed -i "s|current_image_path = .*|current_image_path = \"$user_home/cache/retropie.png\"|" "$user_home/marquee_daemon.py"
sed -i "s|user = .*|user = \"$real_user\"|" "$user_home/marquee_daemon.py"


# 10. Adjust service file
echo "[10/12] Configureing daemon service..."
user_id=$(id -u "$real_user")

arch=$(uname -m)
sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $user_home/marquee_daemon.py|" "$user_home/marquee.service"
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$user_home|" "$user_home/marquee.service"
sed -i "s|User=.*|User=$real_user|" "$user_home/marquee.service"
sed -i "s|Environment=XDG_RUNTIME_DIR=.*|Environment=XDG_RUNTIME_DIR=/run/user/$user_id|" "$user_home/marquee.service"

if [[ "$arch" == "aarch64" ]]; then
    # 64-bit system: use KMSDRM
    sed -i '/^Environment=SDL_FBDEV=/d' "$user_home/marquee.service"
    sed -i "s|Environment=SDL_VIDEODRIVER=.*|Environment=SDL_VIDEODRIVER=KMSDRM|" "$user_home/marquee.service"
else
    # 32-bit system: use fbcon
    sed -i "s|Environment=SDL_VIDEODRIVER=.*|Environment=SDL_VIDEODRIVER=fbcon|" "$user_home/marquee.service"
fi

# 11. Install systemd service
echo "[11/12] Installing daemon service..."
sudo mv "$user_home/marquee.service" /etc/systemd/system/marquee.service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable marquee
sudo systemctl start marquee

echo "[12/12] Checking and configuring console autologin for user: $real_user"

# Path to autologin override
AUTOLOGIN_DIR="/etc/systemd/system/getty@tty1.service.d"
AUTOLOGIN_CONF="$AUTOLOGIN_DIR/autologin.conf"

# Check if autologin is already set for the correct user
if grep -q "agetty --autologin $real_user" "$AUTOLOGIN_CONF" 2>/dev/null; then
    echo "[Installer] Autologin already configured for $real_user, skipping."
else
    echo "[Installer] Enabling autologin for $real_user on tty1..."

    # Ensure directory exists
    sudo mkdir -p "$AUTOLOGIN_DIR"

    # Write or replace autologin config
    sudo tee "$AUTOLOGIN_CONF" > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $real_user --noclear %I \$TERM
EOF

    # Ensure getty is enabled (safe to call even if already enabled)
    sudo systemctl enable getty@tty1.service

    echo "[Installer] Autologin configured. Reboot required to apply."
fi

echo "✅ Installation complete! Reboot recommended."
