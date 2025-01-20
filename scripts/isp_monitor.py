#!/usr/bin/env python3
"""
Network Interface Monitor
------------------------

A Python script that continuously monitors and logs the status of network connectivity
and the active network interface. It performs periodic checks by pinging Google's servers
and logs whether the network is up or down, along with the interface being used.

Features:
    - Monitors network connectivity through ping tests
    - Identifies active network interface and its description
    - Implements rotating log files with daily rotation
    - Maintains 5 days of log history
    - Randomized check intervals (45-90 seconds) to prevent system stress

Log Format:
    YYYY-MM-DD HH:MM:SS: Network is [UP/DOWN] using [interface] ([description])

Requirements:
    - Python 3.x
    - macOS (uses macOS-specific networking commands)
    - Root/sudo access may be required for some network commands

Usage:
    ./network_monitor.py

Log File:
    - Primary log file: isp_monitor.log
    - Rotated files: isp_monitor.log.YYYY-MM-DD

Author: Davi Busanello
License: MIT
Version: 0.2
"""

import subprocess
import datetime
import time
import random
import logging
from logging.handlers import TimedRotatingFileHandler

# Set up logging with rotation
logger = logging.getLogger("NetworkLogger")
logger.setLevel(logging.INFO)

handler = TimedRotatingFileHandler("isp_monitor.log", when="midnight", interval=1, backupCount=5)
handler.setFormatter(logging.Formatter('%(asctime)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S'))
logger.addHandler(handler)

def get_default_interface():
    command = "route -n get default"
    try:
        result = subprocess.check_output(command, shell=True).decode()
        for line in result.splitlines():
            if "interface:" in line:
                return line.split(":")[1].strip()
    except subprocess.CalledProcessError:
        return "Unknown"

def get_interface_description(interface):

    command = "networksetup -listallhardwareports"
    try:
        result = subprocess.check_output(command, shell=True).decode()
        description = None
        for line in result.splitlines():
            if line.startswith("Hardware Port"):
                description = line.split(": ", 1)[1]
            if "Device: " + interface in line:
                return description
    except subprocess.CalledProcessError:
        return "Unknown Description"

def log_network_status():
    # with open("network_log.txt", "a") as log_file:
    while True:
        network_interface = get_default_interface()
        network_interface_description = get_interface_description(network_interface)
        status, result = subprocess.getstatusoutput("ping -c1 google.com")
        current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        if status == 0:  # The network is up
            logger.info(f"Network is UP using {network_interface} ({network_interface_description})")
            # log_file.write(f"{current_time}: Network is UP using {network_interface} {network_interface_description}\n")
        else:  # The network is down
            logger.info(f"Network is DOWN using {network_interface} ({network_interface_description})")
            # log_file.write(f"{current_time}: Network is DOWN using {network_interface} {network_interface_description}\n")

        # log_file.flush()
        time.sleep(random.randint(45, 90))

if __name__ == "__main__":
    log_network_status()
