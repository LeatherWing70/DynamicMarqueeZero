#!/bin/sh -f

script_name=$(basename $0)
for pid in $(pidof -x $script_name); do
    if [ $pid != $$ ]; then
        kill -9 $pid
    fi 
done

DIR="$(dirname "${2}")" ; FILE="$(basename "${2}")"
GAME=${FILE%.*}
EMU=$1

if [ -f $DIR/marquee/"$GAME".mp4 ]
then
    SOURCE=$DIR/marquee/$GAME.mp4
	CACHE=$1/$GAME.mp4
elif [ -f $DIR/marquee/"$GAME".mpg ]
then
    SOURCE=$DIR/marquee/$GAME.mpg
	CACHE=$1/$GAME.mpg
elif [ -f $DIR/marquee/"$GAME".png ]
then
    SOURCE=$DIR/marquee/$GAME.png
	CACHE=$1/$GAME.png
elif [ -f $DIR/marquee/"$GAME".jpg ]
then
    SOURCE=$DIR/marquee/$GAME.jpg
	CACHE=$1/$GAME.jpg
elif [ -f $DIR/marquee/"$GAME".bmp ]
then
    SOURCE=$DIR/marquee/$GAME.bmp
	CACHE=$1/$GAME.bmp
elif [ -f $DIR/marquee/"$GAME".tiff ]
then
    SOURCE=$DIR/marquee/$GAME.tiff
	CACHE=$1/$GAME.tiff
elif [ -f $DIR/marquee/"$GAME".gif ]
then
    SOURCE=$DIR/marquee/$GAME.gif
	CACHE=$1/$GAME.gif
else
	SOURCE=""
	CACHE="retropie.png"
	EMU=""
fi

(sleep .3 && ssh USERNAME@HOSTNAME "echo \""$CACHE"::"$SOURCE"::"$EMU" > /tmp/display.pipe\"")&
