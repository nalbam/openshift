#!/bin/bash

curl -s -o ~/.ssh/config https://gitlab.com/nalbam/openshift/raw/master/config

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -q -f ~/.ssh/id_rsa -N ""
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi
