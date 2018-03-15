#!/bin/bash

export USERNAME=${USERNAME:=$(whoami)}
export IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

curl -s -o ~/.ssh/config https://gitlab.com/nalbam/openshift/raw/master/config

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -q -f ~/.ssh/id_rsa -N ""

    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

    ssh -o StrictHostKeyChecking=no ${USERNAME}@${IP} "pwd" < /dev/null
fi
