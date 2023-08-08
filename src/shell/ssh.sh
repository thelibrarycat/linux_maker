#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function ssh_download() {    
    local DROPBEAR="dropbear-2022.83"

    cd "$CONFIG_PACKAGES_DIR_PATH" 
    if [[ ! -d $DROPBEAR ]]; then        
        wget https://matt.ucc.asn.au/dropbear/releases/$DROPBEAR.tar.bz2   
        tar xf $DROPBEAR.tar.bz2
        rm -rf $DROPBEAR.tar.bz2 
    fi
}


function ssh_build() {
    local DROPBEAR="dropbear-2022.83"

    cd "$CONFIG_PACKAGES_DIR_PATH"/$DROPBEAR
    make distclean

    ./configure --prefix="$CONFIG_ROOTFS_DIR_PATH" --disable-zlib --host=arm-linux \
        CC=${CONFIG_ARCH_CROSS_COMPILE}gcc  STRIP=${CONFIG_ARCH_CROSS_COMPILE}strip 
    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" strip -j$(nproc)
    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" install
}


function ssh_postprocess() {
    cd "$CONFIG_ROOTFS_DIR_PATH"
    
    mkdir -p etc/dropbear   
   
    (
        echo "#!/bin/sh"
        echo
        echo "start() {"
        echo "  if [[ ! -f /etc/dropbear/dropbear_rsa_host_key ]]; then"
        echo "    /bin/dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key"
        echo "  fi"
        echo
        echo "  if [[ ! -f /etc/dropbear/dropbear_dss_host_key ]]; then"
        echo "    /bin/dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key"
        echo "  fi"
        echo 
        echo "  /sbin/dropbear"
        echo "}"
        echo
        echo "usage() {"
        echo "  echo Usage: dropbear {start}"
        echo "}"
        echo 
        echo "case \$1 in"
        echo "  start) start ;;"
        echo "  *) usage ;;"
        echo "esac"
    ) > etc/init.d/dropbear

    chmod +x etc/init.d/dropbear

    # cd etc/rc.d   
    # rm dropbear
    # ln -s ../init.d/dropbear dropbear     

}


case $1 in
    all)
        ssh_download
        ssh_build
        ssh_postprocess
        ;;
        
    download)
        ssh_download
        ;;

    build)
        ssh_build
        ;;

    postprocess)
        ssh_postprocess
        ;;
        
    *) 
        echo unknown ssh parameter 
        exit 20
        ;;
esac




cd "$ORIGIN_PATH"
