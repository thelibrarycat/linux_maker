#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function raspberry-pi-3b_kernel_download()
{
    if [[ ! -d $CONFIG_LINUX_DIR_PATH ]]; then
        cd "$CONFIG_SOURCE_DIR_PATH/linux"

        local VERSION="${CONFIG_LINUX_DIR_PATH##*/}"
        git clone --depth=1 -b $VERSION --single-branch https://github.com/raspberrypi/linux.git $VERSION
       
    fi
}


function raspberry-pi-3b_kernel_copy() {
    local ARCH="$CONFIG_ARCH_NAME"
    local CROSS_COMPILE="$CONFIG_ARCH_CROSS_COMPILE"    
    local KERNEL_NAME="$CONFIG_LINUX_KERNEL" 
    local DEVICE_TREE_NAME="$CONFIG_LINUX_DEVICE_TREE"    
    
    cd "$CONFIG_LINUX_DIR_PATH"
    cp arch/$ARCH/boot/$KERNEL_NAME "$CONFIG_DEPLOY_DIR_PATH"
    cp arch/$ARCH/boot/dts/broadcom/$DEVICE_TREE_NAME "$CONFIG_DEPLOY_DIR_PATH"

    mkdir -p "$CONFIG_BOOTFS_DIR_PATH"/overlays
    cp arch/$ARCH/boot/dts/overlays/*.dtb* "$CONFIG_BOOTFS_DIR_PATH"/overlays       
    
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH="$CONFIG_ROOTFS_DIR_PATH" modules_install
    
}


function raspberry-pi-3b_buildroot_copy() {
    local TARGET_DIR="$CONFIG_SOURCE_DIR_PATH/${CONFIG_BUILDROOT_DEFCONFIG%_*}"

    cd "$TARGET_DIR"/images

    cp -r rpi-firmware/{bootcode.bin,start.elf,overlays} "$CONFIG_BOOTFS_DIR_PATH"
    cp -r {bcm2710-rpi-3-b.dtb,$CONFIG_LINUX_KERNEL,rootfs.cpio.gz,u-boot.bin} "$CONFIG_DEPLOY_DIR_PATH"
        
    (
    cat << __EOF__ > "$CONFIG_BOOTFS_DIR_PATH"/config.txt
enable_uart=1
core_freq=250 
arm_64bit=1
kernel=u-boot.bin
__EOF__
    )  

    mkdir rfs 
    sudo mount -o loop  rootfs.ext4 rfs  
    sudo cp -r rfs/*  "$CONFIG_ROOTFS_DIR_PATH"
    sudo umount rfs 
    rm -r rfs   

}




function raspberry-pi-3b_firmware_copy() {    
    local FIRMWARE_DIR="$CONFIG_FIRMWARE_DIR_PATH/$CONFIG_GERERAL_TITLE"

    if [[ ! -d $FIRMWARE_DIR ]]; then
        cd "$CONFIG_FIRMWARE_DIR_PATH"
        git clone --depth=1 https://github.com/raspberrypi/firmware.git $CONFIG_GERERAL_TITLE
    fi

    cd "$FIRMWARE_DIR"
    cp  boot/{bootcode.bin,start.elf} $CONFIG_BOOTFS_DIR_PATH

    (
    cat << __EOF__ > "$CONFIG_BOOTFS_DIR_PATH"/config.txt
enable_uart=1
core_freq=250 
arm_64bit=1
kernel=u-boot.bin
__EOF__
    )  
        
}   


function raspberry-pi-3b_qemu_emulate() {
    cd "$CONFIG_DEPLOY_DIR_PATH" 

    local SERVER_IP="${CONFIG_NET_BRIDGE_IP%/*}"
    local TARGET_IP="${CONFIG_NET_TARGET_IP_LIST[0]}"

    # $CONFIG_QEMU_EMULATOR \
    #   -M raspi3b \
    #   -cpu cortex-a72 \
    #   -m 1G -smp 4 \
    #   -kernel u-boot.bin \
    #   -dtb bcm2710-rpi-3-b.dtb \
    #   -append "earlycon=pl011,0x3f201000 console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw " \
    #   -drive id=hd-root,if=none,format=raw,file=sdcard.img \
    #   -usb \
    #   -device usb-kbd \
    #   -device usb-mouse \
    #   -netdev tap,id=net1,ifname=tap0,script=no,downscript=no \
    #   -device usb-net,netdev=net1,mac=00:33:22:11:00:22 \
      


    $CONFIG_QEMU_EMULATOR \
    -M virt \
    -cpu cortex-a72 \
    -m 1G -smp 2 \
    -drive if=none,file=linux.img,format=raw,media=disk,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -device virtio-mouse-device \
    -device virtio-keyboard-device \
    -netdev tap,id=n1,ifname=tap0,script=no,downscript=no \
    -device virtio-net-device,netdev=n1,mac=00:33:22:11:00:22 \
    -nographic \
    -bios u-boot.bin \
    # -kernel Image \
    # -append "earlycon=pl011,0x3f201000 console=ttyAMA0 root=/dev/mmcblk0p2 rootwait rw " \
      
}




case $1 in
    kernel_download)
        raspberry-pi-3b_kernel_download
        ;;
        
    kernel_copy)
        raspberry-pi-3b_kernel_copy
        ;;

    buildroot_copy)
        raspberry-pi-3b_buildroot_copy
        ;;
        
    firmware_copy)
        raspberry-pi-3b_firmware_copy
        ;;

    qemu_emulate)
        raspberry-pi-3b_qemu_emulate
        ;;
        
    *) 
        echo unknown raspberry-pi-3b parameter 
        exit 20
        ;;
esac




cd "$ORIGIN_PATH"





