#!/bin/bash

CURRENT_PATH=$(dirname $(realpath $0))

. "$CURRENT_PATH"/include.sh


STATUS="$(systemctl is-active tftpd-hpa.service)"
if [[ $STATUS != active ]]; then
    sudo apt install tftpd-hpa
    modify_config_with_string TFTP_DIRECTORY "$CONFIG_DEPLOY_DIR_PATH" /etc/default/tftpd-hpa sudo
    sudo systemctl restart tftpd-hpa
fi

echo TFTP has been established






