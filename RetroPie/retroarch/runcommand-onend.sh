#!/bin/sh -f

DIR="$(dirname "${3}")"

if [ -f $DIR/marquee/marquee.png ]
then
	ssh USERNAME@HOSTNAME "echo '$1'/marquee.png::" $DIR"/marquee/marquee.png::" $1"> /tmp/display.pipe"
else
	ssh USERNAME@HOSTNAME "echo retropie.png > /tmp/display.pipe"
fi
