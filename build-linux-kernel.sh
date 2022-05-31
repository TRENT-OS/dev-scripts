#!/bin/bash

#  # Linux kernel build script
#  
#  The build script will download the official tar files from kernel.org to build the Linux kernel.
#  
#  ## Building the kernel
#  
#  For the linux compliation the following packages need to be installed
#  ```
#  sudo apt install binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu
#  ```
#  More information can be found [here](https://gts3.org/2017/cross-kernel.html)
#  
#  
#  Then you can run the build script
#  ```
#  ./build.sh 5 18.1
#  ```
#  where the first argument 5 means we want to build linux major version 5 and the second argument 18.1 that we want minor version 18.1.
#  This split is needed to find the correct http path for the kernel source.
#  The final kenrel will be copied back into the start directory with the naming scheme linux-arm64-5.18.1 .
#  
#  If changes need to be made to the configuration you can perform them manually, simplie pick up the script the outcommented at make menuconfig.
#  menuconfig will open up a menu inside the terminal to make it easier to change the configuration.
#  
#  
#  ## Trouble shooting
#  
#  If the kernel on a platform has problems running it is possible to deactivate the problematic driver.
#  First findout from which file the error message is comming from (grep, sliver-searcher-ag, VSCode, ...).
#  Second in the folder inside the Makefile the korresponding kconfig name is printed. Search until you find a kconfig, that is also inside .config in the linux root directory.
#  with scripts/config -d {KCONFIGNAME} you can disable the module from compilation.
#  Run compilation and the kernel should no longer run the problematic component.
#  
#  If you want to do printf debuging you can first enable the inbuild debug messages with XXX in the compilation.
#  If you want to add printf statements use [printk](https://www.kernel.org/doc/html/latest/core-api/printk-basics.html).
#  If you are using ctags you can run `make tags` to generate them.


if [ -z "$1" ]
then
	LINUX_MAJOR_VERSION="5"
else
	LINUX_MAJOR_VERSION="$1"
fi

if [ -z "$2" ]
then
	LINUX_MINOR_VERSION="0"
else
	LINUX_MINOR_VERSION="$2"
fi

LINUX_MAJOR_PATH="v$LINUX_MAJOR_VERSION.x"
LINUX_NAME="linux-${LINUX_MAJOR_VERSION}.${LINUX_MINOR_VERSION}"
LINUX_VERSION_PATH="$LINUX_MAJOR_PATH/$LINUX_NAME.tar.xz"
LINUX_HTTPS_TRUNK="https://mirrors.edge.kernel.org/pub/linux/kernel/"

LINUX_SOURCE_PATH="$LINUX_HTTPS_TRUNK$LINUX_VERSION_PATH"



if [ ! -d $LINUX_MAJOR_PATH ]
then
	echo "Creating directore $LINUX_MAJOR_PATH"
	mkdir -p $LINUX_MAJOR_PATH
fi

echo "entering kernel major directorey $LINUX_MAJOR_PATH"
cd $LINUX_MAJOR_PATH

if [ ! -d $LINUX_NAME ]
then
	echo "Download source code from $LINUX_SOURCE_PATH"
	wget $LINUX_SOURCE_PATH
	echo "Unpack source $LINUX_NAME.tar.xz"
	tar -xf "$LINUX_NAME.tar.xz"
fi

echo "entering kernel directore $LINUX_NAME"
cd "$LINUX_NAME"

echo "Export needed enviroment variables for compilation"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

echo "Verify if config exists"
if [ ! -f .config ]
then
	echo "Set default config shiped with linux"
	make defconfig

	echo "deactivate flash module as it throws error in qemu vm"
	scripts/config -d CONFIG_MTD_PHYSMAP -d CONFIG_MTD_PHYSMAP_OF
fi
## To edit config in a menue use
#make menuconfig

echo "Build Kernel"
make -j $(nproc --all)

echo "Copy build kernel to root directory"
cp "arch/$ARCH/boot/Image" "../../linux-$ARCH-$LINUX_MAJOR_VERSION.$LINUX_MINOR_VERSION"
echo "you should find the kernel linux-$ARCH-$LINUX_MAJOR_VERSION.$LINUX_MINOR_VERSION"
