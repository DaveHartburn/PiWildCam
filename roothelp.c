/* roothelp.c - Dave Hartburn : September 2015
 *   Runs setuid root, used by wildcam web interface to execute
 *   various functions as root, such as starting services
 *   and powering down. Takes a single argument
 */

#include <stdio.h>
#include <string.h>
 
int main(int argc, char **argv) {
	printf("Input is %s\n", argv[1]);
	setuid(0);
	char cmd[512];
	char argstr[512];
	int i;
	
	if(!strcmp(argv[1], "streamer_off")) {
		//printf("Turning the streamer off\n");
		system("/home/pi/wildbin/stream-mjpg.sh stop");
	
	}
	else if(!strcmp(argv[1], "whoami")) {
		system("whoami");
	}
	else if(!strcmp(argv[1], "streamer_on")) {
		//printf("Turning the streamer on\n");
		system("/home/pi/wildbin/stream-mjpg.sh start");
	
	}
	else if(!strcmp(argv[1], "poweroff")) {
		/* Power down the unit */
		system("/sbin/poweroff");
	
	}
	else if (!strcmp(argv[1], "wifioff")) {
		/* Turn off wifi */
		system("/home/pi/wildbin/ap_off silent");
	}
	else if (!strcmp(argv[1], "wifiinf")) {
		/* Turn off wifi */
		system("/home/pi/wildbin/ap_off");
	}
	else if (!strcmp(argv[1], "wifiap")) {
		/* Turn off wifi */
		system("/home/pi/wildbin/ap_on");
	}
	else if (!strcmp(argv[1], "ledctrl")) {
		/* Change LED state */
		sprintf(cmd, "/home/pi/wildbin/brightPiCtrl.py %s %s", argv[2], argv[3]);
		system(cmd);
	}
	else if (!strcmp(argv[1], "wildcam")) {
		/* Start the wildcam */
		/* Loop through the array of arguments */
		argstr[0]='\0';
		for(i=2; i<argc; i++) {
			sprintf(argstr, "%s %s", argstr, argv[i]);
		}
		sprintf(cmd, "/home/pi/wildbin/wildcam.py %s &", argstr);
		printf("Executing command %s\n", cmd);
		system(cmd);
	}
	else if (!strcmp(argv[1], "killwildcam")) {
		system("killall wildcam.py");
	}
	else if (!strcmp(argv[1], "clearlog")) {
		system("> /home/pi/wildcaps/wildcam.log");
	}
}
