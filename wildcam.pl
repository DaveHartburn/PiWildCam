#!/usr/bin/perl

# Perl script to show status and allow config
# Not using CSS or anything modern and friendly!
# By Dave Hartburn 2015

use strict;
use warnings;
use CGI;

my $apssid="wildcam";
my $roothelp="/home/pi/wildbin/roothelp";
my $logfile="/home/pi/wildcaps/wildcam.log";


my $myurl="http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}";
$myurl =~ s/\?press=1//;

my ($cmdout, $button, $streambut, $cambut);

print "Content-type: text/html\n\n";

print "<html><head>\n";

# Intercept log file view
if($myurl =~ /viewlog/) {
	print "<title>wildcam.log</title></head><body>\n";
	print "<a href='/'>Return</a>\n";
	print "<pre>\n";
	open(FILE, '<', $logfile) or die $!;
	while(<FILE>) {
		print $_;
	}
	print "</pre></body></html>\n";
	exit;
}
	

# Do we need to process any POST data?
if($ENV{CONTENT_LENGTH}!=0) {
	# Set refresh in 5 seconds and reload
	print "<META HTTP-EQUIV=\"refresh\" CONTENT=\"5; URL=$myurl\">\n";
	print "<title>Processing</title></head>\n";
	print "<h1>Processing input, please wait. Debugging messages below</h1>\n";
	process_input();	
	print("</html>");
} else {

	print "<title>Wildcam</title>\n";
	print "</head><body>\n";
	print "<h1>Wildcam status & Config</h1>\n";


	print "<form method='POST' action='$myurl?press=1'>\n";
	print "<table border='1'>\n";

	# Are we running in AP mode?
	print "<tr><td><b>AP Mode:</b></td><td>\n";
	$cmdout=`/sbin/iwconfig wlan0`;
	$cmdout =~ /ESSID:"(.*)"/;
	my $ssid=$1;
	if($ssid eq $apssid) {
		print "Running in AP mode - SSID=$ssid";
		print "</td><td>";
		print "<input type='submit' name='action' value='Switch to infrastructure'>";
	} else {
		print "Connected to infrastructure wifi - SSID=$ssid";
		print "</td><td>";
		print "<input type='submit' name='action' value='Switch to AP mode'>";
	}
	print "<input type='submit' name='action' value='Wifi Off'></td></tr>\n";



	# Is streaming mode on?
	print "<tr><td><b>Streamer running?:</b></td><td>\n";
	if(system("ps -eo args | grep '^/usr/local/bin/mjpg_streamer' > /dev/null")) {
		print "Not running";
		$streambut="Streamer On";
	} else {
		my $link="http://$ENV{'HTTP_HOST'}:8080/?action=stream";
		#print "Running (<a href=\"$link\">$link</a>)";
		print("<iframe src=\"$link\" width=640 height=480></iframe>");
		$streambut="Streamer Off";
	}
	print "</td><td><input type='submit' name='action' value='$streambut'></td></tr>\n";


	# Allow turning on of LEDs
	print "<tr><td><b>LED Control:</b></td>\n";
	print "<td><input type='radio' name='led' value='White'>White\n";
	print "<input type='radio' name='led' checked='checked' value='IR'>IR\n";
	print "<input type='radio' name='led' value='Off'>Off\n<br>";
	print "<b>Brightness:</b><select name='brightness'>\n";
	print "  <option value='0'>0%</option>\n";
	print "  <option value='1'>25%</option>\n";
	print "  <option value='2'>50%</option>\n";
	print "  <option value='3'>75%</option>\n";
	print "  <option value='4' selected>100%</option>\n";
	print "</select></td>\n";

	print "<td><input type='submit' name='action' value='Change LED'></td></tr>\n";



	# Report disk space
	print "<tr><td><b>Disk space:</b></td>\n";
	my $diskspace=`df -h /`;
	print "<td><pre>$diskspace</pre></td><td></td></tr>\n";

	# Link to thumbnails
	print "<tr><td><b>Captures:</b></td>\n";
	print "<td><a href='/wildcaps/index.pl'>Thumbnails</a>\n";
	print " or paste \\\\$ENV{'HTTP_HOST'}\\wildcaps\\ into explorer</td>\n";
	print "<td></td></tr>\n";

	# Is wildcam running?
	print "<tr><td><b>Wildcam running?:</b></td><td>\n";
	if(system("ps -ef | grep 'wildcam.py' |grep -v 'grep' > /dev/null")) {
		print "Not running";
		start_cam_opts();
		$cambut="Run Wildcam";
	} else {
		print "Running ....";
		$cambut="Terminate Wildcam";
	}
	print "</td><td><input type='submit' name='action' value='$cambut'></td></tr>\n";


	# Allow Pi power off
	print "<tr><td><b>Power:</b></td><td>On!</td>\n";
	print "<td><input type='submit' name='action' value='Power Off'></td>\n";
	print "</tr>\n";

	# Show logfile
	my $lfile=`ls -lh $logfile`;
	print "<tr><td><b>Logfile:</b></td>\n";
	print "<td><a href='?viewlog=1'><pre>$lfile</pre></a></td>\n";
	print "<td><input type='submit' name='action' value='Clear Log'></td></tr>\n";

	print "</table>\n";

	print "</form>\n";



	# Debugging!

	#print"<pre>";
	#foreach my $key (sort keys(%ENV)) {
	#  print "$key = $ENV{$key}<p>";
	#}
	#print "</pre>\n";


	print "</body>\n";
	print "</html>\n";
}
exit; 

