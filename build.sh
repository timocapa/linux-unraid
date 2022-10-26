#!/usr/bin/env bash

# export vars
UNRAID="${HOME}/unRAID"
NPROC=$(getconf _NPROCESSORS_ONLN)
MODULES="/tmp/lib/modules"
TEMP="INSTALL_MOD_PATH=/tmp"
CLEAN="/tmp/lib"

echo -e '\e[93myellow\e[0m = info'
echo -e '\e[92mgreen\e[0m = pass'
echo -e '\e[31mred\e[0m = error'

read -r -p "Select compiler: clang or gcc (c/g) " compiler;
case $compiler in
    c|C)
        echo -e '\e[93mBuilding bzImage and modules with clang\e[0m'
            sleep '1'
            LLVM=1 make -j"$NPROC" unraid_defconfig
            LLVM=1 make -j"$NPROC" bzImage
            LLVM=1 make -j"$NPROC" modules

        echo -e '\e[93mInstalling modules\e[0m'
            sleep '1'
            make "$TEMP" -j"$NPROC" modules_install > /dev/null 2>&1
    ;;

    g|G)
        echo -e '\e[93mBulding bzImage and modules with gcc\e[0m'
            sleep '1'
            make -j"$NPROC" unraid_defconfig
            make -j"$NPROC" bzImage
            make -j"$NPROC" modules

        echo -e '\e[93mInstalling modules\e[0m'
            sleep '1'
            make "$TEMP" -j"$NPROC" modules_install > /dev/null 2>&1
    ;;

    *)
        echo 'Invalid input'
    exit
    ;;
esac

echo -e '\e[93mCreating unRAID folder in your home dir if not present...\e[0m'
sleep 1
[ -d "${UNRAID}" ] || mkdir "${UNRAID}"

echo -e '\e[93mCopying bzImage to /home/user/unRAID..\e[0m'
sleep '1'
cp "arch/x86/boot/bzImage" "${UNRAID}/bzimage"

echo -e '\e[93mCreate unRAID bzmodules\e[0m'
mksquashfs "$MODULES"/*Unraid* "$UNRAID"/bzmodules -keep-as-directory -noappend > /dev/null 2>&1

echo -e '\e[93mGenerating modules checksum\e[0m'
sleep '1'
# cut will break `sha256sum --check`
sha256sum "$UNRAID"/bzmodules | cut -d " " -f 1 > "$UNRAID"/bzmodules.sha256
sha256sum "arch/x86/boot/bzImage" | cut -d " " -f 1 > "$UNRAID"/bzimage.sha256

# more vars for checksumming
BZIMAGE=$(sha256sum "${UNRAID}/bzimage" | cut -d " " -f 1)
BZIMAGESHA=$(cat "${UNRAID}/bzimage.sha256")
BZMODULES=$(sha256sum "${UNRAID}/bzmodules" | cut -d " " -f 1)
BZMODULESSHA=$(cat "${UNRAID}/bzmodules.sha256")

# bzimage
if [ "$BZIMAGE" == "$BZIMAGESHA" ]; then
    echo -e '\e[92mbzimage pass\e[0m'
else
    echo -e '\e[31mbzimage fail - unRAID will not boot\e[0m'
fi

# bzmodules
if [ "$BZMODULES" == "$BZMODULESSHA" ]; then
    echo -e '\e[92mbzmodules pass\e[0m'
else
    echo -e '\e[31mbzmodules fail - unRAID will not boot\e[0m'
fi

read -r -p "Do you wish to clean up? (y/n) " clean;
case $clean in
    y|Y)
        echo -e '\e[93mCleaning up modules...\e[0m'
            rm -r "$CLEAN"
        echo -e '\e[93mCleaning the kernel...\e[0m'
            make clean
            make mrproper
    ;;

    n|N)
        echo 'Skipping'
    exit
    ;;

    *)
        echo 'Invalid input'
    exit
    ;;
esac
