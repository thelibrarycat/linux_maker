#!/bin/bash

CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


STATUS="$(systemctl is-active nfs-kernel-server.service)"
if [[ $STATUS != active ]]; then
    sudo apt install nfs-kernel-server 

    # <path_to_rootfs_directory> <ip_address_of_board>(rw,no_root_squash,no_subtree_check)
    echo  "$CONFIG_ROOTFS_DIR_PATH ${CONFIG_NET_TARGET_IP_LIST[0]}/$CONFIG_NET_MASK(rw,no_root_squash,no_subtree_check)" >> /etc/exports
    
    sudo systemctl restart nfs-kernel-server        
fi

echo NFS has been established


 
 



 




 
 
 
 