# ***************************************************

sub process_fork {
	# Process the inputs in the background
	my $pid = fork;
	return if $pid;	# In the parent
	process_input();
	exit;
}

sub process_input {
	# Decode command line options
	my $cgi = CGI->new();
	my %vars = $cgi->Vars;

	# Read raw POST data
	my ($var, $value, $bright, $led, $cmdout);
	
	$var=$vars{'action'};
	
	print "<p>Button press was $var</p>\n";
	
	# Action on buttons
	if($var eq "Streamer On") {
		$cmdout=`$roothelp streamer_on`;
	}
	if($var eq "Streamer Off") {
		$cmdout=`$roothelp streamer_off`;
	}
	if($var eq "Power Off") {
		$cmdout=`$roothelp poweroff`;
	}
	if($var eq "Wifi Off") {
		$cmdout=`$roothelp wifioff`;
	}
	if($var eq "Switch to infrastructure") {
		$cmdout=`$roothelp wifiinf`;
	}
	if($var eq "Switch to AP mode") {
		$cmdout=`$roothelp wifiap`;
	}
	if($var eq "Change LED") {
		# Changing LED status, extract other values
		$led=$vars{'led'};
		
		$bright=$vars{'brightness'};
		
		print "Changing LED......$led +++  $bright";
		
		# Validate input before it gets sent off to 
		# a SUID program
		my @vled = ("White", "IR", "Off");
		my @vbright = ("0", "1", "2", "3", "4");
		if( grep ( /^$bright$/, @vbright) && 
		  grep ( /^$led$/, @vled) ) {
			$cmdout=`$roothelp ledctrl $led $bright`;
		}
		# No else, just ignore whoever has been messing
	}
	if($var eq "Run Wildcam") {
		my $cam=launch_wildcam(%vars);
		$cmdout=`$roothelp wildcam $cam`;
	}
	if($var eq "Terminate Wildcam") {
		$cmdout=`$roothelp killwildcam`;
	}
	if($var eq "Clear Log") {
		$cmdout=`$roothelp clearlog`;
	}
	print "<pre>$cmdout</pre>";
}

sub start_cam_opts {
	# Formatted a table in a table - yuk 
	print "<table>\n";
	
	print "<tr><td><b>Wait before monitoring starts (sec): </b></td>\n";
	print "<td><input type='text' name='waitsec' size=10 value='3'></td></tr>\n";
	print "<tr><td><b>Folder to store images:</b></td>\n";
	print "<td><input type='text' name='folder' value='/home/pi/wildcaps'></td></tr>\n";
	print "<tr><td><b>Post capture delay:</b><br><i>Time to wait idle after each still or video</i></td>\n";
	print "<td><input type='text' name='postcap' value='1'></td></tr>\n";

	print "<tr><td><b>Capture mode:</b></td>\n";
	print "<td><select name='capmode'><option value='s'>Stills</option>\n";
	print "<option value='v'>Video</option><option value='t'>Timelapse</option>\n";	
	print "</select></td></tr>\n";

	print "<tr><td><b>Seconds per video capture: </b></td>\n";
	print "<td><input type='text' name='capsec' size=10 value='10'></td></tr>\n";
	print "<tr><td><b>Number of stills on motion detect: </b>";
	  print "<br><i>Will multishoot a number of frames</i></td>\n";
	print "<td><input type='text' name='numstill' size=10 value='3'></td></tr>\n";
	print "<tr><td><b>Seconds between timelapse or still multishoot: </b></td>\n";
	print "<td><input type='text' name='tsec' size=10 value='1'></td></tr>\n";
	
	print "<tr><td><b>Capture resolution</b></td>\n";
	#print "<td><input type='text' name='resolution' value='640x480'></td></tr>\n";
	print "<td><select name='resolution'><option value='640x480'>640x480</option>\n";
	print "<option value='1296x792'>1296x792</option>\n";
	print "<option value='1920x1080'>1920x1080</option>\n";
	print "<option value='2592x1944'>2592x1944</option>\n";
	print "</select></td></tr>\n";
	
	print "<tr><td><b>Illumination:</b></td>\n";
	print "<td><select name='illumin'><option value='i'>IR</option>\n";
	print "<option value='w'>White</option><option value='n'>None</option>\n";	
	print "</select></td></tr>\n";

	print "<tr><td><b>Illumination mode:</b></td>\n";
	print "<td><select name='illmode'><option value='m'>On motion</option>\n";
	print "<option value='o'>Always on</option><option value='f'>Always off</option>\n";	
	print "</select></td></tr>\n";
	
	print "<tr><td><b>Motion detect method:</b></td>\n";
	print "<td><select name='motion'><option value='p'>PIR</option>\n";
	print "<option value='i'>Software</option>\n";	
	print "</select></td></tr>\n";

	print "</table>\n";
	
}

sub launch_wildcam {
	my (%v) = @_;
	
	my $camopts="-w $v{'waitsec'} -f $v{'folder'} -p $v{'postcap'} -m $v{'capmode'} ";
	$camopts.="-c $v{'capsec'} -s $v{'numstill'} -t $v{'tsec'} -r $v{'resolution'} ";
	$camopts.="-i $v{'illumin'} -j $v{'illmode'} -d $v{'motion'}";
	
	print "<pre>Cam options $camopts</pre>\n";
	
	return $camopts;
}
