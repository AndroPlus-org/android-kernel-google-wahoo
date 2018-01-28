#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image"
DTBIMAGE="dtb"
export CLANG_PATH=/mnt/ssd/home/android/wahoo/tools/linux-x86/clang-4556391/bin/
export PATH=${CLANG_PATH}:${PATH}
export LD_LIBRARY_PATH=:${LD_LIBRARY_PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=~/aarch64-linux-android-4.9-aosp/bin/aarch64-linux-android-
DEFCONFIG="flash_defconfig"

# Kernel Details
VER=".v04"

# Paths
KERNEL_DIR=`pwd`
TOOLS_DIR=/mnt/ssd/home/android/wahoo/tools
REPACK_DIR=/mnt/ssd/home/android/wahoo/tools/AnyKernel2
PATCH_DIR=/mnt/ssd/home/android/wahoo/tools/AnyKernel2/patch
MODULES_DIR=/mnt/ssd/home/android/wahoo/tools/AnyKernel2/modules
ZIP_MOVE=/mnt/ssd/home/android/wahoo/tools/out/
ZIMAGE_DIR=${KERNEL_DIR}/arch/arm64/boot
MYDESKTOP=/mnt/hgfs/VMShare/desktop

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		cd $KERNEL_DIR/out/kernel
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make CC=clang $DEFCONFIG
		make CC=clang -j4

}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$TOOLS_DIR/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/
}

function make_boot {
		cp -vr $ZIMAGE_DIR/Image.lz4-dtb ${REPACK_DIR}/zImage
}


function make_zip {
		cd ${REPACK_DIR}
		zip -r9 `echo $AK_VER`.zip *
		dd if=`echo $AK_VER`.zip of=$MYDESKTOP/`echo $AK_VER`.zip
		mv  `echo $AK_VER`.zip $ZIP_MOVE
		
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")


echo -e "${green}"
echo "-----------------"
echo "Making AndroPlus Kernel:"
echo "-----------------"
echo -e "${restore}"


# Vars
BASE_AK_VER="AndroPlus"
AK_VER="$BASE_AK_VER$VER"
export LOCALVERSION=~`echo $AK_VER`
export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=AndroPlus
export KBUILD_BUILD_HOST=andro.plus

echo

while read -p "Do you want to clean stuffs (y/N)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		break
		;;
esac
done

make_kernel
make_dtb
make_modules
make_boot
make_zip

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
