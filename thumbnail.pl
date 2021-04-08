#!/usr/bin/perl

# Lightwight file browser for wildcam caps
# By Dave Hartburn 2015

use strict;
use warnings;

use File::stat;
use Time::localtime;
use Time::Piece;
use CGI;

my $CAPDIR="/var/www/html/wildcaps";
my $NOCOLS=5;
my $picsperpage=50;

my $myurl="http://$ENV{'HTTP_HOST'}/wildcaps";

print "Content-type: text/html\n\n";
print "<html><head>\n";
print "<title>Wildcam - Captures</title>\n";
print "</head><body>\n";
print "<h1>Wildcam Captures</h1>\n";

# Decode command line options
my $cgi = CGI->new();
my %vars = $cgi->Vars;

# Read directory into sorted array
opendir (DIR, $CAPDIR) or die $!;

# Read to array and sort youngest first. Remember file name has date
# so file params are not needed to determine age. Only list mp4 and jpg
my @files = grep { $_ =~ /^(.*)\.(mp4|jpg)$/ } readdir(DIR);
my @files_sorted = reverse (sort @files);

#print"<pre>";
#foreach my $key (sort keys(%ENV)) {
#  print "$key = $ENV{$key}<p>";
#}
#print "</pre>\n";

# Are we displaying a thumbnail or a the whole lot?
if($vars{'image'}) {
	show_image($vars{'image'});
} else {
	if($vars{'page'}) {
		list_files($vars{'page'});
	} else {
		list_files();
	}
}


print "</body></html>\n";

exit;

# ***************************************************************

sub list_files {
	my $page = $_[0];
	if(!$page) {
		$page=1;
	}
	my ($file, $pre, $ext, $col, $count, $hsize, $i);
	
	# Print page headers
	my $numpages = roundup(@files_sorted/$picsperpage);
	print "<p><a href='http://$ENV{'HTTP_HOST'}'>Back to control page....</a>";
	print "<p><b>Pages:</b> ";
	for($i=1; $i<=$numpages; $i++) {
		if($page==$i) {
			print "<b>$page</b>  ";
		} else {
			print "<a href='$ENV{'SCRIPT_NAME'}?page=$i'>$i</a>  ";
		}
	}
	print "</p>";

	print "<table style='font-size:10px'>\n";
	
	$col=0;
	$count=0;
	
	# What do we count from and to?
	my $start=($page-1)*$picsperpage;
	my $finish=$start+$picsperpage;
	if($finish>@files_sorted) {
		$finish=@files_sorted;
	}
	for($i=$start; $i<$finish; $i++) {
	 	$file=$files_sorted[$i];
		if($count<$picsperpage) {
			# Strip filename components
			$file =~ /^(.*)\.(mp4|jpg)$/;
			$pre=$1;
			$ext=$2;
			if($col==0) {
				print("<tr>");
			}
			# Need a thumbnail for jpg?
			if($ext eq "jpg") {
				print "<td><a href='$ENV{'SCRIPT_NAME'}?image=$file'>\n";
				# Does the thumbnail exist?			
				my $thumb="$pre-thumb.$ext";
				my $thumbfull="$CAPDIR/thumbs/$thumb";
				if(! -e $thumbfull) {
					# No thumb, generates in same directory
					# which we don't seem to be able to change
					`exiv2 -et $CAPDIR/$file`;
					`mv $CAPDIR/$thumb $thumbfull`;
				}
				print "<img src='$myurl/thumbs/$thumb'>";
			} else {
				# Display movie icon
				print "<td><a href='$myurl/$file'>\n";
				print "<img src='/mp4icon.jpg'>";
			}
			
			# Add thumbnail or icon for video
			print "<br>$file</a><br>\n";
			# Add file details
			my $ftime = stat("$CAPDIR/$file")->mtime;
			my $ftimestr = localtime($ftime)->strftime('%F %T');
			$hsize=fileSize("$CAPDIR/$file");
			print "$ftimestr - $hsize";
			
			print "</td>\n";
			# Increase counters
			$col++;
			$count++;
			if($col==$NOCOLS) {
				$col=0;
				print("</tr>\n");
			}
		}
	
	}
	# ** Need to deal with more button 
	print "</table>\n";
	close(DIR);
}

sub show_image() {
	# Display the image with forward and back options
	my $file = $_[0];
	
	# **** Need to put in some URL checks to make sure someone is not
	# probing files they should not.
	
	# What is our position in the array?
	my ($index) = grep { $files_sorted[$_] eq $file } (0 .. @files_sorted-1);
	
	# What thumbnail page did we link from?
	my $pageno= int($index/$picsperpage)+1;
	print "<p><a href='$ENV{'SCRIPT_NAME'}?page=$pageno'>Return to index</a></p>\n";
	
	print "<b>FILE:</b>$file<br>\n";
	my $hsize=fileSize($file);
	print "<b>SIZE:</b>$hsize<br>\n";
	# Using table for layout....bad CSS! (change in future)
	print "<table><tr>\n";
	if($index>0) {
		my $nindex=$index-1;
		print "<td><a href='$ENV{'SCRIPT_NAME'}?image=$files_sorted[$nindex]'>";
		print "Previous</a></td>\n";
	} else {
		print "<td>At start</td>\n";
	}
	if($file =~ /jpg$/ ) {
		print "<td><img style='max-height:80vh' src='$myurl/$file'></td>";
	} else {
		print "<td><a href='$myurl/$file'>\n";
		print "<img src='/mp4icon.jpg'><br>Play</a></td>";
	}
	if($index<(@files_sorted-1)) {
		my $nindex=$index+1;
		print "<td><a href='$ENV{'SCRIPT_NAME'}?image=$files_sorted[$nindex]'>";
		print "Next</a></td>\n";
	} else {
		print "<td>At end</td>\n";
	}
	print "</tr></table>\n";

}

sub fileSize() {
	# Returns file size in human readable format
	my $file=$_[0];
	my ($size, $psize, $hsize);
	
	$size = -s "$file";
	if($size>1048576) {
		# 1048576 = bytes in 1Mb;
		$psize=$size/1048576;
		$hsize=sprintf("%.1fM", $psize);
	} else {
		$psize = $size/1024;
		$hsize=sprintf("%dK", $psize);
	}			

	return $hsize;
}

sub roundup {
    	my $n = shift;
    	return(($n == int($n)) ? $n : int($n + 1))
}
