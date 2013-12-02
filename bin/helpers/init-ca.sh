#!/bin/bash

#
# Helper script for initializing a new CA
# Builds the complete folder structure
#

# Script vars
SCRIPT=`basename $0`

source ./etc/vars

main() {
    if [ ! $CA ];
    then
        help
        exit 1
    fi

    echo "Init new CA $CA"

    CADIR="$CADIR/$CA"
    CAPRIVDIR="$CADIR/$PRIVATEDIR"
    CADBDIR="$CADIR/$DBDIR"

    CADB="$CADBDIR/$CA$DBEXT"
    CADBATTR="$CADBDIR/$CA$ATTREXT"

    SERIAL="$CADBDIR/$CA$SERIALEXT"
    CRLNUM="$CADBDIR/$CA$CRLNUMBEREXT"

    # create directorys
    mkdir -p $CAPRIVDIR $CADBDIR $CRLDIR $CERTSDIR $PUBDIR
    chmod 700 $CAPRIVDIR

    # create database
    echo "Creating databases"

    touch $CADB
    touch $CADBATTR
    echo 01 > $SERIAL
    echo 01 > $CRLNUM

    echo "done"
}

help() {
    echo "
        Usage: $SCRIPT CA
        
        Builds the folder structure for the CA

        CA                      Name of the CA
        -h, --help              Shows up this help
        "
}

while :
do
    case $1 in
        -h | --help)
            help
            exit 0
            ;;
        *)
            CA="$1"
            main
            exit 0
            ;;
    esac
done
