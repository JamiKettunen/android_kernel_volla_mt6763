#!/bin/bash
set -e

# Config
TARGET_DEVICE="yggdrasil"
TARGET_PROP="ro.build.product"
BACKUP_DIR=".backup"

# Script
cd "$(dirname "$0")"
if [[ -e "$BACKUP_DIR"/boot.img || -e "$BACKUP_DIR"/kernel-modules.tar.gz ]]; then
	read -p ">> Backed up kernel already found; would you like to replace it (Y/n)?" ans
	[[ -z "$ans" || "${ans:0:1}" = "Y" || "${ans:0:1}" = "y" ]] || exit 0
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

echo ">> Detected your '$device' in recovery mode; starting kernel backup..."
mkdir -p "$BACKUP_DIR"
adb pull /dev/block/bootdevice/by-name/boot "$BACKUP_DIR"/boot_dump.img
sed '$ s/\x00*$//' "$BACKUP_DIR"/boot_dump.img > "$BACKUP_DIR"/boot.img && \
	rm "$BACKUP_DIR"/boot_dump.img # strip trailing zeroes; needs GNU sed!
ls -lh "$BACKUP_DIR"/boot.img
adb shell << EOF
if [ -e /system/var/lib/lxc/android/android-rootfs.img ]; then
	mkdir /a
	mount /system/var/lib/lxc/android/android-rootfs.img /a
fi
EOF
halium=0
adb shell '[ -e /system/var/lib/lxc/android/android-rootfs.img ]' && halium=1
if [ $halium -eq 1 ]; then
	adb pull /a/system/lib/modules "$BACKUP_DIR"
else
	adb pull /system/lib/modules "$BACKUP_DIR"
fi
tar -C "$BACKUP_DIR"/modules -czvf "$BACKUP_DIR"/kernel-modules.tar.gz .
rm -r "$BACKUP_DIR"/modules/
ls -lh "$BACKUP_DIR"/kernel-modules.tar.gz
adb shell << EOF
[ -e /a ] && umount /a && rmdir /a
EOF
[ -e deploy.sh ] && ln -sf "$PWD"/deploy.sh "$BACKUP_DIR"/
echo ">> Backup done! See '$PWD/$BACKUP_DIR/'"
