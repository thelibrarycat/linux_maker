#!/bin/bash

UTILITY_FUNCTIONS="Defined"


function modify_config_with_string() {
    echo $1 = $2
    local REPLACE="\"$2\""
    REPLACE=${REPLACE//'/'/'\/'}   
    $4 sed -i "/$1/s/=.*/=$REPLACE/" "$3"
}


