#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


if [[ ! -d ${CONFIG_ARCH_CROSS_COMPILE%/*} ]]; then
    # sudo apt install git texinfo help2man gawk libtool-bin automake libncurses5-dev bc bison flex libssl-dev make libc6-dev 
    cd "$CONFIG_SOURCE_DIR_PATH"
    git clone --depth=1 https://github.com/crosstool-ng/crosstool-ng.git crosstool-ng
    cd crosstool-ng
    make distclean  
    ./bootstrap
    ./configure --enable-local
    make -j$(nproc)

    #./ct-ng list-samples
    ./ct-ng $CONFIG_ARCH_PRE_DEFCONFIG  
    #ct-ng menuconfig
    #ct-ng show-$CONFIG_ARCH_PRE_DEFCONFIG      
    ./ct-ng build -j$(nproc)
  
    echo "export PATH=\$PATH:${CONFIG_ARCH_CROSS_COMPILE%/*}" >> ~/.bashrc
    source ~/.bashrc 
fi


 
 
cd "$ORIGIN_PATH"
