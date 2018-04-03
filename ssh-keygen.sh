#!/bin/bash

export USER=${USER:=$(whoami)}

export IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -q -f ~/.ssh/id_rsa -N ""
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

if [ ! -f ~/.ssh/config ]; then
  echo "Host * " >> ~/.ssh/config
  echo "    StrictHostKeyChecking no " >> ~/.ssh/config
fi

chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

ssh -o StrictHostKeyChecking=no ${USER}@${IP} "pwd" < /dev/null
