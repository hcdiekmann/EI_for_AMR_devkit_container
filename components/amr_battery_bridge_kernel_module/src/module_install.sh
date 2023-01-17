#!/usr/bin/env bash

# INTEL CONFIDENTIAL

# Copyright 2021 Intel Corporation.

# This software and the related documents are Intel copyrighted materials, and
# your use of them is governed by the express license under which they were
# provided to you ("License"). Unless the License provides otherwise, you may
# not use, modify, copy, publish, distribute, disclose or transmit this
# software or the related documents without Intel's prior written permission.

# This software and the related documents are provided as is, with no express
# or implied warranties, other than those that are expressly stated in the
# License.

set -E -o pipefail
shopt -s extdebug
IFS=$'\n\t'
DIR=$(dirname "${0}")
NC="\033[0m"
RED="\e[31m"
GREEN="\e[32m"
BAT_BRIDGE_UNINSTALL=0
usage()
{
    printf "usage:\n
        Installation: sudo ./install_prerequisites.sh \n
        Uninstall: sudo ./install_prerequisites.sh [-u|--uninstall]\n
This script will:
    * install battery-bridge kernel module using insmod.
    * apply udev rule to add read-write permissions for users to location /dev/battery_bridge.\n\n\n"
    exit 1
}

if [[ $EUID -ne 0 ]]; then
       echo -ne "${RED}This script must be run as root or with sudo!\n${NC}"
       exit 1
fi

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            usage
        ;;
        -u|--uninstall)
            echo -e "\n!!!Warning: uninstall requested, battery_bridge kernel module will ONLY be uninstalled..!!!\n"
            BAT_BRIDGE_UNINSTALL=1
            shift;
        ;;
        *)
            echo -e "${RED}\nERROR: parameter not allowed: ${1}.\n${NC}"
            usage
            shift;
        ;;
    esac
done


echo -e "\nINFO: Uninstalling battery_bridge kernel module.\n"
cd ${DIR} || exit 1
rmmod battery_bridge 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}\nWarning: battery_bridge kernel module could not be uninstalled, skiping removal.!!!${NC}\n\n"
else
    echo -e "\n${GREEN}INFO: battery_bridge kernel module uninstalled.${NC}\n\n"
fi
if [ -c "/dev/battery_bridge" ]; then
    rm -rf /dev/battery_bridge
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}\INFO: removed stalled device left behind from previous installtion steps. ${NC}\n\n"
    fi
fi

if [ ${BAT_BRIDGE_UNINSTALL} -eq 0 ]; then
    echo -e "\nINFO: Installing linux headers...\n"
    apt update
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nERROR: apt update is unsuccessful!!!\n\nExiting !!!${NC}\n\n"
        exit 1
    fi
    apt install linux-headers-$(uname -r)
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nERROR: Linux-kernel-headers installation is unsuccessful!!!\n\nExiting !!!${NC}\n\n"
        exit 1
    fi


    echo -e "\nINFO: Building battery_bridge kernel module .."
    make clean
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nERROR: make clean command is unsuccessful!!!\n\nExiting !!!${NC}\n\n"
        exit 1
    else
        echo -e "\n${GREEN}INFO: battery_bridge kernel module old build cleaned.${NC}\n\n"
    fi
    make all
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nERROR: make all command is unsuccessful!!!\n\nExiting !!!${NC}\n\n"
        exit 1
    else
        echo -e "\n${GREEN}INFO: battery_bridge kernel module build successful.${NC}\n\n"
    fi
    echo -e "\nINFO: Installing battery_bridge kernel module."
    cp battery_bridge.udev.rules /etc/udev/rules.d/battery_bridge.udev.rules || exit 1
    cd src
    insmod battery_bridge.ko
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nERROR: battery_bridge kernel module installation unsuccessful!!!\n\nExiting !!!${NC}\n\n"
        exit 1
    else
        echo -e "\n${GREEN}INFO: Installed battery_bridge kernel module.${NC}"
    fi
    echo -e "\nINFO: Applying devrule to make /dev/battery_bridge read-writable by users..."
    udevadm control --reload-rules
    udevadm trigger
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nERROR: udev rules could not be updated. !!!unsuccessful!!!\n\nExiting !!!${NC}\n\n"
        exit 1
    else
        echo -e "\n${GREEN}INFO: udev rules applied.${NC}"
    fi
fi
echo -e "${GREEN}\n\n!!!Done.!!!${NC}\n\n"
