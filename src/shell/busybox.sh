#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))


. "$CURRENT_PATH"/include.sh


function busybox_download() {   
    if [[ ! -d $CONFIG_BUSYBOX_DIR_PATH ]]; then
        cd "$CONFIG_SOURCE_DIR_PATH"
        
        local VERSION="${CONFIG_BUSYBOX_DIR_PATH##*/}"
        wget https://busybox.net/downloads/$VERSION.tar.bz2  
        tar jxvf $VERSION.tar.bz2
        rm -rf $VERSION.tar.bz2       
    fi
}


function busybox_build() {
    cd "$CONFIG_BUSYBOX_DIR_PATH"
    make distclean   

    local CROSS_COMPILE="$CONFIG_ARCH_CROSS_COMPILE" 
   
    if [[ -e "$CONFIG_CONFIGURATION_DIR_PATH/busybox.config" ]]; then
        cp "$CONFIG_CONFIGURATION_DIR_PATH/busybox.config" .config
        echo include existing busybox config
    else
        make CROSS_COMPILE=$CROSS_COMPILE defconfig   
    fi    
        
    make CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) 
    make CROSS_COMPILE=$CROSS_COMPILE install CONFIG_PREFIX="$CONFIG_ROOTFS_DIR_PATH"
}


function busybox_create_ramdisk() { 
    [[ $(ls -A "$CONFIG_ROOTFS_DIR_PATH") ]] && echo Create a root filesystem ramdisk || (echo root filesystem does not exist; exit 20)
    
    cd "$CONFIG_ROOTFS_DIR_PATH"        
    find . | cpio -o --format=newc --owner root:root | gzip -9 > "$CONFIG_DEPLOY_DIR_PATH"/rootfs.cpio.gz

    cd "$CONFIG_DEPLOY_DIR_PATH"
    "$CONFIG_UBOOT_DIR_PATH"/tools/mkimage -n 'Ramdisk Image' -A $CONFIG_ARCH_NAME -O linux -T ramdisk -C none -d rootfs.cpio.gz rootfs.cpio.gz.uboot   
 
}


function busybox_create_rootfs() {   
    cd "$CONFIG_ROOTFS_DIR_PATH"
    
    mkdir bin sbin lib etc dev sys proc tmp var opt mnt usr home root media run
    mkdir -p etc/{rc.d,init.d}
    mkdir -p usr/{bin,lib,sbin}   
    mkdir -p var/{log,run}
    ln -s lib lib64
    touch etc/{inittab,fstab,profile,hostname,passwd,group,shadow,resolv.conf,mdev.conf,inetd.conf,init.d/rcS}
    chmod +x etc/init.d/rcS

    (
        echo ::sysinit:/etc/init.d/rcS        
        echo ::respawn:/sbin/getty -L console 0 vt100
        #echo ::askfirst:-/bin/sh
        echo ::ctrlaltdel:-/sbin/reboot
        echo ::shutdown:/bin/umount -a -r
        echo ::restart:/sbin/init
    ) > etc/inittab

    (
        echo "#!/bin/sh"       
        echo /bin/mount -a  
        echo mkdir /dev/pts
        echo /bin/mount -t devpts devpts /dev/pts
        echo "echo /sbin/mdev > /proc/sys/kernel/hotplug"
        echo /sbin/mdev -s    
        echo /bin/hostname -F /etc/hostname        
        echo ifconfig lo 172.0.0.1
        echo ifconfig eth0 ${CONFIG_NET_TARGET_IP_LIST[0]}
        echo '$(dirname $(realpath $0))/dropbear start'
    ) > etc/init.d/rcS

    (
        echo proc      /proc     proc        defaults 0 0
        echo sysfs     /sys      sysfs       defaults 0 0
        echo tmpfs     /var      tmpfs       defaults 0 0
        echo tmpfs     /tmp      tmpfs       defaults 0 0
        echo devtmpfs  /dev      devtmpfs    defaults 0 0       
    ) > etc/fstab

    (
        echo root:uG4dKmW8HPJqY:0:0:root:/root:/bin/sh    # password 1234 
       
    ) > etc/passwd

    echo target  > etc/hostname

    (
        echo "#!/bin/sh"
        echo umask 022       
        echo PS1=\"[\\u@\\h \\w]\\$ \"
        echo PATH=/bin:/sbin:/usr/bin:/usr/sbin
        echo LD_LIBRARY_PATH=/lib:/usr/lib:\$LD_LIBRARY_PATH
        echo export PATH LD_LIBRARY_PATH PS1
    ) > etc/profile

    echo /lib > etc/ld.so.conf

    sync

    #readelf -a bin/busybox | grep -E "(program interpreter)|(Shared library)"
    local SYSROOT=$(${CONFIG_ARCH_CROSS_COMPILE}gcc -print-sysroot)
    sudo cp -L "$SYSROOT"/lib/*.so* lib
    sudo ${CONFIG_ARCH_CROSS_COMPILE}strip lib/*.so*
    ldconfig -r .    

    sudo mknod -m 666 dev/null c 1 3
    sudo mknod -m 600 dev/console c 5 1    
    
}



function busybox_postprocess() {
    busybox_create_rootfs  
    # bash "$CURRENT_PATH"/ssh.sh download
    # bash "$CURRENT_PATH"/ssh.sh build
    bash "$CURRENT_PATH"/ssh.sh postprocess
    
}


case $1 in
    all)
        busybox_download
        busybox_build
        busybox_postprocess
        ;;

    download)
        busybox_download
        ;;

    build)
        busybox_build
        ;; 
   
    postprocess)
        busybox_postprocess
        ;;

    ramdisk)
        busybox_create_ramdisk
        ;;

    *) 
        echo unknown busybox parameter 
        exit 20
        ;;
esac


cd "$ORIGIN_PATH"