#!/bin/bash

# Function to display messages in red
RED() {
    echo -e "\e[91m$1\e[0m"
}

# Testing if root...
if [ $UID -ne 0 ]; then
    RED "You must run this script as root!" && echo
    exit
fi

# Define the directories
preferences_dir="/lib/firefox/browser/defaults/preferences/"
distribution_dir="/lib/firefox/distribution/"
extensions_dir="/lib/firefox/distribution/extensions/"

# Create directories if they don't exist
mkdir -p "$preferences_dir"
mkdir -p "$extensions_dir"
mkdir -p "$distribution_dir"

# Copy files to the directories
cp ./Files/browser/defaults/preferences/* "$preferences_dir"
cp ./Files/distribution/* "$distribution_dir"
cp ./Files/distribution/extensions/* "$extensions_dir"
