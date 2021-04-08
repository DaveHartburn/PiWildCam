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

# Initialize BrightPi and turn off LEDs
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


# *** Functions **************************************
def debug(str):
	# Need to check for debugging mode here
	print "DEBUG:"+str
	logging.debug(str)
	
def checkArgs():
	try:
		opts, args = getopt.getopt(sys.argv[1:],"w:f:p:m:c:s:t:r:i:j:d:l:")
	except getopt.GetoptError:
		print "Usage: sdfsdf sd fsdf sd"
		sys.exit(2)
	for opt, arg in opts:
		if opt in ("-w"):
			global startWaitTime
			startWaitTime=int(arg)
		elif opt in ("-f"):
			global folderPath
			folderPath=arg
		elif opt in ("-p"):
			global postCapDelay
			postCapDelay=int(arg)
		elif opt in ("-m"):
			# Can be v, s or t
			global capMode
			if(arg=="v" or arg=="s" or arg=="t"):
				capMode=arg
			else:
				print "Invalid capture mode", arg
				sys.exit(1)
		elif opt in ("-c"):
			global vidCapTime
			vidCapTime=int(arg)
		elif opt in ("-s"):
			global numStill
			numStill=int(arg)
		elif opt in ("-t"):
			global tlDelay
			tlDelay=int(arg)
		elif opt in ("-r"):
			global resX
			global resY
			tmp=arg.split("x")
			resX=int(tmp[0])
			resY=int(tmp[1])
		elif opt in ("-i"):
			global ilType
			if(arg=="w" or arg=="i" or arg=="n"):
				ilType=arg
			else:
				print "Invalid illumination type (-i w|i|n)", arg
				sys.exit(1)
		elif opt in ("-j"):
			global ilMode
			if(arg=="o" or arg=="m" or arg=="f"):
				ilMode=arg
			else:
				print "Invalid illumination mode (-j o|m|f)", arg
				sys.exit(1)
		elif opt in ("-d"):
			global mDetect
			if(arg=="p" or arg=="i"):
				mDetect=arg
			else:
				print "Invalid motion detect mode (-d p|i)", arg
				sys.exit(1)
		elif opt in ("-l"):
			global logFile
			logFile=arg

def getFilename():
	# Return a base filename (without extension) based on the time
	# Assume it is not quick enough to be called more than once in the same second
	txtTime=time.strftime("wildcam_%Y_%m_%d_%H%M%S")
	return folderPath+"/"+txtTime
	
def doTimelapse():
	print "Sorry, no timelapse function yet"
	
def doMotionDetect():
	newMotion=0
	exitState=0

	# Loop until something sets exitstate to 1
	cmdBase=RASPISTILL+CAMOPTS
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
						baseFilename=getFilename()
						debug("Saving "+baseFilename+".jpg")
						cmd=RASPISTILL+CAMOPTS+" -w "+str(resX)+" -h "+str(resY)+" -o "+baseFilename+".jpg"
						debug("Command :"+cmd)
						os.system(cmd)
						debug("Saved image")

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
