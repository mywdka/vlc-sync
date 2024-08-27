#!/bin/bash

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\e[1;97m'
NC='\033[0m'

CONF_FILE="/home/ias/vlc-sync/config.conf"
WLAN_FILE="/etc/network/interfaces.d/wlan0"

if [ ! -f "$CONF_FILE" ]; then
    echo -e "[${RED} VLC-SYNC ${NC}]\t ${RED}Config file not found: $CONF_FILE${NC}"
    exit 1
fi

conductor=$(awk -F= '/^\[options\]/{f=1} f && /conductor/{gsub(/[ \t]/, "", $2); print tolower($2); exit}' "$CONF_FILE")
broadcast=$(awk -F= '/^\[options\]/{f=1} f && /destination/{gsub(/[ \t]/, "", $2); print tolower($2); exit}' "$CONF_FILE")
network=$(awk -F= '/^\[options\]/{f=1} f && /destination/{gsub(/[ \t]/, "", $2); print tolower($2); exit}' "$CONF_FILE" | cut -d'.' -f1-3)

function get_unused_number {
    local subnet="$1"
    local used_numbers=$(arp -n | awk -v subnet="$subnet" '$1 ~ subnet {print $1}' | cut -d'.' -f4 | sort -n)
    for i in {2..254}; do
        if ! echo "$used_numbers" | grep -q "$i"; then
            echo "$i"
            return
        fi
    done
}

if [[ "$conductor" == "true" ]]; then
    address="${network}.1"
else
    unused_number=$(get_unused_number "$network")
    address="${network}.${unused_number}"
fi

echo -e "[${GREEN} VLC-SYNC ${NC}]\t${WHITE}Setting ip $address on network ${network}.0 with broadcast ${broadcast}${NC}"

cat << EOF | sudo tee "$WLAN_FILE" > /dev/null
auto wlan0
iface wlan0 inet static
  address $address
  network ${network}.0
  netmask 255.255.255.0
  broadcast $broadcast
  wireless-channel 1
  wireless-essid vlc-sync
  wireless-mode ad-hoc
EOF

sudo systemctl restart networking
