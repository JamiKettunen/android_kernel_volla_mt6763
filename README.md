# Android kernel (v4.4.245) for the Volla Phone

## Features
1. Upstreamed to latest 4.4.y subversion release available on [kernel.org](https://www.kernel.org/)
2. Added LOTS of build time fixes and improvements:
   - Fixed some actual issues in code thanks to `-Werror` under newer GCC
   - Any GCC version up to 10.2 with relevant binutils have been tested as working
   - In-tree compilation has been fixed (no need to use `make O=out` anymore)
   - Migrated MediaTek's DCT tool from Python 2 to Python 3
   - Silenced a bunch of build-time message spam from MediaTek Makefiles and such
   - Builds with `CC=clang` (only on [`wip-llvm-clang-support`](../../tree/wip-llvm-clang-support) branch, crashes when entering suspend)
3. Silenced LOTS of message spam in `dmesg` on device runtime
4. Disabled even more debugging features in [defconfig](arch/arm64/configs/k63v2_64_bsp_defconfig)

## Branches
* [android-9.0](../../tree/android-9.0) — Android 9 kernel source with many build fixes and some cleanup
* [halium-9.0](../../tree/halium-9.0) — Same as android-9.0, but with Halium 9 patches for e.g. Ubuntu Touch

## Building

### Environment
The currently used & tested working build env consists of (others should work fine as well):
* An x86-64 Ubuntu 20.10 (-based) distro
* binutils 2.35
* GCC 10.2

### Dependencies

#### Ubuntu / Debian (-based)
```
# apt install -y build-essential gcc-aarch64-linux-gnu libssl-dev python3 bc curl mkbootimg kmod
```

#### Arch Linux (-based)
```
# pacman -S --needed --noconfirm base-devel aarch64-linux-gnu-gcc python3 bc android-tools kmod
```

### Kernel build
The process should be straight forward following the prompts from the [build.sh](build.sh) script:
```
./build.sh
```

## Deployment to a device
The [`deploy.sh`](deploy.sh) script will detect and attempt to deploy a `boot.img` & `kernel-modules.tar.gz` in the current directory to a connected device in recovery mode.

### Ubuntu Touch
```
./deploy.sh
```
**NOTE:** The device needs to be booted to UBports recovery for this to work **AND** these changes will get overwritten by the default kernel on OS updates!

## Links
* [Default README](README)
* [HelloVolla's kernel tree](https://github.com/HelloVolla/android_kernel_volla_mt6763)
* [Google's common 4.4 Android Pie kernel](https://android.googlesource.com/kernel/common/+/refs/heads/android-4.4-p)
* [Upstream linux-stable 4.4.y tree](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/log/?h=linux-4.4.y)
* [Ubuntu 20.10 Minimal Cloud Image](https://partner-images.canonical.com/core/groovy/current/ubuntu-groovy-core-cloudimg-amd64-root.tar.gz)
