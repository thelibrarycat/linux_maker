#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function kernel_download() {
    bash "$CURRENT_PATH"/$CONFIG_GERERAL_TITLE.sh kernel_download
}


function kernel_defconfig() {
    local ARCH="$CONFIG_ARCH_NAME"
    local CROSS_COMPILE="$CONFIG_ARCH_CROSS_COMPILE"
    local DEFCONFIG="$CONFIG_LINUX_DEFCONFIG"    
  
    cd "$CONFIG_LINUX_DIR_PATH"
    make distclean  
    
    if [[ ! -e .config  ]]; then
        if [[ -e "$CONFIG_CONFIGURATION_DIR_PATH/kernel.config" ]]; then
            cp  "$CONFIG_CONFIGURATION_DIR_PATH/kernel.config"  .config
            echo include existing kernel config
        else
            make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $DEFCONFIG
        fi    
    fi     
}


function kernel_build() {
    local ARCH="$CONFIG_ARCH_NAME"
    local CROSS_COMPILE="$CONFIG_ARCH_CROSS_COMPILE"
    local KERNEL_NAME="$CONFIG_LINUX_KERNEL" 

    cd "$CONFIG_LINUX_DIR_PATH"
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $KERNEL_NAME modules dtbs -j$(nproc) 
}


function kernel_copy() {
    bash "$CURRENT_PATH"/$CONFIG_GERERAL_TITLE.sh kernel_copy    
}



case $1 in
    all)
        kernel_download
        kernel_defconfig
        kernel_build
        kernel_copy
        ;;

    download)
        kernel_download
        ;;

    defconfig)
        kernel_defconfig
        ;;
 
    build)        
        kernel_build
        ;;

    copy)
        kernel_copy
        ;;

    *) 
        echo  unknown kernel parameter
        exit 20
        ;;
esac


cd "$ORIGIN_PATH"




