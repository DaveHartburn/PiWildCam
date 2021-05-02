#!/usr/bin/perl

# Test backgrounding - starting wildcam was causing the web scripts to hang
# How can I start a long running process and complete the parent process?

use Proc::Daemon;

print("Hello World\n");

system("echo Shell command");

my $cmd="../wildcam.py --folder=/home/pi/wildcaps --mode=tl --time=600 --res=640x480 --iltype=none --ilmode=off 2>&1 1>/dev/null &";
print("Running command: $cmd\n");
$daemon = Proc::Daemon->new(work_dir => '/home/pi/wildbin/testing');
$childPid = $daemon->Init( {
    exec_command => $cmd,
  });

print("Started wildcam with PID = $childPid\n");
#system($cmd);
print("Done\n");
