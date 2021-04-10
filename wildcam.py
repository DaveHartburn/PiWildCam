#!/usr/bin/python

# Wildlife camera control software - David Hartburn 2014
# Can also be used for other various motion detection and
# timelapse projects.
# For full info see **** URL ??? ************

# Using the raspistill/vid commands rather than the python modules
# as these seemed to give better control, or at least less to do within
# this code. Many pictures were appearing too dark or lacking in colour

# Import libries
import RPi.GPIO as GPIO
import time
#import picamera
import os
import sys, getopt
import string
import smbus
import logging

# Defaults
# Hardware
pirPin=17
RASPISTILL="/usr/bin/raspistill"
RASPIVID="/usr/bin/raspivid"
# Always have a leadingspace"
CAMOPTS=" -hf -vf -ex auto -t 500"
VIDOPTS=" -hf -vf -ex auto "
# Captures in h264, store temp and convert
VIDTMP="/tmp/wildcamvid.h264"

IR_LED=0xa5
WHITE_LED=0x5a
ALL_ON=0xff
ALL_OFF=0x00

loopDelay=0.25		# Small sleep in main loop to avoid CPU hammering

# Software settings (may be overridden by CLI switches
startWaitTime=0		# Time between software starting and monitoring
folderPath="/home/pi/wildcaps"	# Storage location
postCapDelay=1		# Time to wait between captures
capMode='s'		# still, video or timelapse (svt)
vidCapTime=10		# Time in seconds for video capture
numStill=1		# Number of stills to take on capture
tlDelay=300		# Time between timelapse images
resX=2592		# X resolution
resY=1944		# Y resolution
ilType='i'		# Illumination, white, IR or none (irn)
ilMode='m'		# Trigger illumination on motion or always on (om)
mDetect='p'		# Motion detect on image analysis or PIR (pi)
logFile=folderPath+"/wildcam.log"	# Log location
timeStart=0000  # Time of operating hours start
timeEnd=2359    # Time of operating hours end



# *** Functions **************************************
def debug(str):
	# Need to check for debugging mode here
	print "DEBUG:"+str
	logging.debug(str)

def usage():
	print("Usage wildcam.py:")
	print("	 -w <sec>  | --wait=<sec> : Seconds to wait before monitoring starts (default 0)")
	print("	 -f <path> | --folder=<path> : Folder path to store captures (default /home/pi/video)")
	print("	 -p <sec>  | --postcap=<sec> : Post capture delay before next video or still (default 1 second)")
	print("	 -m v|s|t  | --mode=vid|still|tl : Capture mode - video, still or timelapse (default still)")
	print("	 -c <sec>  | --caplen=<sec> : Number of seconds per video capture (default 10 seconds)")
	print("	 -s <num>  | --stills=<num> : Number of stills to take on motion capture (default 1)")
	print("	 -t <sec>  | --time=<sec> : Number of seconds between timelapse images or still multishoot")
	print("	 	   (default 300 for timelapse or 1 second for still)")
	print("	 -r XXXxYYY | --res=XXXXxYYYY: Capture resolution (default 2592x1944)")
	print("	 -i w|i|n  | --iltype=white|ir|none : Illumination type - white, IR or none. (default IR)")
	print("	 -j o|m|f  | --ilmode=on|off|motion :")
	print("	    Illumination - Fixed on (o), off (f)  or only on motion detection (m default)")
	print("	 -d p|i    | --detect=pir|image  : Motion detection method PIR or image analysis (p default)")
	print("	 -l <file> | --log=<file>: Log file location (default, capture folder/wildcam.log)")
	print("	 -h hhmm-hhmm | --hours=hhmm-hhmm : Only operate between times specified in hhmm format")
	print("	    0000-2359 is 24x7")

