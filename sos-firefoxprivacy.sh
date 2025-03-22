#!/bin/bash

# Function to display messages in red and exit
die() {
    echo -e "\033[91m$1\033[0m" >&2
    exit 1
}

# Function to display information messages in green
info() {
    echo -e "\033[92m$1\033[0m"
}

# Testing if root...
testRoot() {
    if [ "$UID" -ne 0 ] ; then
        die "You must run this script as root"
    fi
}

# Check if config_dir exists   
checkInstall() {
    if [ ! -d "$config_dir" ]; then
        die "The specified Firefox directory does not exist. Firefox may not be installed or not in the default directory."
    fi
}

# Uninstall function to remove changes
uninstall() {
    if [ -f "$config_dir/mozilla.cfg" ]; then
        rm -f "$config_dir/mozilla.cfg"
        info "Removed $config_dir/mozilla.cfg"
    fi
    if [ -d "$preferences_dir" ]; then
        rm -rf "$preferences_dir"/*
        info "Removed all files from $preferences_dir"
    fi
    if [ -d "$extensions_dir" ]; then
        rm -rf "$extensions_dir"/*
        info "Removed all files from $extensions_dir"
    fi
    if [ -f "$distribution_dir/policies.json" ]; then
        rm -f "$distribution_dir/policies.json"
        info "Removed $distribution_dir/policies.json"
    fi
    info "Uninstallation complete."
}

# Check for flags
FORCE=false
UNINSTALL=false

for arg in "$@"; do
    case $arg in
        --force)
            FORCE=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
    esac
done

# Test if running as root
testRoot

# Define the directories
if [ "$(uname -s)" = "Darwin" ] ; then
    # For macOS - Firefox 124.0.2
    preferences_dir="/Applications/Firefox.app/Contents/Resources/defaults/pref/"
    extensions_dir="/Applications/Firefox.app/Contents/Resources/browser/features/"
    config_dir="/Applications/Firefox.app/Contents/Resources/"
    distribution_dir="/Applications/Firefox.app/Contents/Resources/distribution/"

    checkInstall

    if [ "$UNINSTALL" = true ]; then
        uninstall
        exit 0
    fi

    rm -f /Library/Preferences/org.mozilla.firefox.plist
    defaults import /Library/Preferences/org.mozilla.firefox ./Files/distribution/org.mozilla.firefox.plist

else
    # For Linux - check for directories in order of preference
    for dir in "/usr/lib64/firefox" "/usr/lib/firefox" "/lib64/firefox" "/lib/firefox" "/usr/lib64/firefox-esr" "/usr/lib/firefox-esr" "/lib64/firefox-esr" "/lib/firefox-esr"; do
        if [ -d "$dir" ]; then
            base_dir="$dir"
            break
        fi
    done

    # Exit if no valid Firefox directory was found
    if [ -z "$base_dir" ]; then
        echo "Firefox directory not found in /usr/lib64, /usr/lib, /lib64, or /lib."
        exit 1
    fi

    config_dir="$base_dir/"
    preferences_dir="$base_dir/browser/defaults/preferences/"
    extensions_dir="$base_dir/distribution/extensions/"
    distribution_dir="$base_dir/distribution/"

    checkInstall

    if [ "$UNINSTALL" = true ]; then
        uninstall
        exit 0
    fi

    mkdir -p "$distribution_dir"
    cp ./Files/distribution/policies.json "$distribution_dir"
fi

# Create directories if they don't exist
mkdir -p "$preferences_dir"
mkdir -p "$extensions_dir"

# Copy files to the directories with overwrite prompt if not forced
copyFile() {
    local sourceFile="$1"
    local destFile="$2"
    if [ -f "$destFile" ] && [ "$FORCE" = false ]; then
        read -p "File $destFile already exists. Do you want to replace it? (y/n) " choice
        if [ "$choice" != "y" ]; then
            echo "Skipped $destFile"
            return
        fi
    fi
    cp "$sourceFile" "$destFile"
    echo "Copied $sourceFile to $destFile"
}

# Perform the copy operations
copyFile "./Files/mozilla.cfg" "$config_dir/mozilla.cfg"
cp -r ./Files/browser/defaults/preferences/* "$preferences_dir"
cp -r ./Files/distribution/extensions/* "$extensions_dir"

info "Firefox configurations installed successfully."
