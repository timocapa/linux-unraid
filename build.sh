#!/usr/bin/env bash

# export vars
UNRAID="${HOME}/unRAID"
NPROC=$(getconf _NPROCESSORS_ONLN)
MODULES="/tmp/lib/modules"
TEMP="INSTALL_MOD_PATH=/tmp"
CLEAN="/tmp/lib"

read -r -p "Select compiler: clang or gcc (c/g) " compiler;
case $compiler in
    c|C)
        echo 'Building bzImage and modules with clang'
	    sleep '1'
	    LLVM=1 make -j"$NPROC" bzImage
	    LLVM=1 make -j"$NPROC"
	    LLVM=1 make -j"$NPROC" modules

	echo 'Installing modules'
	    sleep '1'
	    make "$TEMP" -j"$NPROC" modules_install
        ;;

    g|G)
        echo 'Bulding bzImage and modules with gcc'
	    sleep '1'
	    make -j"$NPROC" bzImage
	    make -j"$NPROC"
	    make -j"$NPROC" modules
	
	echo 'Installing modules'
	    sleep '1'
	    make "$TEMP" -j"$NPROC" modules_install
        ;;

    *)
        exit
        ;;
esac

echo 'Creating unRAID folder in your home dir if it doesnt exist...'
sleep 1
[ -d "${UNRAID}" ] || mkdir "${UNRAID}"

echo 'Copy bzImage to /home/user/unRAID'
sleep '1'
cp "arch/x86/boot/bzImage" "${UNRAID}/bzimage"

echo 'Create unRAID bzmodules'
mksquashfs "$MODULES"/*Unraid* "$UNRAID"/bzmodules -keep-as-directory -noappend

echo 'Generate SHA256sums'
sleep '1'
sha256sum "$UNRAID"/bzmodules | cut -d " " -f 1 > "$UNRAID"/bzmodules.sha256
sha256sum "$UNRAID"/bzimage | cut -d " " -f 1 > "$UNRAID"/bzimage.sha256

read -r -p "Do you wish to clean up? (y/n) " clean;
case $clean in
    y|Y)
	echo 'Cleaning up modules...'
	    rm -r "$CLEAN"
	echo 'Cleaning the kernel...'
	    make clean
        ;;

    n|N)
	echo 'Skipping'
	    exit
        ;;

    *)
        exit
        ;;
esac
