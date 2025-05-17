#!/bin/sh -f

DIR="$(dirname "${3}")" ; FILE="$(basename "${3}")"
GAME=${FILE%.*}

#if Maquee exists on RetroPie
if [ -f $DIR/marquee/$GAME.png ]
then
	ssh USERNAME@HOSTNAME "echo "$1"/"$GAME".png::"$DIR"/marquee/"$GAME".png::" $1"> /tmp/display.pipe"
# else default marquee
else 
	if [ -f $DIR/marquee/marquee.png ]
	then
		ssh USERNAME@HOSTNAME "echo "$1"/"$GAME".png::" $DIR"/marquee/marquee.png::" $1"> /tmp/display.pipe"
	else
		ssh USERNAME@HOSTNAME "echo retropie.png > /tmp/display.pipe"
	fi
fi
