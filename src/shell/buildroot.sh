#!/biin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function buildroot_download() {      
    if [[ ! -d $CONFIG_BUILDROOT_DIR_PATH ]]; then
        # sudo apt install -y git build-essential wget cpio unzip rsync bc libncurses5-dev

        cd "$CONFIG_SOURCE_DIR_PATH"

        local VERSION="${CONFIG_BUILDROOT_DIR_PATH##*/}"               
        wget https://git.buildroot.net/buildroot/snapshot/$VERSION.tar.bz2  
        tar jxvf $VERSION.tar.bz2
        rm -rf $VERSION.tar.bz2       
    fi
   
}


function buildroot_build() { 
    local TARGET_DIR="$CONFIG_SOURCE_DIR_PATH/${CONFIG_BUILDROOT_DEFCONFIG%_*}"
    mkdir -p $TARGET_DIR

    cd "$CONFIG_BUILDROOT_DIR_PATH"
    if [[ -e "$CONFIG_CONFIGURATION_DIR_PATH/buildroot.config" ]]; then
        cp "$CONFIG_CONFIGURATION_DIR_PATH/buildroot.config" "$TARGET_DIR"/.config
        echo include existing buildroot config
    else
        # make list-defconfigs | less
        make O="$TARGET_DIR" $CONFIG_BUILDROOT_DEFCONFIG     
    fi
   
    make O="$TARGET_DIR" -j$(nproc)
}


function buildroot_copy() {   
    bash "$CURRENT_PATH"/$CONFIG_GERERAL_TITLE.sh buildroot_copy
}



case $1 in
    all)
        buildroot_download
        buildroot_build
        buildroot_copy
        ;;
        
    download)
        buildroot_download
        ;;

    build)
        buildroot_build
        ;;

    copy)
        buildroot_copy
        ;;
        
    *) 
        echo unknown buildroot parameter 
        exit 20
        ;;
esac






cd "$ORIGIN_PATH"




