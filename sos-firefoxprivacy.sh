#!/bin/bash

# Function to display messages in red and exit
die() {
    echo -e "\033[91m$1\033[0m" >&2
    exit 1
}

# Testing if root...
testRoot() {
    if [ $UID -ne 0 ] ; then
        die "You must run this script as root"
    fi
}

# Check if config_dir exists   
checkInstall() {
    if [ ! -d "$config_dir" ]; then
        die "The specified Firefox directory does not exist. Firefox may not be installed or not in the default directory."
    fi
}

testRoot

# Define the directories
if [ `uname -s` = "Darwin" ] ; then
    # For macos - firefox 124.0.2
    preferences_dir="/Applications/Firefox.app/Contents/Resources/defaults/pref/"
    extensions_dir="/Applications/Firefox.app//Contents/Resources/browser/features/"
    config_dir="/Applications/Firefox.app/Contents/Resources/"

    checkInstall

    rm /Library/Preferences/org.mozilla.firefox.plist
    defaults import /Library/Preferences/org.mozilla.firefox ./Files/distribution/org.mozilla.firefox.plist

else
    # For linux
    config_dir="/lib/firefox/"
    preferences_dir="/lib/firefox/browser/defaults/preferences/"
    extensions_dir="/lib/firefox/distribution/extensions/"

    checkInstall

    distribution_dir="/lib/firefox/distribution/"
    mkdir -p "$distribution_dir"
    cp ./Files/distribution/policies.json "$distribution_dir"

fi

# Create directories if they don't exist
mkdir -p "$preferences_dir"
mkdir -p "$extensions_dir"

# Copy files to the directories
cp ./Files/mozilla.cfg "$config_dir"
cp -r ./Files/browser/defaults/preferences/* "$preferences_dir"
cp -r ./Files/distribution/extensions/* "$extensions_dir"
