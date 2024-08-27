#!/bin/bash

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\e[1;97m'
NC='\033[0m'

SOURCE_DIR="/mnt/tmp"
DEST_DIR="/home/ias/vlc-sync"

echo ""
echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}Starting VLC init${NC}"
echo ""

USB_DEVICES=$(lsblk -d -o NAME,TRAN | grep usb | awk '{print $1}')

if [ "$USB_DEVICES" ]; then
    #echo -e "[${YELLOW} VLC-SYNC ${NC}]\t${WHITE}No USB devices found${NC}"
    for device in $USB_DEVICES; do
        partition="/dev/${device}1"

        if [ -b "$partition" ]; then
            echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}Mounting $partition to /mnt/tmp...${NC}"

            [ ! -d /mnt/tmp ] && sudo mkdir -p /mnt/tmp

            sudo mount "$partition" /mnt/tmp

            if mountpoint -q /mnt/tmp; then
                echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}$partition mounted to /mnt/tmp${NC}"
            else
                echo -e "[${RED} VLC-SYNC ${NC}]\t${WHITE}Failed to mount $partition${NC}"
                exit 1
            fi
        fi
    done
fi



check_folder() {
    if [ ! -d "$1" ]; then
        echo -e "[${RED} VLC-SYNC ${NC}]\t${RED}Folder '$1' does not exist${NC}"
        echo ""
        exit 1
    fi
}

check_folder "$SOURCE_DIR"
check_folder "$DEST_DIR"

remove_files() {
    local dest="$1"
    local extension="$2"

    if compgen -G "$SOURCE_DIR"/*."$extension" > /dev/null; then
        rm -f "$dest"/*."$extension" 2>/dev/null
    fi
}

move_files() {
    local source="$1"
    local dest="$2"
    local files_moved=false

    remove_files "$dest" "mp4"
    remove_files "$dest" "conf"

    for file in "$source"/*.{mp4,conf}; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -f "$dest/$filename" ]; then
                echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}File '$filename' already exists in '$dest'. Overwriting...${NC}"
                cp -f "$file" "$dest/"
                echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}Moved and overwritten $file to $dest/${NC}"
                echo ""
            else
                cp "$file" "$dest/"
                echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}Moved $file to $dest/${NC}"
                echo ""
            fi
            files_moved=true
        fi
    done

    if ! $files_moved; then
        echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}No files had to be moved from '$source'${NC}"
        echo ""
    fi
}

move_files "$SOURCE_DIR" "$DEST_DIR"

echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}VLC init complete${NC}"
echo ""
