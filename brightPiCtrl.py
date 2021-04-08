#!/usr/bin/python

# Usage: brightPiCtl White|IR|Off [brightness: 0-4]

# Imports
import smbus
import time
import sys

# Set up bus and Bright Pi address
bus=smbus.SMBus(1)
bpi_address=0x70
IR_LED=0xa5
WHITE_LED=0x5a
ALL_ON=0xff
ALL_OFF=0x00

levels=[0x00, 0x10, 0x20, 0x30, 0x3f]
brightness=0x3f
if len(sys.argv)==3 :
	setl=int(sys.argv[2])
	if setl<5:
		brightness=levels[setl]

# Only continue if there are arguments, default to off
value=ALL_OFF
if len(sys.argv)>1:
	if sys.argv[1]=="White":
		# Turn on white light
		value=WHITE_LED
	if sys.argv[1]=="IR":
		# Turn on IR light
		value=IR_LED
	if sys.argv[1]=="Off":
		# Turn off
		value=ALL_OFF
		
	# Push up gain
	bus.write_byte_data(bpi_address, 0x09, 0x0f)

	# Turn brightness to max
	for x in range(1, 9):
		bus.write_byte_data(bpi_address, x, brightness)

	bus.write_byte_data(bpi_address, 0, value)

