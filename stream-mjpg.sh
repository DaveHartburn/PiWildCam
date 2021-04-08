#!/bin/bash

# Start or stop the mjpg streamer
case "$1" in
  start)
    echo Starting streamer
    /usr/local/bin/mjpg_streamer -i "input_raspicam.so -hf -vf -x 640 -y 480" -o "output_http.so -p 8080 -w /usr/local/share/mjpg-streamer/www" >/dev/null 2>&1 &
    ;;
  stop)
    echo Stopping streamer
    killall mjpg_streamer
    ;;
  *)
    echo Unkown arguments, use start or stop
    exit 1
    ;;
esac
exit 0
