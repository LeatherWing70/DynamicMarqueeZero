# DynamicMarqueeZero
Dynamic Marquee for Retropi using a Pi Zero (2) to drive the display instead of using the second HDMI on a 4/5 and making it possible for Pi 3 owners to run a dynamic marquee cheeply.  If video marquees become avalable this could easily be modfied to run them while adding 0 CPU load to RetroPie and its emulators

## This ain't great
I've hammered these scripts out of neccesity, because I have a Pi 5, and currently there are no other options to run a dynamic marquee on RetroPie and Bookworm.  In my parlance: It's like useing a sledgehammer to drive a finishing nail.

## Installation and todo for setup script if this gets any attention
### On the pi Zero (marquee or marqueepi from here on)
Set up a Pi Zero (or any pi) with the lite version (no gui), ssh enabled, and wi-fi configured (headless configuration) <br>
Edit settings to fit your uws display, ie add to /boot/config.txt:
```
hdmi_drive=2
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1920 360 60
```
run the following commands on the marqueepi<br>
This is to make sure there are no errors about localazation settings on the two Pis when transfering files
```
sudo nano /etc/locale.gen  <-- you will run this on retropie as well. Make sure they match
sudo locale-gen LC_ALL
```

these commands allow automatic secure file transfer without having to manually enter or hardcode passwords
```
ssh-keygen -t rsa <-- accept default settings
ssh-copy-id pi@retropie.local

ssh pi@retropie.local  <-- You will be asked to save the figerprint of the RetroPie, type yes then you can just type exit to end ssh.
```

Install and setup the marqueepi side of the scripts
```
sudo apt-get -y install fbi
mkdir ~/cache
```
download or copy marquee/t.sh to ~/<br>
download or copy copy retropie.png to ~/cache<br>
if you want a default image on boot use 'sudo nano .bashrc' and add this to the last line:  (rquires autologin to be set in raspi-config)
```
sudo ~/t.sh retropie.png
```

### On the RetroPie via console or ssh
Run the following commands
```
sudo nano /etc/locale.gen  <-- See, told ya. Make sure they match
sudo locale-gen LC_ALL
ssh-keygen -t rsa
ssh-copy-id pi@marquee.local
ssh pi@marquee.local  <-- You will be asked to save the figerprint of the RetroPie, type yes then you can just type exit to end ssh.
```

## Two ways to run Dynamic Marquee Zero
### 1)  Via Attract mode plugin
download or copy attract/dynamicmarquee.nut to ~/.attract/plugins<br>
Edit dynamicmarquee.nut.  There is a long switch/case section in the function updateTick.  Each case should match your configured emmulators in ~/.attract/emulators<br>
Configured emmulators should all have a "marquee" artwork folder defined.  This is the path DynamicMarqueeZero will use to send images to the marqueepi<br>
Run attractmode and enable dynamicmarquee in the plugins section of settings.<br>
A default 'marquee.png' (jpg, ect) can be placed in each layout folder you use to display your games<br>
<B>Enjoy</B>

### 2) Via runcommand launching and exiting games (only supports .png files currently)
download or copy runcommand-onstart.sh and runcommand-onend.sh to /opt/retropie/confgis/all<br>
These scripts assume there is a 'marquee' directory in the roms directory<br>
A default 'marquee.png' can be placed in the roms/[emulator]/marquee directory
