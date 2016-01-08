#!/bin/bash
# MSM8X26 L build script v0.1

BUILD_TOP_DIR=$(pwd)
BUILD_KERNEL_DIR=$(pwd)

BUILD_CROSS_COMPILE=$(pwd)/tools/arm-eabi-4.8/bin/arm-eabi-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`

# Kernel default
KERNEL_DEFCONFIG=msm8226-sec_defconfig
SELINUX_DEFCONFIG=selinux_defconfig

shift $((OPTIND-1))

BUILD_COMMAND=$1

MODEL=${BUILD_COMMAND%%_*}
TEMP=${BUILD_COMMAND#*_}
REGION=${TEMP%%_*}
CARRIER=${TEMP##*_}


echo "	 _____                _       _    _ _     "
echo "	|_   _|              | |     | |  | (_)    "
echo "	  | | ___  _   _  ___| |__   | |  | |_ ____"
echo "	  | |/ _ \| | | |/ __| '_ \  | |/\| | |_  /"
echo "	  | | (_) | |_| | (__| | | | \  /\  / |/ / "
echo "	  \_/\___/ \__,_|\___|_| |_|  \/  \/|_/___|"
echo ""
echo " _           _ _ _                    ______          _   "
echo "| |         | | (_)                   | ___ \        | |  "
echo "| |     ___ | | |_ _ __   ___  _ __   | |_/ /__  _ __| |_ "
echo "| |    / _ \| | | | '_ \ / _ \| '_ \  |  __/ _ \| '__| __|"
echo "| |___| (_) | | | | |_) | (_) | |_) | | | | (_) | |  | |_ "
echo "\_____/\___/|_|_|_| .__/ \___/| .__/  \_|  \___/|_|   \__|"
echo "                  | |         | |                         "
echo "                  |_|         |_|                         "
echo ""  

echo "######### PARAMETERS ##########"
echo "MODEL   = $MODEL"
echo "TEMP    = $TEMP"
echo "REGION  = $REGION"
echo "CARRIER = $CARRIER"
echo "######### END  #########"



if [[ "$BUILD_COMMAND" == "ms01lte"* ]]; then		# MS01_LTE
	VARIANT=${MODEL}_${CARRIER}
	DTS_NAMES=msm8926-sec-ms01lteeur-r
elif [[ "$BUILD_COMMAND" == "ms013g"* ]]; then		# MS01_3g
	VARIANT=${MODEL}_${CARRIER}
	DTS_NAMES=msm8226-sec-ms013geur-r
elif [[ "$BUILD_COMMAND" == "s3ve3g"* ]]; then		# S3ve_3g
	VARIANT=${MODEL}_${CARRIER}
	DTS_NAMES=msm8226-sec-s3ve3geur-r
elif [[ "$BUILD_COMMAND" == "milletlte_vzw"* ]]; then
	VARIANT=${MODEL}_${CARRIER}
DTS_NAMES=msm8926-sec-milletltevzw-r
#DTS_NAMES=msm8926-sec-milletlte_tmo-r
elif [[ "$BUILD_COMMAND" == "NewModel"* ]]; then	# New Model
	VARIANT=NewModel${CARRIER}
	DTS_NAMES=NewModel-DTS-NAME
else
	DTS_NAMES=
fi

PROJECT_NAME=${VARIANT}
if [ "$MODEL" == "ms01lte" ]; then
	VARIANT_DEFCONFIG=msm8926-sec_${MODEL}_${CARRIER}_defconfig
elif [ "$MODEL" == "milletlte" ]; then
	VARIANT_DEFCONFIG=msm8926-sec_${MODEL}_${CARRIER}_defconfig
else
	VARIANT_DEFCONFIG=msm8226-sec_${MODEL}_${CARRIER}_defconfig
fi

BUILD_KERNEL_DIR=$(pwd)/kernel/$MODEL/
echo "============================================="
echo "		Other Spec"
echo "============================================="
echo "Build DIR      = $BUILD_TOP_DIR "
echo "Kernel         = $BUILD_KERNEL_DIR"
echo "GCC            = $BUILD_CROSS_COMPILE"
echo "JOBs           = $BUILD_JOB_NUMBER"
echo "Out Dir        = $BUILD_TOP_DIR/out"
echo "ROM            = $BUILD_TOP_DIR/s5_mini_port"
echo "Ramdisk-kernel = $BUILD_TOP_DIR/ramdisk "
echo "============================================="

case $1 in
		clean)
		echo "Clean..."
		BUILD_KERNEL_OUT_DIR=$BUILD_TOP_DIR/out/*
		echo "remove kernel out directory $BUILD_KERNEL_OUT_DIR"
		rm $BUILD_KERNEL_OUT_DIR -rf
		exit 1
		;;

		*)
		BUILD_KERNEL_OUT_DIR=$BUILD_TOP_DIR/out/${MODEL}/kernel_obj
		PRODUCT_OUT=$BUILD_TOP_DIR/out/${MODEL}/kernel_obj
		mkdir -p $BUILD_KERNEL_OUT_DIR
		;;

esac

KERNEL_ZIMG=$BUILD_KERNEL_OUT_DIR/arch/arm/boot/zImage
DTC=$BUILD_KERNEL_OUT_DIR/scripts/dtc/dtc

FUNC_APPEND_DTB()
{
	if ! [ -d $BUILD_KERNEL_OUT_DIR/arch/arm/boot ] ; then
		echo "error no directory : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot""
		exit -1
	else
		echo "rm files in : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot/*-zImage""
		rm $BUILD_KERNEL_OUT_DIR/arch/arm/boot/*-zImage
		echo "rm files in : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot/*.dtb""
		rm $BUILD_KERNEL_OUT_DIR/arch/arm/boot/*.dtb
	fi

	for DTS_FILE in `ls ${BUILD_KERNEL_DIR}/arch/arm/boot/dts/msm8226/${DTS_NAMES}*.dts`
	do
		DTB_FILE=${DTS_FILE%.dts}.dtb
		DTB_FILE=$BUILD_KERNEL_OUT_DIR/arch/arm/boot/${DTB_FILE##*/}
		ZIMG_FILE=${DTB_FILE%.dtb}-zImage

		echo ""
		echo "dts : $DTS_FILE"
		echo "dtb : $DTB_FILE"
		echo "out : $ZIMG_FILE"
		echo ""

		$DTC -p 1024 -O dtb -o $DTB_FILE $DTS_FILE
		cat $KERNEL_ZIMG $DTB_FILE > $ZIMG_FILE
	done
}

INSTALLED_DTIMAGE_TARGET=${BUILD_KERNEL_OUT_DIR}/dt.img
DTBTOOL=$BUILD_KERNEL_DIR/tools/dtbTool

FUNC_BUILD_DTIMAGE_TARGET()
{
	echo ""
	echo "================================="
	echo "START : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
	echo "DT image target : $INSTALLED_DTIMAGE_TARGET"

	if ! [ -e $DTBTOOL ] ; then
		if ! [ -d $BUILD_TOP_DIR/out/host/linux-x86/bin ] ; then
			mkdir -p $BUILD_TOP_DIR/out/host/linux-x86/bin
		fi
		cp $BUILD_TOP_DIR/kernel/tools/dtbTool $DTBTOOL
	fi

	BOARD_KERNEL_PAGESIZE=2048

	echo "$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm/boot/"
		$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm/boot/

	chmod a+r $INSTALLED_DTIMAGE_TARGET

	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
}

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "=============================================="
	echo "START : FUNC_BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "build project="$PROJECT_NAME""
	echo "build common config="$KERNEL_DEFCONFIG ""
	echo "build variant config="$VARIANT_DEFCONFIG ""
	echo "build secure option="$SECURE_OPTION ""
	echo "build SEANDROID option="$SEANDROID_OPTION ""

	if [ "$BUILD_COMMAND" == "" ]; then
		SECFUNC_PRINT_HELP;
		exit -1;
	fi
	if [ "$BUILD_COMMAND" == "setup" ]; then
		MKBOOTIMG;
		exit -1;
	fi

	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG VARIANT_DEFCONFIG=$VARIANT_DEFCONFIG \
			DEBUG_DEFCONFIG=$DEBUG_DEFCONFIG SELINUX_DEFCONFIG=$SELINUX_DEFCONFIG \
			SELINUX_LOG_DEFCONFIG=$SELINUX_LOG_DEFCONFIG || exit -1
	
	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	#FUNC_APPEND_DTB
	FUNC_BUILD_DTIMAGE_TARGET
	
	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

BUILD_KERNEL_RAMDISK_DIR=$BUILD_TOP_DIR/ramdisk

FUNC_EXT_MODULES_TARGET()
{

	echo ""
	echo "===================================="
	echo "  START : FUNC_EXT_MODULES_TARGET"
	echo "===================================="
	echo ""

	OUT_MODU=$BUILD_TOP_DIR/out/${MODEL}/system/lib/modules
	rm -rf $OUT_MODU
	mkdir -p $OUT_MODU
	find $BUILD_KERNEL_OUT_DIR -name "*.ko" -exec cp -fv {} $OUT_MODU \;

	mkdir -p $OUT_MODU/pronto
	echo ""
	echo "Moving wlan.ko to pronto/pronto_wlan.ko"
	echo ""
	mv -vf $OUT_MODU/wlan.ko $OUT_MODU/pronto/pronto_wlan.ko

	echo ""
	echo "===================================="
	echo "  END : FUNC_EXT_MODULES_TARGET"
	echo "===================================="
	echo ""

}

SECFUNC_PRINT_HELP()
{
	echo -e '\E[33m'
	echo "Help:"
	echo "$0 \$1"
	echo " "
	echo "If you have just Download the ROM the you need to SetUp it First For Setting it up. type \$1 as setup."
	echo "  OR "
	echo "If you have already runned Setup then type \$1 as following as per your device codename with _eur at last. please note that only following codenames are supported  "
	echo "      s3ve3g_eur"
	echo "      ms013g_eur"
	echo "      ms01lte_eur"
	echo -e '\E[0m'
}

MKBOOTIMG()
{
	if [ "$BUILD_COMMAND" == "setup" ]; then
		echo -e '\E[33m'
		echo "Seting UP";
		echo "Done.. Please re-run the build with your device codename";
		echo -e '\E[0m'
		exit -1;
	fi
}

# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	FUNC_EXT_MODULES_TARGET

	cp -vf $KERNEL_ZIMG $BUILD_KERNEL_RAMDISK_DIR/kernel
	MKBOOTIMG

	END_TIME=`date +%s`

	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./build.log
