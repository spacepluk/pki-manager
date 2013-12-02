#!/bin/bash

#
# Wrapper script to go every step through for building a CA
#

# Script vars
SCRIPT=`basename $0`


source ./etc/vars

main() {
    if [[ ! $CA || ! $i -eq 1 ]] || [[ $INTERMEDIATECA && ! $SIGNCA ]] || [[ $SIGNINGCA && ! $SIGNCA ]];
    then
        help
        exit 1
    fi

    if [ $ROOTCA ];
    then
        CFG="$CFGDIR/$CA$CFGEXT"
        CA="$CA$ROOTCAEXT"
        CANAME="$ROOTCAEXT"
        SCRIPTARG="--root-ca"
        TOPCFG=$CFG
    elif [ $INTERMEDIATECA ];
    then
        CFG="$CFGDIR/$CA/$CA$CFGEXT"
        CA="$CA$INTERMEDIATEEXT"
        TOPCA="$SIGNCA$ROOTCAEXT"
        TOPCFG="$CFGDIR/$SIGNCA$CFGEXT"
        CANAME="$INTERMEDIATEEXT"
        SCRIPTARG="--intermediate-ca"
    elif [ $SIGNINGCA ];
    then
        CFG="$CFGDIR/$SIGNCA/$CA$CFGEXT"
        TOPCFG="$CFGDIR/$SIGNCA/$SIGNCA$CFGEXT"
        TOPCA="$SIGNCA$INTERMEDIATEEXT"
        SCRIPTARG="--signing-ca"

        if [ $SIGNCA == $CA ];
        then
            echo "Conflict! Signing CA has the same name as the unit"
            exit 1
        fi
    fi

    export CANAME=$(echo $(basename $CFG) | \
                        awk -F "." -v name="$CANAME" '{print $1name}')
    if [ $SIGNCA ];
    then
        CACHAIN="true"
        CRT=$DIR/$CADIR/$CA/$CA$CRTEXT
        if [ $INTERMEDIATECA ];
        then
            export ROOTCANAME=$TOPCA
            export INTERMEDIATECANAME=$CANAME
            TOP=$DIR/$CADIR/$TOPCA/$TOPCA$CRTEXT
        else
            export INTERMEDIATECANAME=$TOPCA
            CACHAIN=$DIR/$CADIR/$TOPCA/$TOPCA$CACHAINEXT$PEMEXT
            TOP=$CACHAIN
        fi
    else
        export ROOTCANAME=$CANAME
        CRT=$DIR/$CADIR/$CA/$CANAME$CRTEXT
    fi

    #read -p ".."

    init
    request
    sign
    init_crl
    if [ $CACHAIN ];
    then
        create_ca_chain
    fi
}

init() {
    bash $DEBUG ./bin/helpers/init-ca.sh $CA
    check $?
}

request() {
    bash $DEBUG ./bin/helpers/request-certificate.sh $ENCRYPTION --ca --cfg $CFG $CA
    check $?
}

sign() {
    bash $DEBUG ./bin/helpers/signing-certificate.sh $SCRIPTARG --cfg $TOPCFG $CA
    check $?
}

init_crl() {
    bash $DEBUG ./bin/helpers/create-crl.sh $CFG $CA
    check $?
}

create_ca_chain() {
    bash $DEBUG ./bin/helpers/create-ca-chain.sh $TOP $CRT
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
        Usage: $SCRIPT [ARGS] CA
        
        Wrapper script to go every step through for building a CA

        CA                  Name of the new CA
        -d, --debug         Enable bash debug mode
        -h, --help          Shows up this help
        --intermediate-ca   Build an intermediate ca
        --no-password       Don't protect the private key
        --root-ca           Build a root ca
        --signing-ca        Build a signing ca
        --sign-with         CA used to sign the new CA
        "
}

i=0
while :
do
    case $1 in
        -d|--debug)
            set -x
            DEBUG="-x"
            shift 1
            ;;
        -h|--help)
            help
            exit 0
            ;;
        --intermediate-ca)
            INTERMEDIATECA="true"
            i=$(($i + 1))
            shift
            ;;
        --no-password)
            ENCRYPTION="--no-password"
            shift
            ;;
        --root-ca)
            ROOTCA="true"
            i=$(($i + 1))
            shift
            ;;
        --signing-ca)
            SIGNINGCA="true"
            i=$(($i + 1))
            shift
            ;;
        --sign-with)
            SIGNCA=$2
            shift 2
            ;;
        --sign-with=*)
            SIGNCA=${1#*=}
            shift
            ;;
        *)
            CA=$1
            main
            exit 0
            ;;
    esac
done
