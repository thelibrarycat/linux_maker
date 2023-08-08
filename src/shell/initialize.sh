#!/bin/bash

ORIGIN_PATH=$(pwd)
CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh



function initialize_create_dependent_folder() {
    mkdir -p "$CONFIG_SOURCE_DIR_PATH"/{linux,packages}
    mkdir -p "$CONFIG_DEVELOP_DIR_PATH"/{config,firmware}
    mkdir -p "$CONFIG_BOOTFS_DIR_PATH"
    mkdir -p "$CONFIG_ROOTFS_DIR_PATH"
}



function initialize_clear_deploy_folder() {
    cd "$CONFIG_DEPLOY_DIR_PATH"
    find . -maxdepth 1 -type f -exec echo delete {} \; -exec rm {} \;
}


function initialize_clear_bootfs_folder() {
    rm -rf "$CONFIG_BOOTFS_DIR_PATH"/*
}


function initialize_clear_rootfs_folder() {
    sudo rm -rf "$CONFIG_ROOTFS_DIR_PATH"/*
}




case $1 in
    create_dependent_folder)
        initialize_create_dependent_folder
        ;;
        
    clear_deploy_folder)
        initialize_clear_deploy_folder
        ;;

    clear_bootfs_folder)
        initialize_clear_bootfs_folder
        ;;

    clear_rootfs_folder)
        initialize_clear_rootfs_folder
        ;;
        
    *) 
        echo unknown raspberry-pi-3b parameter 
        exit 20
        ;;
esac





cd "$ORIGIN_PATH"

