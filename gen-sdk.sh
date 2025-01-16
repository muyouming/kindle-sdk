#!/bin/sh

Setup_SDK() {
    tc_target="$1"
    arch="$2"
    FIRM_URL="$3"
    tc_dir="$HOME/x-tools/$tc_target"
    sysroot_dir="$tc_dir/$tc_target/sysroot"

    if ! [ -d $tc_dir ]; then
        echo "[ERROR ] Toolchain not installed - Please setup koxtoolchain for target $tc_target"
        exit 1
    fi

    chmod a-w $tc_dir
    echo "[*] Setting up SDK for $1"

    echo "[*] Generating Meson crosscompilation file"
    chmod a+w $tc_dir

    if [ -f "$tc_dir/meson-crosscompile.txt" ]; then
        chmod a+w $tc_dir/meson-crosscompile.txt
    fi

    echo "[binaries]" > $tc_dir/meson-crosscompile.txt
    echo "c = '$tc_dir/bin/$tc_target-gcc'" >> $tc_dir/meson-crosscompile.txt
    echo "cpp = '$tc_dir/bin/$tc_target-g++'" >> $tc_dir/meson-crosscompile.txt
    echo "ar = '$tc_dir/bin/$tc_target-ar'" >> $tc_dir/meson-crosscompile.txt
    echo "strip = '$tc_dir/bin/$tc_target-strip'" >> $tc_dir/meson-crosscompile.txt
    echo "pkg-config = 'pkg-config'" >> $tc_dir/meson-crosscompile.txt
    echo "" >> $tc_dir/meson-crosscompile.txt
    echo "[built-in options]" >> $tc_dir/meson-crosscompile.txt
    echo "pkg_config_path = '$tc_dir/$tc_target/sysroot/usr/lib/pkgconfig'" >> $tc_dir/meson-crosscompile.txt
    echo "" >> $tc_dir/meson-crosscompile.txt
    echo "[host_machine]" >> $tc_dir/meson-crosscompile.txt
    echo "system = 'linux'" >> $tc_dir/meson-crosscompile.txt
    echo "cpu_family = 'arm'" >> $tc_dir/meson-crosscompile.txt
    echo "cpu = 'arm'" >> $tc_dir/meson-crosscompile.txt
    echo "endian = 'little'" >> $tc_dir/meson-crosscompile.txt
    echo "" >> $tc_dir/meson-crosscompile.txt
    echo "[properties]" >> $tc_dir/meson-crosscompile.txt
    echo "target='Kindle'" >> $tc_dir/meson-crosscompile.txt
    echo "arch = '$arch'" >> $tc_dir/meson-crosscompile.txt
    chmod a-w $tc_dir/meson-crosscompile.txt

    echo "[*] Downloading Kindle firmware"

    if ! [ -d "./cache/${tc_target}" ]; then
        mkdir -p ./cache/${tc_target}
    fi
    echo "Downloading from: ${FIRM_URL}"
    curl --progress-bar -L -C - -o "./cache/${tc_target}/firmware.bin" "${FIRM_URL}"

    echo "[*] Building Latest KindleTool"
    cd KindleTool/
        make
    cd ..

    echo "[*] Extracting firmware"
    if [ -d "./cache/${tc_target}/firmware/" ]; then
        sudo rm -rf "./cache/${tc_target}/firmware/"
    fi

    KindleTool/KindleTool/Release/kindletool extract "./cache/${tc_target}/firmware.bin" "./cache/${tc_target}/firmware/"
    cd "./cache/${tc_target}/firmware/"
        gunzip rootfs.img.gz
        mkdir mnt
        sudo mount -o loop rootfs.img mnt
    cd ../../..

    

    echo "[*] Parsing pkgconfig files"
    mkdir -p ./patch/any/usr/lib/pkgconfig
    cp -r ./pkgconfig ./patch/any/usr/lib/
    for filepath in ./patch/any/usr/lib/pkgconfig/*
    do
        sed -i "s@%SYSROOT%@$sysroot_dir@g" "$filepath"
        sed -i "s@%TARGET%@$tc_target@g" "$filepath"
    done

    echo "[*] Executing jobs for additional libraries"
    ###
    # Lipc
    ###
    echo "[*] Copying openlipc"
    cp ./openlipc/include/openlipc.h ./patch/any/usr/include/lipc.h

    echo "[*] Copying cJSON"
    cp ./cJSON/cJSON.h ./patch/any/usr/include/cJSON.h
    cp ./cJSON/cJSON_Utils.h ./patch/any/usr/include/cJSON_Utils.h



    echo "[*] Copying patch files to sysroot"
    # Copy universal stuff
    cd "./patch/any"
        find . -type d -exec chmod -R a+w $sysroot_dir/{} ';'
    cd ../..

    chmod a+w $sysroot_dir/
    cp -r ./patch/any/* $sysroot_dir/
    chmod a-w $sysroot_dir/
    cd "./patch/any"
        find . -type d -exec chmod -R a-w $sysroot_dir/{} ';'
    cd ../..




    echo "[*] Copying firmware library files to sysroot"
    chmod -R a+w $sysroot_dir/lib
    chmod -R a+w $sysroot_dir/usr/lib
    sudo chown -R $USER: ./cache/${tc_target}/firmware/mnt/usr/lib/*
    sudo chown -R $USER: ./cache/${tc_target}/firmware/mnt/lib/*
    cp -rn ./cache/${tc_target}/firmware/mnt/usr/lib/* $sysroot_dir/usr/lib/
    cp -rn ./cache/${tc_target}/firmware/mnt/lib/* $sysroot_dir/lib/
    chmod -R a-w $sysroot_dir/usr/lib
    chmod -R a-w $sysroot_dir/lib


    chmod a-w $tc_dir/


    echo "[*] Cleaning up"
    cd "./cache/${tc_target}/firmware/"
        sudo umount mnt
    cd ../../..

    echo "===================================================================================================="
    echo "[*] Kindle (unofficial) SDK Installed"
    echo "[*] To cross-compile via Meson, use the meson-crosscompile.txt file at:"
    echo "[*] $tc_dir/meson-crosscompile.txt"
    echo "===================================================================================================="
}

sudo echo # Do sudo auth beforehand in case the user leaves when we actually need it lol
cd $(dirname "$0")

HELP_MSG="
kindle-sdk - The Unofficial Kindle SDK

usage: $0 PLATFORM

Supported platforms:

	kindlepw2
	kindlehf
"

if [ $# -lt 1 ]; then
	echo "Missing argument"
	echo "${HELP_MSG}"
	exit 1
fi

case $1 in
	-h)
		echo "${HELP_MSG}"
		exit 0
		;;
	kindlehf)
		Setup_SDK "arm-${1}-linux-gnueabihf" "armhf" "https://s3.amazonaws.com/firmwaredownloads/update_kindle_all_new_paperwhite_v2_5.16.3.bin"
		;;
	kindlepw2)
		Setup_SDK "arm-${1}-linux-gnueabi" "armel" "https://s3.amazonaws.com/G7G_FirmwareUpdates_WebDownloads/update_kindle_5.4.2.bin"
		;;
	*)
		echo "[!] $1 not supported!"
		echo "${HELP_MSG}"
		exit 1
		;;
esac
