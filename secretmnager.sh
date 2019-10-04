#! /bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SECRETFILE=$BASEDIR/.SECRET
SSH_PUB_KEY_FILE=$HOME/.ssh/id_rsa.pub
SSH_PRIV_KEY_FILE=$HOME/.ssh/id_rsa

########################################

if [[ ! -r $SSH_PUB_KEY_FILE ]]; then
    echo "ssh pub key file $SSH_PUB_KEY_FILE does not exist"
    exit 1
fi
if [[ ! -r $SSH_PRIV_KEY_FILE ]]; then
    echo "ssh key file $SSH_PRIV_KEY_FILE does not exist"
    exit 1
fi

SSH_PUB_KEY=$(ssh-keygen -e -f $SSH_PUB_KEY_FILE -m PKCS8)

if [[ ! -r $SECRETFILE ]]; then
    echo "No .SECRET file found. Going to create $SECRETFILE"
    SYM_KEY=$(openssl rand 32 | base64 -w0)
    openssl rsautl -encrypt -oaep -pubin -inkey <(echo -n "$SSH_PUB_KEY") -in <(echo -n "$SYM_KEY") | base64 -w0 > $SECRETFILE
fi

SYM_KEY_ENC=$(cat $SECRETFILE)

SYM_KEY=$(openssl rsautl -decrypt -oaep -inkey $SSH_PRIV_KEY_FILE -in <(echo -n $SYM_KEY_ENC | base64 -d) > /dev/null 2>&1)
if [[ $? != 0 ]]; then
     echo "Error while decrypting encryption key"
     exit 1
fi


TOENCRYPT="This is a test"

OUT=$(echo $SYM_KEY | openssl aes-256-cbc -e -in <(echo -n $TOENCRYPT) -pass stdin -pbkdf2)
if [[ $? != 0 ]]; then
     echo "Could not encrypt data"
     exit 1
fi
