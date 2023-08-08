#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function deploy_flash() {   
    local INDEX=${1##*/}
    local PATTERN=${1//'/'/'\/'}
      
    df | awk "\$1 ~ /$PATTERN/ {cmd=\"sudo umount \"\$6; print cmd; system(cmd)}"
    cat /proc/partitions |  awk "\$4 ~/${INDEX}[^[:digit:]]*[0-9]+/ {cmd=\"sudo wipefs -af /dev/\"\$4; print cmd; system(cmd)}"
    sudo wipefs -af $1
        
    (       
        echo n 
        echo p 
        echo 1 
        echo   
        echo +128M        
        echo n 
        echo p 
        echo 2 
        echo   
        echo +256M
        echo t
        echo 1
        echo b 
        echo t  
        echo 2
        echo 83
        echo w 
    ) | sudo fdisk $1


    local DEVICES=($(sudo fdisk -l $1 | awk "\$1 ~ /$PATTERN/ {print \$1}" | tr '\n' ' '))     
    sudo mkfs.vfat -F 32 -n bootfs ${DEVICES[0]}    
    sudo mkfs.ext4 -L rootfs ${DEVICES[1]}

    cd "$CONFIG_DEPLOY_DIR_PATH"
    mkdir boot root
    sudo mount ${DEVICES[0]} boot
    sudo mount ${DEVICES[1]} root      

    case $CONFIG_DEPLOY_BOOTFS_TYPE in
        sdcard|emmc|usb)
            cp {u-boot.bin,linux.itb,boot.scr} "$CONFIG_BOOTFS_DIR_PATH"
            sudo cp -r "$CONFIG_BOOTFS_DIR_PATH"/* boot
            sudo cp -dpR "$CONFIG_ROOTFS_DIR_PATH"/* root           
            ;;

        tftp)
            cp {u-boot.bin,boot.scr} "$CONFIG_BOOTFS_DIR_PATH"
            sudo cp -r "$CONFIG_BOOTFS_DIR_PATH"/* boot
            ;;
    esac    

    sudo umount boot
    sudo umount root
    sudo rm -rf boot root
    
    echo done 
}


function deploy_flash_sdcard() { 
    deploy_flash /dev/mmcblk0
}


function deploy_flash_image() {
    cd "$CONFIG_DEPLOY_DIR_PATH"    
    dd if=/dev/zero of=linux.img bs=K count=2M
    local LOOP=$(sudo losetup --show -f -P linux.img)
    deploy_flash $LOOP
    sudo losetup -d $LOOP 
   
}


function deploy_flash_usb() {
    deploy_flash /dev/sdb
}



case $CONFIG_DEPLOY_STORAGE_TYPE in
    sdcard|emmc)
        deploy_flash_sdcard
        ;;

    image)
        deploy_flash_image
        ;;

    usb) 
        deploy_flash_usb
        ;;
        
    *) 
        echo unknown deploy parameter 
        exit 20
        ;;
esac



cd "$ORIGIN_PATH"



