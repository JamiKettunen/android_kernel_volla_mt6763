#!/bin/bash
set -e

# Config
TARGET_DEVICE="yggdrasil"
TARGET_PROP="ro.build.product"

# Script
cd "$(dirname "$0")"
if [[ ! -e boot.img || ! -e kernel-modules.tar.gz ]]; then
	echo ">> ERROR: Please place a 'boot.img' along with 'kernel-modules.tar.gz' in the"
	echo "          directory of this deployment script!"
	exit 1
fi

device=""
echo ">> Waiting for a device in recovery mode..."
while true; do
	if adb devices | grep -q recovery; then
		device="$(adb shell getprop $TARGET_PROP)"
		break
	fi
	sleep 1
done
if [ "$device" != "$TARGET_DEVICE" ]; then
	echo ">> Detected device '$device' does not match deploy target '$TARGET_DEVICE';"
	echo "   please disconnect any other potentially conflicting devices and try again!"
	exit 1
fi

echo ">> Detected your '$device' in recovery mode; pushing & flashing kernel build artifacts..."
adb push {boot.img,kernel-modules.tar.gz} /tmp
adb shell << EOF
dd bs=4M if=/tmp/boot.img of=/dev/block/bootdevice/by-name/boot
if [ -e /system/var/lib/lxc/android/android-rootfs.img ]; then
	mkdir /a
	mount /system/var/lib/lxc/android/android-rootfs.img /a
	tar -xvf /tmp/kernel-modules.tar.gz -C /a/system/lib/modules/
	chown root:root /a/system/lib/modules/*
	umount /a
else
	tar -xvf /tmp/kernel-modules.tar.gz -C /system/lib/modules/
	chown root:root /system/lib/modules/*
fi
sync && reboot
EOF
echo ">> Done!"
