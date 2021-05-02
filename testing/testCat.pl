#!/usr/bin/perl

my $logfile="/home/pi/wildcaps/wildcam.log";
	print "<title>wildcam.log</title></head><body>\n";
	print "<a href='/'>Return</a>\n";
	print "<pre>\n";
	open(FILE, '<', $logfile) or die $!;
	while(<FILE>) {
		print $_;
	}
	print "</pre></body></html>\n";
	exit;
