#!/biin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function qemu_downlaod() {
    if [[ ! -d $CONFIG_QEMU_DIR_PATH ]]; then
        # sudo apt install ninja-build
        # sudo apt install pkg-config
        # sudo aptitude install libglib2.0-dev    # select  solution 2
        # sudo apt install libpixman-1-dev

        cd "$CONFIG_SOURCE_DIR_PATH"

        local VERSION="${CONFIG_QEMU_DIR_PATH##*/}"    
        wget https://download.qemu.org/$VERSION.tar.bz2      
        tar jxvf $VERSION.tar.bz2      
        rm -rf $VERSION.tar.bz2  
    fi
}


function qemu_build() {
    cd "$CONFIG_QEMU_DIR_PATH"
    make distclean
    mkdir build
    cd build
    ../configure --target-list=aarch64-softmmu,arm-softmmu --prefix="$CONFIG_TOOLS_DIR_PATH/$VERSION"
    make -j$(nproc) 
    make install 

    strip ${CONFIG_QEMU_EMULATOR%/*}/*

    echo "export PATH=\$PATH:${CONFIG_QEMU_EMULATOR%/*}" >> ~/.bashrc
    source ~/.bashrc 
}



case $1 in
    all)
        qemu_downlaod
        qemu_build
        ;;

    download) 
        qemu_downlaod
        ;;
    
    build) 
        qemu_build
        ;;

    *) 
        echo  unknown qemu parameter 
        exit 20
        ;;
esac


cd "$ORIGIN_PATH"




