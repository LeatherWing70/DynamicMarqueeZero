#!/bin/sh -f

DIR="$(dirname "${3}")"

if [ -f $DIR/marquee/marquee.png ]
then
	ssh pi@marquee.local "/home/pi/t.sh '$1'/marquee.png" $DIR"/marquee/marquee.png" $1
else
	ssh pi@marquee.local "/home/pi/t.sh retropie.png"
fi
