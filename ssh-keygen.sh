#!/bin/bash

export USERNAME=${USERNAME:=$(whoami)}

export IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

if [ ! -f ~/.ssh/config ]; then
  echo "Host * " >> ~/.ssh/config
  echo "    StrictHostKeyChecking no " >> ~/.ssh/config
fi

if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -q -f ~/.ssh/id_rsa -N ""
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

ssh -o StrictHostKeyChecking=no ${USERNAME}@${IP} "pwd" < /dev/null
