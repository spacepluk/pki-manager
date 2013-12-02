#!/bin/bash

#
# Helper script to generate a crl from given config file
#

# Script vars
SCRIPT=`basename $0`


source ./etc/vars

main() {
    CRLFILE="$DIR/$CRLDIR/$CA$CRLEXT"
    PUBCRLFILE="$DIR/$PUBDIR/$CA$CRLEXT"

    gen
    export_der
}

gen() {
    echo "Init crl file"

    openssl ca -gencrl \
        -config $CFG \
        -out $CRLFILE
    check $?
}

export_der() {
    echo "Export crl into public format der"

    openssl crl \
        -in $CRLFILE \
        -out $PUBCRLFILE \
        -outform der
    check $?
}

check() {
    if [ $1 -gt 0 ];
    then
        echo "An error occured"
        echo "Return code was $1"
        exit 1
    fi
}

help() {
    echo "
        Usage: $SCRIPT [ARGS] CFG CA
        
        Helper script to generate a crl from given config file
        
        CFG                 Path to config file
        CA                  Name of the CA
        -h, --help          Shows up this help
        "
}

while :
do
    case $1 in
        -h|--help)
            help
            exit 0
            ;;
        *)
            CFG=$1
            CA=$2
            main
            exit 0
            ;;
    esac
done
