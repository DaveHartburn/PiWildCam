#!/usr/bin/perl

# Perl script to show status and allow config
# By Dave Hartburn 2015

use strict;
use warnings;
use CGI;
use Proc::Daemon;

my $apssid="wildcam";
my $binpath="/home/pi/wildbin";
my $roothelp="/home/pi/wildbin/roothelp";
my $logfile="/home/pi/wildcaps/wildcam.log";


my $myurl="http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}";
$myurl =~ s/\?press=1//;

my ($cmdout, $button, $streambut, $cambut);

print "Content-type: text/html\n\n";

print "<html><head>\n";
print "<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>\n";
print "<link rel='STYLESHEET' href='styles.css' type='text/css'>\n";
print "<script src='webgui.js'></script>\n";
print "</head><body>\n";

# Intercept log file view
if($myurl =~ /viewlog/) {
	print "<title>wildcam.log</title>";
	print "<button onClick='javascript:history.back()'>Back</button>\n";
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
	#print "<META HTTP-EQUIV=\"refresh\" CONTENT=\"5; URL=$myurl\">\n";
	print "<title>Processing</title></head>\n";
	print "<h1>Processing input, please wait. Debugging messages below</h1>\n";
	process_input();
	print("</html>");
} else {

	print "<title>Wildcam</title>\n";
	print "</head><body>\n";
	print "<h1>Wildcam status & Config</h1>\n";

	print "<form method='POST' action='$myurl?press=1'>\n";
	print "<table>\n";

	# Are we running in AP mode?
	print "<tr><td class='formTitle'>AP Mode:</td><td class='formData'>\n";
	$cmdout=`/sbin/iwconfig wlan0`;
	$cmdout =~ /ESSID:"(.*)"/;
	my $ssid=$1;
	if($ssid eq $apssid) {
		print "Running in AP mode - SSID=$ssid";
		print "</td><td>";
		print "<input type='submit' name='action' value='Switch to infrastructure'>";
	} else {
		print "Connected to infrastructure wifi - <span class='bold'>SSID=$ssid</span>";
		print "</td><td class='formAction'>";
		print "<input type='submit' name='action' value='Switch to AP mode'>";
	}
	print "<input type='submit' name='action' value='Wifi Off'></td></tr>\n";

	# Is wildcam running?
	print "<tr><td class='formTitle'>Wildcam running?:</td><td class='formData'>\n";
	if(system("ps -ef | grep 'wildcam.py' |grep -v 'grep' > /dev/null")) {
		print "Not running";
		start_cam_opts();
		$cambut="Run Wildcam";
	} else {
		print "Running ....";
		$cambut="Terminate Wildcam";
	}
	print "</td><td class='formAction'><input type='submit' name='action' value='$cambut'></td></tr>\n";


	# Is streaming mode on?
	print "<tr><td class='formTitle'>Streamer running?:</td><td class='formData'>\n";
	if(system("ps -eo args | grep '^/usr/local/bin/mjpg_streamer' > /dev/null")) {
		print "Not running";
		$streambut="Streamer On";
	} else {
		my $link="http://$ENV{'HTTP_HOST'}:8080/?action=stream";
		#print "Running (<a href=\"$link\">$link</a>)";
		print("<iframe src=\"$link\" width=640 height=480></iframe>");
		$streambut="Streamer Off";
	}
	print "</td><td class='formAction'><input type='submit' name='action' value='$streambut'></td></tr>\n";


	# Allow direct turning on of LEDs
	print "<tr><td class='formTitle'>LED Control:</td>\n";
	print "<td class='formData'><input type='radio' name='led' value='White'>White\n";
	print "<input type='radio' name='led' checked='checked' value='IR'>IR\n";
	print "<input type='radio' name='led' value='Off'>Off\n<br>";
	print "<label for='brightness' class='bold'>Brightness:</label>\n";
	print "<select id='brightness' name='brightness'>\n";
	print "  <option value='0'>0%</option>\n";
	print "  <option value='1'>25%</option>\n";
	print "  <option value='2'>50%</option>\n";
	print "  <option value='3'>75%</option>\n";
	print "  <option value='4' selected>100%</option>\n";
	print "</select></td>\n";

	print "<td class='formAction'><input type='submit' name='action' value='Change LED'></td></tr>\n";



	# Report disk space
	print "<tr><td class='formTitle'>Disk space:</td>\n";
	my $diskspace=`df -h /`;
	print "<td class='formData'><pre>$diskspace</pre></td><td class='formAction'></td></tr>\n";

	# Link to thumbnails
	print "<tr><td class='formTitle'>Captures:</td>\n";
	print "<td class='formData'><a href='/wildcaps/index.pl'>Thumbnails</a>\n";
	print " or paste \\\\$ENV{'HTTP_HOST'}\\wildcaps\\ into explorer</td>\n";
	print "<td class='formAction'></td></tr>\n";


	# Allow Pi power off
	print "<tr><td class='formTitle'>Power:</td><td class='formData'>On!</td>\n";
	print "<td class='formAction'><input type='submit' name='action' value='Power Off'></td>\n";
	print "</tr>\n";

	# Show logfile
	my $lfile=`ls -lh $logfile`;
	print "<tr><td class='formTitle'>Logfile:</td>\n";
	print "<td class='formData'><a href='?viewlog=1'><pre>$lfile</pre></a></td>\n";
	print "<td class='formAction'><input type='submit' name='action' value='Clear Log'></td></tr>\n";

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
exit(0);

# ***************************************************

sub process_fork {
	# Process the inputs in the background ** Not actually called, can likely delete this! **
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
		# Problems starting this, try logging to file
		open(FH, '>', '/tmp/wildcamstart.log') or die $!;
		print FH "Trying to start wildcam\n";
		my $cam=launch_wildcam(%vars);
		print FH "Launching with cam options $cam\n";
		my $cmd="$roothelp wildcam $cam 2>&1 1>/dev/null &";
		print FH "Executing command: $cmd\n";
		print "<pre>Running: $cmd</pre><br>\n";
		#$cmdout=`$cmd`;
		$cmdout='';
#		my $child_pid = fork();
#		if ( ! defined( $child_pid )) {
#		    warn "fork failed\n";
#		}
#		elsif ( $child_pid == 0 ) { # true for the child process
#			require POSIX;
#			POSIX::setsid();
#		 	exec($cmd);
#		}
		# Use Proc::Daemon to background the process
		my $daemon = Proc::Daemon->new(work_dir => $binpath);
		my $childPid = $daemon->Init( {
		    exec_command => $cmd,
		  });

		print("<p>Started wildcam with PID = $childPid</p>\n");
		print FH "Started wildcam with PID = $childPid\n";
		close(FH);
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
	# Formatted a table in a table - change to flexbox
	print "<table>\n";

	print "<tr><td>Capture mode:</td>\n";
	print "<td><select onChange='updateVisibleFields();' id='capmode' name='capmode'>\n";
	print "<option value='s'>Stills</option>\n";
	print "<option value='v'>Video</option><option value='t'>Timelapse</option>\n";
	print "</select></td></tr>\n";

	# Dynamic rows have a class name. Initially  stillsOnly and bothMotion are
	# the only two visible. Javascript uses these class names to disable/enable
	# visibility.

	# Only in stills mode
	print "<tr class='stillOnly'><td>Number of stills on motion detect: ";
	  print "<br><i>Will multishoot a number of frames</i></td>\n";
		print "<td><input type='text' name='numstill' size=10 value='3'></td></tr>\n";
		print "<tr class='stillOnly'><td>Seconds between multishoot frames: </td>\n";
		print "<td><input type='text' name='tsec' size=10 value='1'></td></tr>\n";

	# Only video mode
	print "<tr class='videoOnly'><td>Seconds per video capture: </td>\n";
	print "<td><input type='text' name='capsec' size=10 value='10'></td></tr>\n";

	# Both motion detect modes
	print "<tr class='bothMotion'><td>Post capture delay:<br><i>Time to wait idle after each still or video</i></td>\n";
	print "<td><input type='text' name='postcap' value='1'></td></tr>\n";
	print "<tr class='bothMotion'><td>Motion detect method:</td>\n";
	print "<td><select name='motion'><option value='p'>PIR</option>\n";
	print "<option value='i'>Software</option>\n";
	print "</select></td></tr>\n";

	# Timelapse mode
	print "<tr class='timelapse'><td>Seconds between timelapse frames: </td>\n";
	print "<td><input type='text' name='tlsec' size=10 value='300'></td></tr>\n";

	# Options that are the same, regardless of mode - no class set
	print "<tr><td>Wait before monitoring starts (sec): </td>\n";
	print "<td><input type='text' name='waitsec' size=10 value='3'></td></tr>\n";
	print "<tr><td>Folder to store images:</td>\n";
	print "<td><input type='text' name='folder' value='/home/pi/wildcaps'></td></tr>\n";

	print "<tr><td>Capture resolution</td>\n";
	print "<td><select name='resolution'><option value='640x480'>640x480</option>\n";
	print "<option value='1296x792'>1296x792</option>\n";
	print "<option value='1920x1080'>1920x1080</option>\n";
	print "<option value='2592x1944'>2592x1944</option>\n";
	print "</select></td></tr>\n";

	print "<tr><td>Illumination mode:</td>\n";
	print "<td><select name='illmode'><option value='m'>On capture</option>\n";
	print "<option value='o'>Always on</option><option value='f'>Always off</option>\n";
	print "</select></td></tr>\n";
	print "<tr><td>Illumination:</td>\n";
	print "<td><select name='illumin'><option value='n'>None</option>\n";
	print "<option value='w'>White</option><option value='i'>IR</option>\n";
	print "</select></td></tr>\n";

	print "</table>\n";

}

sub launch_wildcam {
	my (%v) = @_;

	my $mode=$v{'capmode'};
	my $camopts;

	print("Mode is $mode<br>\n");

	if($mode eq 's') {
		print "Gonna do a stills mode";
		$camopts="--wait=$v{'waitsec'} --folder=$v{'folder'} --postcap=$v{'postcap'} --mode=$v{'capmode'} ";
		$camopts.="--caplen=$v{'capsec'} --stills=$v{'numstill'} --time=$v{'tsec'} --res=$v{'resolution'} ";
		$camopts.="--iltype=$v{'illumin'} --ilmode=$v{'illmode'} --detect=$v{'motion'}";
	} elsif($mode eq 'v') {
		print "Video killed the radio star";
		$camopts="--wait=$v{'waitsec'} --folder=$v{'folder'} --postcap=$v{'postcap'} --mode=$v{'capmode'} ";
		$camopts.="--caplen=$v{'capsec'} --stills=$v{'numstill'} --time=$v{'tsec'} --res=$v{'resolution'} ";
		$camopts.="--iltype=$v{'illumin'} --ilmode=$v{'illmode'} --detect=$v{'motion'}";
	} elsif($mode eq 't') {
		print "Lets do the timelapse again";
		$camopts="--wait=$v{'waitsec'} --folder=$v{'folder'} --mode=$v{'capmode'} ";
		$camopts.="--time=$v{'tlsec'} --res=$v{'resolution'} ";
		$camopts.="--iltype=$v{'illumin'} --ilmode=$v{'illmode'}";
	} else {
		print "Error, no such mode";
		return "";
	}

	print "<pre>Cam options $camopts</pre>\n";

	return $camopts;
}
