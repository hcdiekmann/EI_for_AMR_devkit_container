# Battery-bridge Module for the Linux kernel

This is a kernel module (based mainly on the `test_power` module
included in the Linux kernel source) for simulating battery behavior on
Linux.
This module helps in case actual battery driver of platform is not supporting to write in /sys/class/power_supply which is a generic interface provided and accessed by kernel-APIs.

## Loading the module

You can build the module with a simple `make`, and load it with `insmod`:

    $ sudo insmod ./battery_bridge.ko

## Automating installation and loading udev-rule

A script automates following tasks:

* uninstall old installed kernel-module for battery_bridge
* make clean old module-binary
* make new binary
* Install new kernel-module for battery_bridge
* Copy udev-rule file into /etc/udev
* Upload udev rule to allow read-write permissions for all users on /dev/battery_bridge location.

    $ sudo module_install.sh

## Changing battery values via /dev/battery\_bridge

Once battery_bridge kernel-module is loaded, values can be written into `/dev/battery_bridge` to change the current charging/discharging
and charge levels of the battery:

    $ echo 'charging = 0' | sudo tee /dev/battery_bridge # set state to discharging
    $ echo 'charging = 1' | sudo tee /dev/battery_bridge # set state to charging
    $ echo 'capacity0 = 77' | sudo tee /dev/battery_bridge # set charge on BAT0 to 77%
    $ echo 'capacity1 = 77' | sudo tee /dev/battery_bridge # set charge on BAT1 to 77%
