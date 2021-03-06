# Linux 

Disclaimer: This code is largely copied from [https://github.com/pavel-demin/red-pitaya-notes](https://github.com/pavel-demin/red-pitaya-notes), licensed under MIT license.

## Prerequirements
*DO NOT WORK ON A SHARED FOLDER INSIDE VIRTUALBOX*
It will get messy, because the Linux kernel build uses a case sensitive file system, which Mac does not provide.

Fix gmake:
```
sudo ln -s /usr/bin/make /usr/bin/gmake
```

Install some tools:
```
sudo apt install curl u-boot-tools libncurses-dev
```

On VirtualBox:
```bash
# On Host to fix shared folder symlinks
# Ubuntu=MACHINE_NAME noah=SHARE_NAME
VBoxManage setextradata Ubuntu VBoxInternal2/SharedFoldersEnableSymlinksCreate/noah 1
# On guets to fix folder permissions
# ON EACH REBOOT
sudo umount /mnt/noah
sudo mount -t vboxsf -o uid=1000,gid=1000 noah /mnt/noah
```

## Step-by-step build
For educational build purposes, the Makefile was extended to build each component seperately.
This guide will go through all components and briefly explain what they are needed for.

### 1. Create FSBL
Requires: 
- Hardware definition exported from Vivado HLx.
Generates: 
- `build/name.fsbl/executable.elf`

This generates the source code and binary for the first level bootloader that is executed after power on.
After project creation, the fsbl is compiled and the binary written.

```
rm -r build/*.fsbl
make fsbl
```

### 2. Devicetree source
Requires: 
- Hardware definition
- Devicetree sources download from Xilinx repository

Generates:
- Device tree sources `dts`

The devicetree files from Xilinx are downloaded and a device tree project created from the hardware definition files. 
From these two sources, a set of `dts` (device tree sources) files are generated.
Finally the makefile applies a patch to some output files.
The patch file is generates by this command:
```bash
diff -rupN pcw.dtsi pcw.dtsi.new > devicetree.patch
```

```
rm -r build/*.tree
make dts
```

### 3. Linux Kernel
Requires: 
- Nothing

Generates:
- `uImage`

Now it is time to pull a vanilla Linux kernel, uncompress the sources, apply some patches, copy some config and finally build the kernel. Issue the following command and go for a walk:

```
rm -r build/linux*
make uimage
```

or if the sources are already downloaded and you don't want to clean before build:
```
make -C build/linux-4.14 ARCH=arm xilinx_zynq_defconfig
make -C build/linux-4.14 ARCH=arm CFLAGS="-O2 -march=armv7-a \
 -mcpu=cortex-a9 -mtune=cortex-a9 -mfpu=neon -mfloat-abi=hard" \
 -j 4 \
 CROSS_COMPILE=arm-linux-gnueabihf- UIMAGE_LOADADDR=0x8000 uImage modules
```

### 4. U Boot
Requires: 
- Nothing

Generates:
- `u-boot.elf`

The bootloader is build from source pulled from Xilinxed repositoriers.
Before build, some config files are copied and patches applied.

```
rm -r build/u-boot*
make uboot
```

### 5. Devicetree blob
Requires: 
- `uImage`
- Devicetree source

Generates:
- `devicetree.dtb`

Using the device tree sources generated previously, the devicetree compiler is used to generate the devicetree blob.

```
rm -r build/devicetree*
make dtb
```

### 6. Boot image
Requires: 
- FSBL
- Bit stream
- U Boot

Generates:
- `boot.bin`

Now the three binaries can be tied to a single binary image.

```
rm -r build/boot.bin
make bootbin
```
### 7. uEnvt.txt
Requires: 
- Linux compiled
- dtb compiled

Generates:
- uEnvt.txt

For u-boot to know what linux version to load we have to generate a uEnv.txt file.
This is done by running the following command:

```
rm -r build/uEnv.txt
make uenv
```

### 7. Copy contents to SD-Card

Create two partitions on a SD-Card:
1. fat32 1.00GiB label:BOOT Flags:boot
2. ext4 label:root

Copy the following files on the boot partition:
- boot.bin
- devicetree.dtb
- uImage
- uEnv.txt

### 8. First Boot!
Connect a serial console and power up the board.
Hit a key to interrupt u-boot automatic boot process.
To check if the uImage and devicetree are correct issue the following commands:
```bash
mmcinfo
fatload mmc 0 0x2080000 uImage
fatload mmc 0 0x2000000 devicetree.dtb
iminfo 0x2000000
iminfo 0x2080000
setenv bootargs console=ttyPS0,115200 root=/dev/mmcblk0p2 ro rootfstype=ext4 earlyprintk rootwait
bootm 0x2080000 - 0x2000000
```

At this point the kernel should start but fail with a kernel panic because no `init` was found.
For that we next generate the rootfs.

### 9. Busybox
First we try the smallest rootf available: Busybox.
To download, untar and build, run:

```bash
make busybox
```

To modify busybox and build manually:
```bash
cd build/busybox-*
make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
make -j4 ARCH=arm INSTALL_PATH=build/ install
```

Now copy the installed busybox and some install scripts to the root partition of the SD-card.

```bash
./scripts/busybox-sdcard.sh /link/to/sdcard/root/
```

We should now be able bring up the network!
```bash
ifconfig eth0 up
udhcpc -i eth0 -p /var/run/dhcpClient-eth0.pid
ifconfig eth0 192.168.0.87 netmask 255.255.255.0
route add default gw 192.168.0.1
ping 8.8.8.8
```