def checkArgs():
	try:
		opts, args = getopt.getopt(sys.argv[1:],"w:f:p:m:c:s:t:r:i:j:d:l:h:",
		  ['wait=', 'folder=', 'postcap=', 'mode=', 'caplen=', 'stills=',
		  'time=', 'res=', 'iltype=', 'ilmode=', 'detect=', 'log=', 'hours=', 'help'])
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	for opt, arg in opts:
		if opt in ["-w", "--wait"]:
			global startWaitTime
			startWaitTime=int(arg)
		elif opt in ["-f", "--folder"]:
			global folderPath
			folderPath=arg
		elif opt in ["-p", "--postcap"]:
			global postCapDelay
			postCapDelay=int(arg)
		elif opt in ["-m", "--mode"]:
			# Can be v, s or t
			global capMode
			if(arg in ['v','s','t','vid','still','tl']):
				# Only take the first character
				capMode=arg[0]
			else:
				print "Invalid capture mode", arg
				sys.exit(1)
		elif opt in ["-c", "--caplen"]:
			global vidCapTime
			vidCapTime=int(arg)
			# print("Video cap time = "+str(vidCapTime))
		elif opt in ["-s", "--stills"]:
			global numStill
			numStill=int(arg)
			#print("Number of stills is "+str(numStill))
		elif opt in ["-t", "--time"]:
			global tlDelay
			tlDelay=int(arg)
			#print("Time delay = "+str(tlDelay))
		elif opt in ["-r", "--res"]:
			global resX
			global resY
			tmp=arg.split("x")
			resX=int(tmp[0])
			resY=int(tmp[1])
			#print("Resolution=",str(resX),str(resY))
		elif opt in ["-i", "--iltype"]:
			global ilType
			if(arg in ['w', 'i', 'n', 'white', 'ir', 'none']):
				ilType=arg[0]
			else:
				print "Invalid illumination type (-i w|i|n)", arg
				sys.exit(1)
			#print("Illumination type="+ilType)
		elif opt in ["-j", "--ilmode"]:
			global ilMode
			if(arg in ['o', 'f', 'm', 'on', 'off', 'motion']):
				if(arg=='off'):
					ilMode='f'
				else:
					ilMode=arg[0]
			else:
				print "Invalid illumination mode (-j o|m|f)", arg
				sys.exit(1)
			#print("Illumination mode = "+ilMode)
		elif opt in ["-d", "--detect"]:
			global mDetect
			if(arg in ['p', 'i', 'pir', 'image']):
				mDetect=arg[0]
			else:
				print "Invalid motion detect mode (-d p|i)", arg
				sys.exit(1)
			#print("Detection = "+mDetect)
		elif opt in ["-l","--log"]:
			global logFile
			logFile=arg
			#print("Logging to "+logFile)
		elif opt in ["-h", "--hours"]:
			global timeStart, timeEnd
			tmp=arg.split("-")
			timeStart=int(tmp[0])
			timeEnd=int(tmp[1])
			#print("Time start & end = ", timeStart, timeEnd)
		elif opt=="--help":
			usage()
			sys.exit(0)

def getFilename():
	# Return a base filename (without extension) based on the time
	# Assume it is not quick enough to be called more than once in the same second
	txtTime=time.strftime("wildcam_%Y_%m_%d_%H%M%S")
	return folderPath+"/"+txtTime

def takePicture():
	# Takes a single snap
	# ***** Add illumination control *****

	# Get time in hhmm format
	curTime=time.localtime()[3]*100+time.localtime()[4]
	#print("curTime, timeStart, timeEnd", curTime, timeStart, timeEnd)

	# Take picture if valid
	if(curTime>=timeStart and curTime<=timeEnd):
		cmdBase=RASPISTILL+CAMOPTS
		baseFilename=getFilename()
		debug("Saving "+baseFilename+".jpg")
		cmd=RASPISTILL+CAMOPTS+" -w "+str(resX)+" -h "+str(resY)+" -o "+baseFilename+".jpg"
		debug("Command :"+cmd)
		os.system(cmd)
	else:
		debug("Out of time period, no picture taken")

def doTimelapse():
	exitState=0
	while exitState==0:
		takePicture()
		debug("Timelapse - sleeping")
		time.sleep(tlDelay)


