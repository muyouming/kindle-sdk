#!/bin/sh

ARMEL_FIRM_URL="https://www.amazon.com/update_Kindle_Paperwhite_6th_Gen" # MUH GLIBC
ARMHF_FIRM_URL="https://www.amazon.com/update_Kindle_Paperwhite_10th_Gen"

Setup_SDK() {
    tc_target="$1"
    arch="$2"
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

    if ! [ -d "./cache/${arch}" ]; then
        mkdir -p ./cache/${arch}
    fi
    if ! [ -f "./cache/${arch}/firmware.bin" ]; then
        case $arch in
            armhf)
                FIRM_URL=$ARMHF_FIRM_URL
                ;;
            armel)
                FIRM_URL=$ARMEL_FIRM_URL
                ;;
        esac
        echo "Downloading from: ${FIRM_URL}"
        curl --progress-bar -L "${FIRM_URL}" -o "./cache/${arch}/firmware.bin"
    fi

    echo "[*] Building Latest KindleTool"
    pushd KindleTool/
        make
    popd

    echo "[*] Extracting firmware"
    if [ -d "./cache/${arch}/firmware/" ]; then
        sudo rm -rf "./cache/${arch}/firmware/"
    fi

    KindleTool/KindleTool/Release/kindletool extract "./cache/${arch}/firmware.bin" "./cache/${arch}/firmware/"
    pushd "./cache/${arch}/firmware/"
        gunzip rootfs.img.gz
        mkdir mnt
        sudo mount -o loop rootfs.img mnt
    popd

    echo "[*] Parsing pkgconfig files"
    mkdir -p ./overlay/any/usr/lib/pkgconfig
    cp -r ./pkgconfig ./overlay/any/usr/lib/
    for filepath in ./overlay/any/usr/lib/pkgconfig/*
    do
        sed -i "s@%SYSROOT%@$sysroot_dir@g" "$filepath"
        sed -i "s@%TARGET%@$tc_target@g" "$filepath"
    done

    echo "[*] Copying overlay files to sysroot"
    # Copy universal stuff
    pushd "./overlay/any"
        find . -type d -exec chmod -R a+w $sysroot_dir/{} ';'
    popd
    chmod a+w $sysroot_dir/
    cp -rv ./overlay/any/* $sysroot_dir/
    chmod a-w $sysroot_dir/
    pushd "./overlay/any"
        find . -type d -exec chmod -R a-w $sysroot_dir/{} ';'
    popd

    echo "[*] Copying firmware library files to sysroot"
    chmod -R a+w $sysroot_dir/lib
    chmod -R a+w $sysroot_dir/usr/lib
    sudo chown -R $USER: ./cache/${arch}/firmware/mnt/usr/lib/*
    sudo chown -R $USER: ./cache/${arch}/firmware/mnt/lib/*
    cp -rvn ./cache/${arch}/firmware/mnt/usr/lib/* $sysroot_dir/usr/lib/
    cp -rvn ./cache/${arch}/firmware/mnt/lib/* $sysroot_dir/lib/
    chmod -R a-w $sysroot_dir/usr/lib
    chmod -R a-w $sysroot_dir/lib


    chmod a-w $tc_dir/


    echo "[*] Cleaning up"
    pushd "./cache/${arch}/firmware/"
        sudo umount mnt
    popd
}

sudo echo # Do sudo auth beforehand in case the user leaves when we actually need it lol

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
		Setup_SDK "arm-${1}-linux-gnueabihf" "armhf"
		;;
	kindlepw2)
		Setup_SDK "arm-${1}-linux-gnueabi" "armel"
		;;
	*)
		echo "[!] $1 not supported!"
		echo "${HELP_MSG}"
		exit 1
		;;
esac
