#!/biin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


if [[ ! -d $CONFIG_GDB_DIR_PATH ]]; then
    cd "$CONFIG_SOURCE_DIR_PATH"
    
    VERSION="${CONFIG_GDB_DIR_PATH##*/}"
    wget https://ftp.gnu.org/gnu/gdb/$VERSION.tar.gz
    tar zxvf  $VERSION.tar.gz
    rm -rf $VERSION.tar.gz   
    
    cd "$CONFIG_GDB_DIR_PATH"
    rm -rf build-gdb build-gdbserver 
    mkdir build-gdb build-gdbserver     

    cd "$CONFIG_GDB_DIR_PATH"/build-gdb
    ../configure --prefix="$CONFIG_TOOLS_DIR_PATH"/$VERSION  --target=$CONFIG_ARCH_PRE_DEFCONFIG        
    make all-gdb -j$(nproc)
    make install-gdb
   
    cd "$CONFIG_GDB_DIR_PATH"/build-gdbserver    
    PATH=$PATH:"${CONFIG_ARCH_CROSS_COMPILE%/*}"   
    ../configure --prefix="$CONFIG_ROOTFS_DIR_PATH" --host=$CONFIG_ARCH_PRE_DEFCONFIG    
    make all-gdbserver -j$(nproc) 
    make install-gdbserver
    
    echo "export PATH=\"$CONFIG_TOOLS_DIR_PATH\"/$VERSION/bin:\$PATH" >> ~/.bashrc    
    source ~/.bashrc
 
fi




# aarch64-rpi3-linux-gnu-gdb -q
# target remote localhost:1234




cd "$ORIGIN_PATH"


