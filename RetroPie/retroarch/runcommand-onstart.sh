#!/bin/sh -f

DIR="$(dirname "${3}")" ; FILE="$(basename "${3}")"
GAME=${FILE%.*}

#if Maquee exists on RetroPie
if [ -f $DIR/marquee/$GAME.png ]
then
	ssh pi@marquee.local "/home/pi/t.sh "$1"/"$GAME".png" $DIR"/marquee/"$GAME".png" $1
# else default marquee
else 
	if [ -f $DIR/marquee/marquee.png ]
	then
		ssh pi@marquee.local "/home/pi/t.sh "$1"/"$GAME".png" $DIR"/marquee/marquee.png" $1
	else
		ssh pi@marquee.local "/home/pi/t.sh retropie.png"
	fi
fi
