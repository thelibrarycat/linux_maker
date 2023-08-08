#!/bin/bash

CURRENT_PATH=$(dirname $(realpath $0))

if [[ -z $CONFIG_VARIABLE ]]; then
   . "$CURRENT_PATH"/env.cfg
fi


if [[ -z $UTILITY_FUNCTIONS ]]; then
   . "$CURRENT_PATH"/func.sh
fi
