#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function uboot_create_fit() {
    local ROOTFS_TYPE="$CONFIG_DEPLOY_ROOTFS_TYPE" 
    local KERNEL_NAME="$CONFIG_LINUX_KERNEL"
    local DEVICE_TREE_NAME="$CONFIG_LINUX_DEVICE_TREE"
    local ARCH="$CONFIG_ARCH_NAME"   
    local KERNEL_ADDR="$CONFIG_UBOOT_KERNEL_MEMORY_ADDRESS"   
    local DESCRIPTION="$CONFIG_GERERAL_TITLE"     

    cd "$CONFIG_DEPLOY_DIR_PATH"

    (
    echo "/*"
    echo " * U-Boot uImage source file with multiple kernels, ramdisks and FDT blobs"
    echo " */"
    echo
    echo "/dts-v1/;"
    echo
    echo "/ {"
    echo "    description = \"Simple image with single Linux kernel and FDT blob\";"
    echo "    #address-cells = <1>;"
    echo 
    echo "    images {"
    echo "        kernel@1 {"
    echo "            description = \"linux kernel\";"
    echo "            data = /incbin/(\"$CONFIG_DEPLOY_DIR_PATH/$KERNEL_NAME\");"
    echo "            type = \"kernel\";"
    echo "            arch = \"$ARCH\";"
    echo "            os = \"linux\";"
    echo "            compression = \"none\";"
    echo "            load = <$KERNEL_ADDR>;"
    echo "            entry = <$KERNEL_ADDR>;"
    echo "            hash@1 {"
    echo "                algo = \"crc32\";"
    echo "            };"    
    echo "        };"
    echo

    if [[ $ROOTFS_TYPE == ramdisk ]]; then
    echo "        initrd@1 {"
    echo "            description = \"root filesystem\";"
    echo "            data = /incbin/(\"$CONFIG_DEPLOY_DIR_PATH/rootfs.cpio.gz\");"    
    echo "            type = \"ramdisk\";"
    echo "            arch = \"$ARCH\";"
    echo "            os = \"linux\";"
    echo "            compression = \"gzip\";"   
    echo "            hash@1 {"
    echo "                algo = \"crc32\";"
    echo "            };"
    echo "        };"
    echo
    fi	

    if [[ -n $DEVICE_TREE_NAME ]]; then
    echo "        fdt@1 {"
    echo "            description = \"device tree\";"
    echo "            data = /incbin/(\"$CONFIG_DEPLOY_DIR_PATH/$DEVICE_TREE_NAME\");"
    echo "            type = \"flat_dt\";"
    echo "            arch = \"$ARCH\";"
    echo "            compression = \"none\";"
    echo "            hash@1 {"
    echo "                algo = \"crc32\";"
    echo "            };"
    echo "        };"
    echo
    fi
    
    echo "    };"
    echo 
    echo "    configurations {"
    echo "        default = \"config@1\";"
    echo
    echo "        config@1 {"
    echo "            description = \"$DESCRIPTION\";"
    echo "            kernel = \"kernel@1\";"
    if [[ $ROOTFS_TYPE == ramdisk ]]; then
    echo "            ramdisk = \"initrd@1\";"
    fi
    if [[ -n $DEVICE_TREE_NAME ]]; then
    echo "            fdt = \"fdt@1\";"
    fi
    echo "        };"
    echo         
    echo "    };"
    echo "};"
    ) >  linux.its

    sync        

    "$CONFIG_UBOOT_DIR_PATH"/tools/mkimage -f linux.its linux.itb
    
}


function uboot_create_load_script() {
    local DEVICE="$1"
    local LOAD="fatload $DEVICE 0:1"
    local ROOTFS_TYPE="$CONFIG_DEPLOY_ROOTFS_TYPE"
    local UIMAGE_TYPE="$CONFIG_UBOOT_IMAGE_TYPE" 
    local DEVICE_TREE_NAME="$CONFIG_LINUX_DEVICE_TREE"
    local KERNEL_NAME="$CONFIG_LINUX_KERNEL" 
    local ARGS="$CONFIG_UBOOT_BOOTARGS $(uboot_create_rootfs_command)" 

    if [[ $DEVICE == tftp ]]; then
        LOAD="tftp"
    fi

    echo setenv bootargs \"$ARGS\" 
    if [[ $UIMAGE_TYPE == FIT ]]; then       
        echo $LOAD \${pxefile_addr_r} linux.itb               
        echo bootm \${pxefile_addr_r}  
    else
        echo $LOAD \${kernel_addr_r} $KERNEL_NAME
        echo $LOAD \${fdt_addr_r} $DEVICE_TREE_NAME

        if [[ $ROOTFS_TYPE == ramdisk ]]; then
            echo $LOAD \${ramdisk_addr_r} rootfs.cpio.gz.uboot
            echo booti \${kernel_addr_r} \${ramdisk_addr_r} \${fdt_addr_r}            
        else
            echo booti \${kernel_addr_r} - \${fdt_addr_r}
        fi
    fi

}


