# /bin/bash

# Testing if root...
if [ $UID -ne 0 ]
then
	RED "You must run this script as root!" && echo
	exit
fi

cp -R ./Files/* /lib/user/