def doMotionDetect():
	newMotion=0
	exitState=0

	# Loop until something sets exitstate to 1
	while exitState==0:
		# Just doing PIR detection for now
		pirInput = GPIO.input(pirPin)
		if(pirInput==1):
			# Sensor is high, what was last state?
			if(newMotion==0):
				# A new detect
				newMotion=1

				# Do we turn on LEDs?
				if(ilMode=="m") :
					debug("Turning on LEDs")
					if(ilType=="w"):
						bus.write_byte_data(bpi_address, 0, WHITE_LED)

					if(ilType=="i"):
						bus.write_byte_data(bpi_address, 0, IR_LED)




				debug("**********Taking picture*********")

				# Video or still?
				if(capMode=='v'):
					# Doing video
					baseFilename=getFilename()
					debug("Saving tmp video "+VIDTMP);
					cmd=RASPIVID+VIDOPTS+" -o "+VIDTMP+" -w "+str(resX)+" -h "+str(resY)+" -t "+str(vidCapTime*1000);
					debug("Command :"+cmd);
					os.system(cmd)
					debug("Saved image, converting....")
					#cam.start_recording("/tmp/video.h264")
					#cam.wait_recording(5)
					#cam.stop_recording
					#print "Sorry, can't do video"

					# Convert to MP4
					os.system("MP4Box -add "+VIDTMP+" "+baseFilename+".mp4")
					os.system("rm "+VIDTMP)

				else:
					# Doing still(s)
					for i in range (0, numStill):
						takePIcture()
						# Delay between pictures
						time.sleep(postCapDelay)


				# Do we turn off LEDs?
				if(ilMode=="m") :
					debug("Turning off LEDs");
					bus.write_byte_data(bpi_address, 0, ALL_OFF)


				# Delay between image capture
				debug("Post capture delay for "+str(postCapDelay))
				time.sleep(postCapDelay)
				debug("Delay complete")

				#exitState=1
		else:
			if(newMotion==1):
				# Movement has gone away
				newMotion=0
				print "Bye bye"
				# Wait to make sure it is not a sensor flap
				time.sleep(2)

		#print "PIR state is: ",pirInput
		time.sleep(loopDelay)

# *** Main code ***************************************




# Parse command line arguments
checkArgs()

print("Illumination type is "+ilType)

# Initialize BrightPi and turn off LEDs, if we have an illumination mode set
if(ilType!='n'):
	# Set up bus and Bright Pi address
	bus=smbus.SMBus(1)
	bpi_address=0x70
	# Make sure all LEDs are off
	bus.write_byte_data(bpi_address, 0, ALL_OFF)
	# Push up gain
	bus.write_byte_data(bpi_address, 0x09, 0x0f)
	# Turn brightness to max
	for x in range(1, 9):
		bus.write_byte_data(bpi_address, x, 0x3f)

# Does capture destination exist?
if(os.path.isdir(folderPath)==False):
	# No, throw error
	print "Error: Capture folder "+folderPath+" does not exist"
	sys.exit(1)

# Does logfile location exist?
lastSlash=string.rfind(logFile, "/")
# If -1 there is no path, directory is local so all is fine
if(lastSlash!=-1):
	lPath=logFile[0:lastSlash]
	if(os.path.isdir(lPath)==False):
		# No, throw error
		print "Error: Log file folder "+lPath+" does not exist"
		sys.exit(1)

# All checks out, hope the supplied arguments are sane and get started....
logging.basicConfig(filename=logFile,level=logging.DEBUG)
print "Logging to ",logFile

# Sleep delay
time.sleep(startWaitTime)

# Set up the camera
#cam=picamera.PiCamera()
#cam.resolution = (resX, resY)

# Set up GPIO pins
# PIR
if(mDetect=='p'):
	GPIO.setmode(GPIO.BCM)
	GPIO.setup(pirPin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

# Do we turn the LEDs on?
if(ilMode=="o") :
	debug("Turning on LEDs")
	if(ilType=="w"):
		bus.write_byte_data(bpi_address, 0, WHITE_LED)

	if(ilType=="i"):
		bus.write_byte_data(bpi_address, 0, IR_LED)

if(capMode=='t'):
	doTimelapse()
else:
	doMotionDetect()

print "Done"
