#!/bin/bash

export USERNAME=${USERNAME:=$(whoami)}

# for docker
sudo yum-config-manager --enable rhui-REGION-rhel-server-extras

# for python2-pip, zile
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum update -y
sudo yum install -y git nano wget zip zile gettext net-tools libffi-devel docker \
                    python-cryptography python-passlib python-devel python-pip pyOpenSSL.x86_64 \
                    openssl-devel httpd-tools java-1.8.0-openjdk-headless NetworkManager \
                    "@Development Tools"

sudo systemctl | grep "NetworkManager.*running"
if [ $? -eq 1 ]; then
    sudo systemctl start NetworkManager
    sudo systemctl enable NetworkManager
fi

sudo systemctl start docker
sudo systemctl enable docker

if [ "${USERNAME}" != "root" ]; then
  sudo groupadd docker
  sudo usermod -aG docker ${USERNAME}
fi
