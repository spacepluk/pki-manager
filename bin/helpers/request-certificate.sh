#!/bin/bash

#
# Helper script for creating a certificate signing request
#

# Script vars
SCRIPT=`basename $0`


source ./etc/vars

main() {
    if [[ ! $CSR || ! $CFG ]];
    then
        help
        exit 1
    fi

    export CN=$CSR

    if [ $CA ];
    then
        # CSR for CA
        CSRFILE=$CADIR/$CSR/$CSR$CSREXT
        KEYFILE=$CADIR/$CSR/$PRIVATEDIR/$CSR$KEYEXT
    else
        # CSR for SSL certs
        CSRFILE=$CERTSDIR/$CSR$CSREXT
        KEYFILE=$CERTSDIR/$CSR$KEYEXT

        if [ $DN ];
        then
            exportSAN
        fi
    fi

    createCSR
}

exportSAN() {
    IFS=","
    for d in $DN
    do
        echo "Adding FQDN $d"
        if [ ! $SAN ];
        then
            SAN="DNS:$d"
        else
            SAN="$SAN,DNS:$d"
        fi
    done

    export SAN=$SAN
}

createCSR() {
    echo "Create csr for $CSR"

    openssl req -new \
        $ENCRYPTION \
        -config $CFG \
        -out $CSRFILE \
        -keyout $KEYFILE
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
        Usage: $SCRIPT [ARGS] CSR

        Helper script for creating a certificate signing request
        
        CSR                 Name of the csr file
        --ca                Use this option if you want to create a csr for a CA
        --cfg               Specify a config file
        --dn                When creating a TLS server cert specify here more domain names speerate by coma
        -h, --help          Shows up this help
        --no-password       Don't protect the private key
        "
}

while :
do
    case $1 in
        --ca)
            CA="true"
            shift
            ;;
        --cfg)
            CFG=$2
            shift 2
            ;;
        --cfg=*)
            CFG=${1#*=}
            shift
            ;;
         --dn)
            DN=$2
            shift 2
            ;;
        --dn=*)
            DN=${1#*=}
            shift
            ;;
        -h|--help)
            help
            exit 0
            ;;
        --no-password)
            ENCRYPTION="-nodes"
            shift
            ;;
        *)
            CSR=$1
            main
            exit 0
            ;;
    esac
done
