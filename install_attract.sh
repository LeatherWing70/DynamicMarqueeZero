#!/bin/bash

repo_url="https://github.com/LeatherWing70/DynamicMarqueeZero.git"
attract_url="RetroPie/attract"
nut_path="/opt/retropie/configs/all/attractmode/plugins/dynamicmarquee.nut"
emulator_cfg_path="/opt/retropie/configs/all/attractmode/emulators"
case_blocks="case_blocks.txt"
attract_cfg="/opt/retropie/configs/all/attractmode/attract.cfg"

# 1. Gather marquee_user and marquee_hostname
echo "1. Gathering marquee hostname and user..."
read -rp "Enter user name marquee Pi [default: pi]: " input_username
marquee_user="${input_username:-pi}"
read -rp "Enter the hostname of your marquee Pi [default: marquee.local]: " input_hostname
marquee_hostname="${input_hostname:-marquee.local}"

# 2. Download Attract Mode files and set ownership
echo "2. Downloading Attract Mode files..."
temp_dir="$(mktemp -d)"
echo "Cloning only '$attract_url' from GitHub to '$temp_dir'..."
git clone --depth 1 --filter=blob:none --sparse "$repo_url" "$temp_dir" || { echo "Git clone failed"; exit 1; }

cd "$temp_dir" || { echo "Failed to enter $temp_dir"; exit 1; }
git sparse-checkout set "$attract_url"

# 3. Generate case_blocks.txt from .cfg files
echo "3. Parsing .cfg files and generating case_blocks.txt..."
> "$case_blocks"
for cfg in "$emulator_cfg_path"/*.cfg; do
	echo "$cfg"
	[[ -f "$cfg" ]] || continue
	cfg_name="$(basename "$cfg" .cfg)"
	rompath=$(grep -E "^rompath[[:space:]]+" "$cfg" | awk '{print $2}' | awk -F '/' '{print $NF}')
	[[ -n "$rompath" ]] && echo -e "\t\t\tcase \"$cfg_name\":\n\t\t\t\t\tmarqDir=\"$rompath\";\n\t\t\t\t\tbreak;\n" >> "$case_blocks"
done


# 4. Integrate case_blocks.txt into the .nut file
mkdir -p "$(dirname "$nut_path")"
if [ -n "$SUDO_USER" ]; then
	chown "$SUDO_USER":"$SUDO_USER" "$(dirname "$nut_path")"
fi

echo "4. Injecting emulator switch/case block into the .nut file..."
start_marker="// DYNAMIC_MARQUEE_SWITCH_START"
end_marker="// DYNAMIC_MARQUEE_SWITCH_END"

awk -v start="$start_marker" -v end="$end_marker" -v block="$(<"$case_blocks")" '
  BEGIN { in_block=0 }
  {
	if ($0 ~ start) {
	  print
	  print block
	  in_block = 1
	  next
	}
	if ($0 ~ end) {
	  in_block = 0
	}
	if (!in_block) print
  }
' "${attract_url}/dynamicmarquee.nut" > "${attract_url}/dynamicmarquee.nut.tmp" && mv "${attract_url}/dynamicmarquee.nut.tmp" "$nut_path"

# 5. Replace plugin_command and plugin_command_bg with echo-to-pipe schema
echo "5. Updating SSH command lines to push to the marquee pipe..."
sed -i "s|USERNAME@HOSTNAME|${marquee_user}@${marquee_hostname}|g" "$nut_path"

if [ -n "$SUDO_USER" ]; then
	chown "$SUDO_USER":"$SUDO_USER" "$nut_path"
fi
chmod +xw "$nut_path"


#6. Enable plugin
echo "6. Enabling Plugin"
# Detect if plugin is present
if grep -q -P '^\s*plugin\s+dynamicmarquee' "$attract_cfg"; then
	# Check if it's enabled
	if grep -A1 -P '^\s*plugin\s+dynamicmarquee' "$attract_cfg" | grep -q -P '^\s*enabled\s+yes'; then
		echo "dynamicmarquee plugin is already present and enabled."
	else
		echo "dynamicmarquee plugin is present but not enabled."
		read -p "Do you want to enable it? [Y/n]: " answer
		answer=${answer,,}  # to lowercase
		if [[ "$answer" =~ ^(y|yes|)$ ]]; then
			# Use sed to update 'enabled' line
			sed -i '/^\s*plugin\s\+dynamicmarquee/{n;s/^\s*enabled\s\+.*/\tenabled              yes/}' "$attract_cfg"
			echo "Plugin enabled."
		else
			echo "Plugin left disabled."
		fi
	fi
else
	echo "Adding dynamicmarquee plugin block to attract.cfg..."
	{
		echo ""
		echo -e "plugin\tdynamicmarquee"
		echo -e "\tenabled              yes"
	} >> "$attract_cfg"
	echo "Plugin block added."
fi

# 7. Clean up.
echo "7. cleaning up temp files"
# Clean up
cd /
rm -rf "$temp_dir"
