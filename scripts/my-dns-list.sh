#!/bin/sh
# Sets automaticaly the DNS servers for the current network interface
# Usage: my-dns-list.sh
# Sets the DNS servers for the current network interface

# Linux
# Get the current network interface
# IFACE=$(ip route get 1 | awk '{print $5}')
# echo "Current network interface: $IFACE"
# IFACE=$(echo $IFACE | tr -d ' ')
# echo "Current network interface: $IFACE"

# Mac OS
# My DNS Server List
# CloudFlare
# 1.1.1.1
# 1.0.0.1
# 2606:4700:4700::1111
# 2606:4700:4700::1001
# # Google
# 8.8.8.8
# 8.8.4.4
# # OpenDNS
# 2001:4860:4860::8888
# 2001:4860:4860::8844
# 2001:4860:4860:0:0:0:0:8888
# 2001:4860:4860:0:0:0:0:8844
# # Vivo ISP 💩
# 192.168.15.1
# fe80::7ae9:cfff:febf:a090
# TODO: Add support for Linux
# TODO: Add support for Windows
# TODO: Add support to select network interfaces from the system list
# TODO: Add support to input custom DNS servers
# TODO: Refactor everything to use as a function
# INFO: This script has been un versioned for a while, so I need to dedicate some love to it and properly refactor

# Helper script to set the DNS servers for the desired network interfaces
echo "Helper script to set the DNS servers for the desired network interfaces"
echo "Only for macOS yet"
echo "--------------------------------"

NETWORK_INTERFACES=('Thunderbolt Ethernet Slot 0' 'USB 10/100/1000 LAN' 'Wi-Fi')
DNS_SERVER_LIST=('1.1.1.1' '1.0.0.1' '2606:4700:4700::1111' '2606:4700:4700::1001' '8.8.8.8' '8.8.4.4' '2001:4860:4860::8888' '2001:4860:4860::8844' '2001:4860:4860:0:0:0:0:8888' '2001:4860:4860:0:0:0:0:8844' '192.168.15.1' 'fe80::7ae9:cfff:febf:a090')

# List Current DNS Servers by network interface
for i in "${NETWORK_INTERFACES[@]}" ; do
    echo "Current DNS Servers for $i"
    networksetup -getdnsservers "$i"
    echo "-------------------------"
done

# TODO: Deprecated, to be reviewed
# # Set DNS Servers from list by network interface
# for i in "${NETWORK_INTERFACES[@]}" ; do
#     SERVERS=''
#     for j in "${DNS_SERVER_LIST[@]}" ; do
#         SERVERS="$SERVERS $j"
#     done

#     echo "Setting DNS Servers for $i"
#     echo "Servers: $SERVERS"
#     COMMAND="networksetup -setdnsservers \"$i\" $SERVERS"
#     echo "Command to be executed: $COMMAND"
#     eval "$COMMAND"
#     echo "-------------------------"
# done

# Select the network interface to set the DNS servers
echo "Select the network interface to set the DNS servers"
for i in "${!NETWORK_INTERFACES[@]}" ; do
    echo "$i. ${NETWORK_INTERFACES[$i]}"
done
echo "a/A/all. All"
echo "q/Q/quit/exit. Quit"
read -p "Enter the number of the network interface: " NETWORK_INTERFACE

# Set DNS Servers for all network interfaces
if [ "$NETWORK_INTERFACE" = "a" ] || [ "$NETWORK_INTERFACE" = "A" ] || [ "$NETWORK_INTERFACE" = "all" ]; then
    # Get confirmation from user
    read -p "Are you sure you want to set the DNS servers for all network interfaces? (y/n): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        for i in "${NETWORK_INTERFACES[@]}" ; do
            echo "Setting DNS Servers for $i"
            SERVERS=''
            for j in "${DNS_SERVER_LIST[@]}" ; do
                SERVERS="$SERVERS $j"
            done
            COMMAND="networksetup -setdnsservers \"$i\" $SERVERS"
            eval "$COMMAND"
            echo "-------------------------"
        done
    fi
    exit 0
fi

if [ "$NETWORK_INTERFACE" = "q" ] || [ "$NETWORK_INTERFACE" = "Q" ] || [ "$NETWORK_INTERFACE" = "quit" ] || [ "$NETWORK_INTERFACE" = "exit" ]; then
    echo "Exiting..."
    exit 0
fi

# Set the DNS servers for the selected network interface
if [[ "$NETWORK_INTERFACE" =~ ^[0-9]+$ ]] && [ "$NETWORK_INTERFACE" -ge 0 ] && [ "$NETWORK_INTERFACE" -lt "${#NETWORK_INTERFACES[@]}" ]; then
    SERVERS=''
    for j in "${DNS_SERVER_LIST[@]}" ; do
        SERVERS="$SERVERS $j"
    done
    COMMAND="networksetup -setdnsservers \"${NETWORK_INTERFACES[$NETWORK_INTERFACE]}\" $SERVERS"
    echo "Setting DNS Servers for ${NETWORK_INTERFACES[$NETWORK_INTERFACE]}"
    echo "Servers: $SERVERS"
    # Get confirmation from user
    read -p "Are you sure you want to set the DNS servers for ${NETWORK_INTERFACES[$NETWORK_INTERFACE]}? (y/n): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        eval "$COMMAND"
        echo "-------------------------"
    fi
else
    echo "Invalid input. Please enter a valid number or option."
    exit 1
fi