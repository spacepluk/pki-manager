#!/bin/bash

#
# Wrapper script for generating a new certificate
#

# Script vars
SCRIPT=`basename $0`


source ./etc/vars

main() {

    if [[ ! $NAME || ! $i -eq 1 || ! $y -eq 2 ]];
    then
        help
        exit 1
    fi

    export CANAME=$SIGNCA
    CACFG=$CFGDIR/$UNIT/$SIGNCA$CFGEXT
    if [ $CLIENT ];
    then
        CFG=$CLIENTCFG
        MODE="--client"
    elif [ $OCSP ];
    then
        CFG=$OCSPCFG
        MODE="--ocsp"
    elif [ $SERVER ];
    then
        CFG=$SERVERCFG
        MODE="--server"
    elif [ $TIMESTAMP ];
    then
        CFG=$TIMESTAMPCFG
        MODE="--timestamp"
    fi

    if [[ ! $SERVER && $DN ]];
    then
        DN=""
    fi

    request
    sign
}

request() {
    bash $DEBUG ./bin/helpers/request-certificate.sh $DN $ENCRYPTION --cfg $CFG $NAME
    check $?
}

sign() {
    bash $DEBUG ./bin/helpers/signing-certificate.sh $MODE --cfg $CACFG $NAME
    check $?
}

check() {
    if [ $1 -gt 0 ];
    then
        #echo "An error occured"
        #echo "Return code was $1"
        exit 1
    fi
}

help() {
    echo "
        Usage: $SCRIPT [ARGS] NAME
        
        Wrapper script for generating a new certificate
        
        NAME                Name of the new certificate
        --client            Create a TLS client certficate
        --debug             Enable debug mode
        --dn                Additional CNs seperated by coma
        -h, --help          Shows up this help
        --no-password       Don't protect the private key
        --ocsp              Create a OCSP-Signing certificate
        --server            Create a TLS server certificate
        --sign-with         CA to sign with
        --timestamp         Create a timestamp certificate
        --unit              Unit the certificate belongs to
        "
}

i=0
y=0
while :
do
    case $1 in
        --client)
            CLIENT="true"
            shift
            i=$(($i + 1))
            ;;
        --debug)
            set -x
            DEBUG="-x"
            shift
            ;;
        --dn)
            DN="--dn $2"
            shift 2
            ;;
        --dn=*)
            DN="--dn ${1#*}"
            shift
            ;;
        -h|--help)
            help
            exit 0
            ;;
        --no-password)
            ENCRYPTION="--no-password"
            shift
            ;;
        --ocsp)
            OCSP="true"
            shift
            i=$(($i + 1))
            ;;
        --sign-with)
            SIGNCA=$2
            shift 2
            y=$(($y + 1))
            ;;
        --sign-with=*)
            SIGNCA=$1
            shift
            y=$(($y + 1))
            ;;
        --server)
            SERVER="true"
            shift
            i=$(($i + 1))
            ;;
        --timestamp)
            TIMESTAMP="true"
            shift
            i=$(($i + 1))
            ;;
        --unit)
            UNIT=$2
            shift 2
            y=$(($y + 1))
            ;;
        --unit=*)
            UNIT=${1#*=}
            shift
            y=$(($y + 1))
            ;;
        *)
            NAME=$1
            main
            exit 0
            ;;
    esac
done
