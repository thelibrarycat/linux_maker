#!/bin/bash

CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


function bridge_release_switch() {
    local TAP_NAMES="$CONFIG_NET_TAP_NAME_LIST"
    local ETH_NAME="$CONFIG_NET_ETHERNET_NAME"
    local BRIDGE_NAME="$CONFIG_NET_BRIDGE_NAME"

    #tap
    for NAME in ${TAP_NAMES[*]}
    do     
        sudo ip link set dev $NAME down         
        sudo ip link set dev $NAME nomaster
        sudo ip tuntap del dev $NAME mod tap     
    done 

    #eth    
    sudo ip link set dev $ETH_NAME down
    sudo ip link set dev $ETH_NAME nomaster
    sudo ip link set up dev $ETH_NAME

    #bridge
    sudo ip link set down dev $BRIDGE_NAME
    sudo ip link del dev $BRIDGE_NAME  
    
    #sudo dhclient -v $ETH_NAME
}


function bridge_establish_switch() {
    local TAP_NAMES="$CONFIG_NET_TAP_NAME_LIST"
    local ETH_NAME="$CONFIG_NET_ETHERNET_NAME"
    local BRIDGE_NAME="$CONFIG_NET_BRIDGE_NAME"
    local BRIDGE_IP="$CONFIG_NET_BRIDGE_IP"

    #bridge
    sudo ip link add name $BRIDGE_NAME type bridge    
    sudo ip addr add $BRIDGE_IP dev $BRIDGE_NAME
    sudo ip link set dev $BRIDGE_NAME up

    #eth
    sudo ip addr flush dev $ETH_NAME
    sudo ip link set $ETH_NAME master $BRIDGE_NAME
    sudo ip link set up dev $ETH_NAME
    
    #tap
    for NAME in ${TAP_NAMES[*]}             
    do       
        sudo ip tuntap add dev $NAME mode tap           
        sudo ip link set dev $NAME master $BRIDGE_NAME
        sudo ip link set dev $NAME up
    done

    #dmesg | grep $ETH_NAME
    #ip -details -pretty -json link show type bridge
    #ip link show master $BRIDGE_NAME
    #sudo bridge link
}

    
STATUS="$(ip link show | awk -F': ' '{print $2}' | grep "\<$CONFIG_NET_BRIDGE_NAME\>")"
if [[ -n $STATUS ]]; then   
    bridge_release_switch
    echo Bridge has been clear up
else
    bridge_establish_switch   
    echo Bridge has been established
fi
    
    