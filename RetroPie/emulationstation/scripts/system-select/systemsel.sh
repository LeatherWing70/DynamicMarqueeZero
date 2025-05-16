#!/bin/sh -f

script_name=$(basename $0)
for pid in $(pidof -x $script_name); do
    if [ $pid != $$ ]; then
        kill -9 $pid
    fi 
done

if [ -f /home/pi/RetroPie/roms/$1/marquee/marquee.png ]; then
    SOURCE=/home/pi/RetroPie/roms/$1/marquee/marquee.png
	CACHE=$1/marquee.png
	EMU=$1
else
	SOURCE=""
	CACHE="retropie.png"
	EMU=""
fi
	
(sleep .3 && ssh USERNAME@HOSTNAME "echo \""$CACHE"::"$SOURCE"::"$EMU" > /tmp/display.pipe\"")&
