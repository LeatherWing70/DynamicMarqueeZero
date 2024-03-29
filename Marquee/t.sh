#!/bin/sh
DIR="$(dirname "${1}")" ; FILE="$(basename "${1}")"


# Find the instances of fbi already running
process=$(pgrep -f 'fbi')

# if the emulator was given in command line args, and a dir dosent exist, make one

# if $3 == "store or missing"
# write $2 to file
if [ -n $3 ] && [ ! -d /home/pi/cache/$3 ]
then
    mkdir /home/pi/cache/$3
fi

# Don't know why I used cacheimg here, probably trying to solve the "Space in filname" problem
# could be [ ! -f /home/pi/cache/$1 ]  with some quoting around $1 maybe?
cacheimg=/home/pi/cache/$1
#echo chcheimg is $cacheimg >>~/t.txt

# if the requested file to display doesn't exist in cache, and command line gave a location, download it 
if [ ! -f "$cacheimg" ] && [ -n "$2" ]
then

    #set up sftp command file in ramdisk memory for faster access
    echo lcd /home/pi/cache>/dev/shm/sftp.commands
    echo get \"$2\" \"$1\">>/dev/shm/sftp.commands
    echo exit >>/dev/shm/sftp.commands
    # pull the remote file with config
    sftp -b /dev/shm/sftp.commands pi@retrocade.local

     # scp just becaue too much of a problem with weird filnames, and pretty much runs sftp in the background anyway
     # so I used sftp dirrectly to solve the problem and speed the script
#    scp -T \"pi@retrocade.local:\'$2\'\" \"/home/pi/cache/$DIR/\'$FILE\'\"

fi

# create the playlist in ramdisc for fbi.  again to solve the "space in filename" problem
echo /home/pi/cache/$1>/dev/shm/playlist

# killing fbi instances in $process
for i in $process
do
   sudo kill $i
done
# would rather launch this afer the new instance of fbi, but the new instance seems to close as well

# TODO
# check file type and launch fbi or cvlc as appopriate


# start a new instance of fbi with the new playlist
sudo fbi -d /dev/fb0 -T 1 --noverbose -a -l /dev/shm/playlist
