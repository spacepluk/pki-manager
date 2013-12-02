#!/bin/bash

#
# Helper script for revoking ca CA or Cert
#

# Specific script vars
SCRIPT=$0

source ./etc/vars

main() {
    if [[ ! $CERT && ! $i -eq 1 ]] || [[ ! $NAME ]] || [[ ! $j -eq 1 ]] || [[ ! $INTERMEDIATECA && ! $SIGNINGCA && ! $UNIT ]];
    then
        help
        exit 1
    fi

    if [ $INTERMEDIATECA ];
    then
        CFG=$CFGDIR/$SIGNCA$CFGEXT
        CA=$NAME$INTERMEDIATEEXT
        CRTFILE=$DIR/$CADIR/$CA/$CA$CRTEXT
        export ROOTCANAME=$SIGNCA$ROOTCAEXT
        DELFILES="$DIR/$CADIR/$CA $DIR/$PUBDIR/$CA.* $DIR/$PUBDIR/$CA$CACHAINEXT$PKCS7EXT"
    elif [ $SIGNINGCA ];
    then
        CFG=$CFGDIR/$SIGNCA/$SIGNCA$CFGEXT
        CRTFILE=$DIR/$CADIR/$NAME/$NAME$CRTEXT
        export INTERMEDIATECANAME=$SIGNCA$INTERMEDIATEEXT
        DELFILES="$DIR/$CADIR/$NAME $DIR/$PUBDIR/$NAME.* $DIR/$PUBDIR/$NAME$CACHAINEXT$PKCS7EXT"
    else
        CFG=$CFGDIR/$UNIT/$SIGNCA$CFGEXT
        CRTFILE=$CERTSDIR/$NAME$CRTEXT
        export CANME=$SIGNCA
        DELFILES="$DIR/$CERTS/$NAME.*"
    fi

    # Check if reasin RFC conform. If not set set to "superseded
    if [ $REASON ];
    then
        if [ ! $REASON == "keyCompromise" ] || \
           [ ! $REASON == "CACompromise" ] || \
           [ ! $REASON == "affiliationChanged" ] || \
           [ ! $REASON == "cessationOfOperation" ] || \
           [ ! $REASON == "certificateHold" ] || \
           [ ! $REASON == "removeFromCRL" ] || \
           [ ! $REASON == "unspecified" ];
        then
            help
            exit 1
        fi
    else
        REASON="superseded"
    fi

    revoke
    delete
}

revoke() { 
    echo "Revoking $NAME using $CFG"

    openssl ca \
        -config $CFG \
        -revoke $CRTFILE \
        -crl_reason $REASON
    check $?
}

delete() {
    echo "Deleting $NAME and all files"

    rm -fr $DELFILES
    check $?
}

check() {
    if [ "$1" -gt 0 ];
    then
        echo "ERROR!"
        echo "\nReturned value is $1"
        exit 1
    fi
}

help() {
    echo "
        $SCRIPT [ARGS] NAME
        
        Script for revoking a certificate

        NAME                    Name of the certificate
        -h, --help              Displays this text
        --cert                  Revoke a certificate
        --intermediate-ca       Revoke a intermediate CA
        -r, --reason            Revoke reason, must be RFC comform
        --signing-ca            Revoke a signing CA
        --signed-with           Name of CA the to revoked CA has been signed
        --unit                  Unit certificate belongs to
        "
}

i=0
j=0
while :
do
    case $1 in
        -h | --help)
            help
            exit 0
            ;;
        --cert)
            CERT="true"
            i=$(($i + 1))
            shift
            ;;
        --intermediate-ca)
            INTERMEDIATECA="true"
            i=$(($i + 1))
            shift
            ;;
        -r | --reason)
            REASON=$2
            shift 2
            ;;
        --reason=*)
            REASON="${1#*=}"
            shift
            ;;
        --signing-ca)
            SIGNINGCA="true"
            i=$(($i + 1))
            shift
            ;;
        --signed-with)
            SIGNCA=$2
            shift 2
            j=$(($j + 1))
            ;;
        --signed-with=*)
            SIGNCA=${1#*=}
            shift
            j=$(($j + 1))
            ;;
        --unit)
            UNIT=$2
            shift 2
            ;;
        --unit=*)
            UNIT=${1#*=}
            shift
            ;;
        *)
            NAME=$1
            main
            exit 0
            ;;
    esac
done