function uboot_create_boot_script() { 
    local BOOTFS_TYPE="$CONFIG_DEPLOY_BOOTFS_TYPE"       

    cd "$CONFIG_DEPLOY_DIR_PATH"
    
    (    
    case $BOOTFS_TYPE in
        sdcard|emmc)              
            uboot_create_load_script mmc           
            ;;

        usb)
            echo usb start
            uboot_create_load_script usb           
            ;;

        tftp)
            echo setenv ipaddr ${CONFIG_NET_TARGET_IP_LIST[0]}
            echo setenv serverip ${CONFIG_NET_BRIDGE_IP%/*}
            echo setenv bootcmd \"tftp \${scriptaddr} tftp.scr\;source \${scriptaddr}\"
            echo saveenv 
            echo reset           
            ;;

        *) 
            echo  unknown u-boot bootfs parameter
            exit 20
            ;;        
    esac   

    ) > boot_cmd.txt  

    "$CONFIG_UBOOT_DIR_PATH"/tools/mkimage -A $CONFIG_ARCH_NAME -O linux -T script -C none -d boot_cmd.txt boot.scr
    
}


function uboot_create_tftp_script() {    
    cd "$CONFIG_DEPLOY_DIR_PATH"            
    
    uboot_create_load_script tftp > tftp_cmd.txt    
    
    # (
    #     echo tftp \${pxefile_addr_r} u-boot.bin       
    #     echo fatwrite mmc 0:1 \${pxefile_addr_r} u-boot.bin \${filesize}
    #     echo fatls mmc 0:1
    # ) > tftp_cmd.txt

    "$CONFIG_UBOOT_DIR_PATH"/tools/mkimage -A $CONFIG_ARCH_NAME -O linux -T script -C none -d tftp_cmd.txt tftp.scr
    
}


function uboot_postprocess() {
    uboot_create_boot_script
    uboot_create_tftp_script
    uboot_create_fit
}


function uboot_create_rootfs_command() {
    local ROOTFS_TYPE="$CONFIG_DEPLOY_ROOTFS_TYPE"
    local ROOTFS_FORMAT="$CONFIG_DEPLOY_ROOTFS_FORMAT"
    local SERVER_IP="${CONFIG_NET_BRIDGE_IP%/*}"
    local TARGET_IP="${CONFIG_NET_TARGET_IP_LIST[0]}"

    case $ROOTFS_TYPE in
        sdcard|emmc)           
            echo "root=/dev/mmcblk0p2 rootfstype=$ROOTFS_FORMAT rootwait rw"           
            ;;

        usb)
            echo "root=/dev/sda1 rootfstype=$ROOTFS_FORMAT rootwait rw"
            ;;

        ramdisk)
            echo ""
            ;;

        nfs)
            echo "root=/dev/nfs rootfstype=$ROOTFS_FORMAT ip=$TARGET_IP:::::eth0 nfsroot=$SERVER_IP:$CONFIG_ROOTFS_DIR_PATH,nfsvers=3 rw"
            ;;

        *) 
            echo  unknown u-boot rootfs parameter
            exit 20
            ;; 
    esac
}


function uboot_create_command() {
    local SCRIPT_ADDRESS="$CONFIG_UBOOT_SCRIPT_MEMORY_ADDRESS"
    local CMD="" 

    case $CONFIG_DEPLOY_STORAGE_TYPE in
        sdcard|emmc|image)            
            CMD+="fatload mmc 0:1 $SCRIPT_ADDRESS boot.scr;" 
            CMD+="source $SCRIPT_ADDRESS;"   
            ;;

        usb)
            CMD+="usb start;fatload usb 0:1 $SCRIPT_ADDRESS boot.scr;"
            CMD+="source $SCRIPT_ADDRESS;" 
            ;;    

        *) 
            echo  unknown u-boot bootfs parameter
            exit 20
            ;;        
    esac    

    modify_config_with_string CONFIG_BOOTCOMMAND "$CMD" "$CONFIG_UBOOT_DIR_PATH"/.config    
}


function uboot_preprocess() {    
    uboot_create_command
}


function uboot_download() { 
    if [[ ! -d $CONFIG_UBOOT_DIR_PATH ]]; then
        #sudo apt install device-tree-compiler

        cd "$CONFIG_SOURCE_DIR_PATH"
        
        local VERSION="${CONFIG_UBOOT_DIR_PATH##*/}"
        wget https://ftp.denx.de/pub/u-boot/$VERSION.tar.bz2  
        tar jxvf $VERSION.tar.bz2
        rm -rf $VERSION.tar.bz2
       
    fi    
    
}


function uboot_defconfig() {
    local CROSS_COMPILE="$CONFIG_ARCH_CROSS_COMPILE"
    local DEFCONFIG="$CONFIG_UBOOT_DEFCONFIG"
   
    cd "$CONFIG_UBOOT_DIR_PATH"
    make distclean     
   
    if [[ -e "$CONFIG_CONFIGURATION_DIR_PATH/uboot.config" ]]; then
        cp  "$CONFIG_CONFIGURATION_DIR_PATH/uboot.config"  .config
        echo include existing uboot config
    else
        make CROSS_COMPILE="$CROSS_COMPILE" $DEFCONFIG
    fi   
   
}


function uboot_build() { 
    local CROSS_COMPILE="$CONFIG_ARCH_CROSS_COMPILE"

    cd "$CONFIG_UBOOT_DIR_PATH"    
    make CROSS_COMPILE="$CROSS_COMPILE" -j$(nproc)
    cp u-boot.bin "$CONFIG_DEPLOY_DIR_PATH" 
}



       
case $1 in
    all)
        uboot_download
        uboot_defconfig
        uboot_preprocess
        uboot_build 
        uboot_postcondion       
        ;;

    download)
        uboot_download
        ;;

    defconfig)
        uboot_defconfig
        ;;

    build)        
        uboot_preprocess        
        uboot_build
        ;;

    postprocess)
        uboot_postprocess
        ;;

    *) 
        echo  unknown uboot parameter
        exit 20
        ;;
esac



cd "$ORIGIN_PATH"







        
   
