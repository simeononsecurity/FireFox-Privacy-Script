# /bin/bash

# Testing if root...
if [ $UID -ne 0 ]
then
	RED "You must run this script as root!" && echo
	exit
fi

mkdir /lib/firefox/browser/defaults/preferences/
mkdir /lib/firefox/distribution/extensions/
cp ./Files/browser/defaults/preferences/* /lib/firefox/browser/defaults/preferences/*
cp ./Files/distribution/extensions/* /lib/firefox/distribution/extensions/*
cp ./Files/browser/distribution/*.json /lib/firefox/distribution/*
