#!/bin/bash

#
# Helper script for signing a certificate
#

# Script vars
SCRIPT=`basename $0`


source ./etc/vars

main() {
    if [[ ! $CSR || ! $CFG ]] && [ ! $i -eq 1 ];
    then
        help
        exit 1
    fi

    if [[ $SERVER || $CLIENT ]];
    then
        CSRFILE="$DIR/$CERTSDIR/$CSR$CSREXT"
        CRTFILE="$DIR/$CERTSDIR/$CSR$CRTEXT"
        PEMFILE="$DIR/$CERTSDIR/$CSR$PEMEXT"
        KEYFILE="$DIR/$CERTSDIR/$CSR$KEYEXT"
    else
        CSRFILE="$DIR/$CADIR/$CSR/$CSR$CSREXT"
        CRTFILE="$DIR/$CADIR/$CSR/$CSR$CRTEXT"
        PUBFILE="$DIR/$PUBDIR/$CSR$PUBEXT"
        PEMFILE="$DIR/$CADIR/$CSR/$CSR$PEMEXT"
        KEYFILE="$DIR/$CADIR/$CSR/$PRIVATEDIR/$CSR$KEYEXT"
    fi

    REQ="ca"
    if [ $ROOTCA ];
    then
        REQ="$REQ -selfsign"
        EXTENSION="root_ca_ext"
    elif [ $INTERMEDIATECA ];
    then
        EXTENSION="intermediate_ca_ext"
    elif [ $SIGNINGCA ];
    then
        EXTENSION="signing_ca_ext"
    elif [ $SERVER ];
    then
        EXTENSION="server_ext"
    elif [ $CLIENT ];
    then
        EXTENSION="client_ext"
    elif [ $OCSP ];
    then
        EXTENSION="ocspsign_ext"
    elif [ $TIMESTAMP ];
    then
        EXTENSION="timestamp_ext"
    fi

    sign
    if [[ ! $SERVER && ! $CLIENT ]];
    then
        export_der
    fi
    create_pem
}

sign() {
    echo "Signing CSR $CSR"

    openssl $REQ \
        -config $CFG \
        -in $CSRFILE \
        -out $CRTFILE \
        -extensions $EXTENSION
    check $?
}

export_der() {
    echo "Export into public format der"

    openssl x509 \
        -in $CRTFILE \
        -out $PUBFILE \
        -outform der
    check $?
}

create_pem() {
    echo "Creating PEM file"

    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' $CRTFILE > $PEMFILE
    cat $KEYFILE >> $PEMFILE
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
        Usage: $SCRIPT CSR

        Helper script for signing a certificate
        
        CSR                 Name of the CSR you want to sign
        --cfg               Sign CSR with this config file
        --client            Sign a client tls certificate
        -h, --help          Shows up this help
        --intermediate-ca   Sign an intermediate ca
        --root-ca           Sign a root ca
        --signing-ca        Sign a signing ca
        --server            Sign a server tls certificate
        "
}

i=0
while :
do
    case $1 in
        --cfg)
            CFG=$2
            shift 2
            ;;
        --cfg=*)
            CFG=${1#*=}
            shift
            ;;
        --client)
            CLIENT="true"
            i=$(($i + 1))
            shift
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
        --server)
            SERVER="true"
            i=$(($i + 1))
            shift
            ;;
        *)
            CSR=$1
            main
            exit 0
            ;;
    esac
done
