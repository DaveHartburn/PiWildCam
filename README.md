# PiWildCam

Early commit. A wildlife camera for the Raspberry Pi. It can sit as either a Pi and a camera module in a nextbox, or in a stand alone enclosure as a trailcam, with LCD screen for status and a PIR.

Full details and setup instructions pending.

First commit is something that just about works, but needs a lot of fiddling. Originally developed a number of years ago, so contains libraries and various ways of doing things that need a lot of improvement.

The web interface is awful!

### Usage

Based on a command line tool wildcam.py, the web interface provides a convenient way of using it.
```
Usage wildcam.py:
 -w <sec>  | --wait=<sec> : Seconds to wait before monitoring starts (default 0)
 -f <path> | --folder=<path> : Folder path to store captures (default /home/pi/video)
 -p <sec>  | --postcap=<sec> : Post capture delay before next video or still (default 1 second)
 -m v|s|t  | --mode=vid|still|tl : Capture mode - video, still or timelapse (default still)
 -c <sec>  | --caplen=<sec> : Number of seconds per video capture (default 10 seconds)
 -s <num>  | --stills=<num> : Number of stills to take on motion capture (default 1)
 -t <sec>  | --time=<sec> : Number of seconds between timelapse images or still multishoot
 	   (default 300 for timelapse or 1 second for still)
 -r XXXxYYY | --res=XXXXxYYYY: Capture resolution (default 2592x1944)
 -i w|i|n  | --iltype=white|ir|none : Illumination type - white, IR or none. (default IR)
 -j o|m|f  | --ilmode=on|off|motion :
    Illumination - Fixed on (o), off (f)  or only on motion detection (m default)
 -d p|i    | --detect=pir|image  : Motion detection method PIR or image analysis (p default)
 -l <file> | --log=<file>: Log file location (default, capture folder/wildcam.log)
 -h hhmm-hhmm | --hours=hhmm-hhmm : Only operate between times specified in hhmm format
    0000-2359 is 24x7
```
#### Examples:

Timelapse, every 10 minutes with no illumination, 640x480 resolution. Useful for birdbox.
`./wildcam.py --folder=/home/pi/wildcaps --mode=tl --time=600 --res=640x480 --iltype=none --ilmode=off`

Same timelapse again, only taking pictures between 8am and 5:30pm
`./wildcam.py --folder=/home/pi/wildcaps --mode=tl --time=600 --res=640x480 --iltype=none --ilmode=off ---hours=0800-1730`

### To do:
- [] Thumbnails on web interface
   - [] list number of captures
- [] More meaningful interface (longopts)
- [] mail still
- [] ftp/scp upload (config file?)
- [] upload limit
- [] high framerate mode
- [] debug feature
- [] log viewer
- [] smb connection
- [] webcam streaming
- [] More dynamic web interface
- [] Directory reshuffle
- [] Do we still need a root helper? Drop if we can
- [] Set up instructions
- [] Blog post
- [] Software motion detection
- [] Instant picture take on web interface
  - [] Allow changing of camera options?
