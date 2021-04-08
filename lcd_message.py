#!/usr/bin/python

# https://learn.adafruit.com/drive-a-16x2-lcd-directly-with-a-raspberry-pi/python-code

from Adafruit_CharLCD import Adafruit_CharLCD
from subprocess import *
import time
import RPi.GPIO as GPIO
import commands
import os

GPIO.setmode(GPIO.BCM)

# Constants
message="Dave Hartburn\n07760 197 885"
LCDbl=8
buttonPin=7
apDelay=5	# Seconds to wait on button press before we go to AP mode

# ******* Functions *****************************************************
def getSSID():
	# Find the SSID and return string
	cmdout=str(commands.getstatusoutput("iwconfig wlan0 | grep ESSID"))
	# Output is in format 
	# wlan0     IEEE 802.11bgn  ESSID:"kudu-wifi"  Nickname:"<W
	p=cmdout.find("ESSID:")
	if(p==-1):
		# No network
		scrout="No wifi. 5s hold\nfor AP mode."
	else:
		p+=7
		q=cmdout[p:].find('"')
		ssid=cmdout[p:q+p]
		
		# Get the IP (taken from Adafruit)
		cmd = "ip addr show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1"
		ip=str(commands.getstatusoutput(cmd)[1])
		scrout=ssid+"\n"+ip
		
	return scrout
		
def display_message():
	# Display messages on LCD
	# Turn on LCD and backlight
	GPIO.output(LCDbl, True)
	lcd.display()
	lcd.clear()
	lcd.message(message)
	time.sleep(5)
	
	# Show network details
	netout=getSSID()
	lcd.clear()
	lcd.message(netout)
	time.sleep(5)
	
	# Turn off LCD
	lcd.noDisplay()
	GPIO.output(LCDbl, False)


def apMode():
	# Going into AP mode
	# Turn on LCD and backlight
	GPIO.output(LCDbl, True)
	lcd.display()
	lcd.clear()
	lcd.message("Enabling AP mode\n--------->")

	os.popen("/home/pi/wildbin/ap_on")
	time.sleep(5)

        # Show network details
        netout=getSSID()
        lcd.clear()
        lcd.message(netout)
        time.sleep(5)

	#lcd.clear()
	#lcd.message("Not really, no\ncode for it")
	#time.sleep(2)
	
	# Reboot while trying to get this to work
	#rebTime=10
	#lcd.clear()
	#lcd.message("Rebooting in "+str(rebTime)+"\nseconds.....")
	#time.sleep(rebTime)
	
	# Turn off LCD
	lcd.noDisplay()
	GPIO.output(LCDbl, False)
	
	#os.popen("reboot")
	


# ******* Main code *****************************************************

# Setup IO
GPIO.setup(LCDbl, GPIO.OUT)
GPIO.setup(buttonPin, GPIO.IN)

lcd = Adafruit_CharLCD()

# Display bootup message, ensure LCD is on
GPIO.output(LCDbl, True)
lcd.display()
lcd.clear()
lcd.message("Wildlife camera\nready")
time.sleep(2)

# Turn off the LCD 
GPIO.output(LCDbl, False)
lcd.noDisplay()

# Infinite loop waiting for button press
while True:
	if(GPIO.input(buttonPin)==False):
		pressTime=time.time()
		exitState=0
		# Loop until button is released or 5 seconds elapses
		while (exitState==0):
			time.sleep(0.25)
			if(GPIO.input(buttonPin)==True):
				# Button released
				exitState=1
				display_message()
			elif(time.time()-pressTime>apDelay):
				# Going to ap mode
				exitState=2
				apMode()
	time.sleep(0.25)



GPIO.cleanup()
