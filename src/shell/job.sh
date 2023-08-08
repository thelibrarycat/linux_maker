#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


for COMMAND in ${CONFIG_GERERAL_COMMANDS[*]}; do
    case $COMMAND in
        init_create_folder)
            bash "$CURRENT_PATH"/initialize.sh create_dependent_folder 
            ;;

        init_clear_deploy)
            bash "$CURRENT_PATH"/initialize.sh clear_deploy_folder 
            ;;

        init_clear_boot)
            bash "$CURRENT_PATH"/initialize.sh clear_bootfs_folder 
            ;;
       
        init_clear_root)
            bash "$CURRENT_PATH"/initialize.sh clear_rootfs_folder 
            ;;

        firmware_copy)
            bash "$CURRENT_PATH"/$CONFIG_GERERAL_TITLE.sh firmware_copy
            ;;

        tftp) 
            bash "$CURRENT_PATH"/tftp.sh 
            ;;

        nfs) 
            bash "$CURRENT_PATH"/nfs.sh 
            ;;

        bridge)
            bash "$CURRENT_PATH"/bridge.sh
            ;;

        busybox_all)
            bash "$CURRENT_PATH"/busybox.sh all
            ;;  

        busybox_load)
            bash "$CURRENT_PATH"/busybox.sh download
            ;;

        busybox_build)
            bash "$CURRENT_PATH"/busybox.sh build
            ;; 
   
        busybox_post)
            bash "$CURRENT_PATH"/busybox.sh postprocess
            ;;

        busybox_ramdisk)
            bash "$CURRENT_PATH"/busybox.sh ramdisk
            ;;

        buildroot_all)
            bash "$CURRENT_PATH"/buildroot.sh all
            ;;
            
        buildroot_load)
            bash "$CURRENT_PATH"/buildroot.sh download
            ;;

        buildroot_build)
            bash "$CURRENT_PATH"/buildroot.sh build
            ;;

        buildroot_copy)
            bash "$CURRENT_PATH"/buildroot.sh copy
            ;;

        kernel_all)
            bash "$CURRENT_PATH"/kernel.sh all 
            ;;

        kernel_load)
            bash "$CURRENT_PATH"/kernel.sh download
            ;;

        kernel_config)
            bash "$CURRENT_PATH"/kernel.sh defconfig
            ;;
 
        kernel_build)        
            bash "$CURRENT_PATH"/kernel.sh build
            ;;

        kernel_copy)
            bash "$CURRENT_PATH"/kernel.sh copy
            ;;
 
        uboot_all)
            bash "$CURRENT_PATH"/uboot.sh all
            ;;

        uboot_load)
            bash "$CURRENT_PATH"/uboot.sh download
            ;;

        uboot_config)
            bash "$CURRENT_PATH"/uboot.sh defconfig
            ;;

        uboot_build)        
            bash "$CURRENT_PATH"/uboot.sh build
            ;;

        uboot_post)
            bash "$CURRENT_PATH"/uboot.sh postprocess
            ;;
        
        deploy) 
            bash "$CURRENT_PATH"/deploy.sh
            ;;

        qemu_all)
            bash "$CURRENT_PATH"/qemu.sh all
            ;;

        qemu_load) 
            bash "$CURRENT_PATH"/qemu.sh download
            ;;
        
        qemu_build) 
            bash "$CURRENT_PATH"/qemu.sh build
            ;;    

        gdb_all) 
            bash "$CURRENT_PATH"/gdb.sh
            ;;            
    esac     
done




cd "$ORIGIN_PATH"



