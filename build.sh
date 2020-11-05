#!/bin/bash
set -e

# Config
DEFCONFIG="k63v2_64_bsp_defconfig"
SAVEDEFCONFIG=1
RAMDISK="halium-ramdisk.cpio.gz"
BUILD_JOBS="$(nproc)"
CCACHE_DISABLE="1"    # 1|0
ODIR=".out"           # use "" for in-tree building
ARCH="arm64"
MAKE="make O=$ODIR ARCH=$ARCH CROSS_COMPILE=aarch64-linux-gnu- CC=clang"
#PATH="/path/to/toolchain/bins:$PATH"

# Script
cd "$(dirname "$0")"
export PATH CCACHE_DISABLE
mk_config=1
if [ -f "./$ODIR/.config" ]; then
	read -p ">> Found existing .config, clean build (y/N)? " ans
	if [ "${ans^^}" = "Y" ]; then
		eval $MAKE mrproper
		if [[ "`readlink -f .`" != "`readlink -f "./$ODIR"`" && -d ./"$ODIR" ]]; then
			rm -rf ./"$ODIR"/*
		else
			rm -rf ./"$ODIR"/rootfs/ # kernel modules from in-tree builds
		fi
		echo ">> Press ^C within 2 seconds to cancel building (i.e. only clean)..."
		sleep 2
	else
		read -p ">> Regenerate .config from $DEFCONFIG (y/N)? " ans
		[ "${ans^^}" != "Y" ] && mk_config=0
	fi
fi

if [ $mk_config -eq 1 ]; then
	echo ">> Generating .config from $DEFCONFIG..."
	eval $MAKE $DEFCONFIG
fi
read -p ">> Run 'make menuconfig' (y/N)? " ans
if [ "${ans^^}" = "Y" ]; then
	eval $MAKE menuconfig

	if [ "$SAVEDEFCONFIG" = "1" ]; then
		read -p ">> Update $DEFCONFIG from 'make savedefconfig' (y/N)? " ans
		if [ "${ans^^}" = "Y" ]; then
			eval $MAKE savedefconfig
			cp ./"$ODIR"/defconfig arch/$ARCH/configs/$DEFCONFIG
		fi
	else
		read -p ">> Update $DEFCONFIG from .config (y/N)? " ans
		[ "${ans^^}" = "Y" ] && cp ./"$ODIR"/.config arch/$ARCH/configs/$DEFCONFIG
	fi
fi
echo ">> Starting kernel build with $BUILD_JOBS jobs..."
sleep 1
eval time $MAKE -j$BUILD_JOBS

if [ ! -z "$RAMDISK" ]; then
	if [ ! -f "$RAMDISK" ]; then
		echo ">> Fetching halium-ramdisk.cpio.gz..."
		curl -L https://github.com/Halium/initramfs-tools-halium/releases/download/continuous/initrd.img-touch-arm64 -o "$RAMDISK"
	fi
else
	RAMDISK="/dev/null"
fi
echo ">> Creating Android boot.img..."
rm -f boot.img kernel-modules.tar.gz
mkbootimg \
	--kernel "./$ODIR/arch/$ARCH/boot/Image.gz-dtb" \
	--ramdisk "$RAMDISK" \
	--cmdline "bootopt=64S3,32N2,64N2 systempart=/dev/disk/by-partlabel/system" \
	--base "0x40078000" \
	--kernel_offset "0x8000" \
	--ramdisk_offset "0x14f88000" \
	--tags_offset "0x13f88000" \
	--pagesize "2048" \
	-o boot.img
ls -lh boot.img

echo ">> Packaging kernel modules..."
eval $MAKE INSTALL_MOD_PATH=rootfs modules_install
modules=./$ODIR/rootfs/lib/modules
kver=$(ls $modules | head -1) # e.g. "4.4.239"
files=$(find $modules/$kver/ -type f -name "*.ko")
files=$(ls $files $modules/$kver/{modules.alias,modules.dep})
mkdir /tmp/kernel_modules
for f in $files; do
	cp $f /tmp/kernel_modules/
done
tar -C /tmp/kernel_modules -czvf kernel-modules.tar.gz .
rm -r /tmp/kernel_modules
ls -lh kernel-modules.tar.gz

echo
read -p ">> Would you like to deploy the kernel build artifacts to a device (Y/n)? " ans
[[ -z "$ans" || "${ans:0:1}" = "Y" || "${ans:0:1}" = "y" ]] || exit 0
source deploy.sh
