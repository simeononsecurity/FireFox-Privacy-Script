#!/bin/bash

# Function to display messages in red and exit
die() {
    echo -e "\e[91m$1\e[0m" >&2
    exit 1
}

# Testing if root...
if [ $UID -ne 0 ]; then
    die "You must run this script as root!"
fi

# Define the directories
config_dir="/lib/firefox/"
preferences_dir="/lib/firefox/browser/defaults/preferences/"
distribution_dir="/lib/firefox/distribution/"
extensions_dir="/lib/firefox/distribution/extensions/"

# Check if config_dir exists
if [ ! -d "$config_dir" ]; then
    die "The specified Firefox directory does not exist. Firefox may not be installed or not in the default directory."
fi

# Create directories if they don't exist
mkdir -p "$preferences_dir"
mkdir -p "$extensions_dir"
mkdir -p "$distribution_dir"

# Copy files to the directories
cp ./Files/mozilla.cfg* "$config_dir"
cp -r ./Files/browser/defaults/preferences/* "$preferences_dir"
cp -r ./Files/distribution/* "$distribution_dir"
cp -r ./Files/distribution/extensions/* "$extensions_dir"
