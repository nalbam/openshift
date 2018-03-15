#!/bin/bash

export DOMAIN=${DOMAIN:="$(curl -s ipinfo.io/ip).nip.io"}
export USERNAME=${USERNAME:=$(whoami)}
export PASSWORD=${PASSWORD:=password}
export VERSION=${VERSION:="v3.7.1"}
export DISK=${DISK:=""}

export IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

export METRICS="True"
export LOGGING="True"

MEMORY=$(cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:[ ]*\([0-9]*\) kB/\1/")

if [ "$MEMORY" -lt "4194304" ]; then
    export METRICS="False"
fi

if [ "$MEMORY" -lt "8388608" ]; then
    export LOGGING="False"
fi

install_dependency() {
    sudo yum repolist | grep rhui-REGION-rhel-server-extras
    if [ $? -eq 1 ]; then
      # for docker
      sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
    fi

    sudo yum repolist | grep epel
    if [ $? -eq 1 ]; then
      # for python2-pip, zile
      sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi

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
}

install_ansible() {
    which ansible || sudo pip install -Iv ansible

    [ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

    pushd openshift-ansible
    git fetch && git checkout release-3.7
    popd
}

install_openshift() {
    sudo ansible-playbook -i inventory.ini openshift-ansible/playbooks/byo/config.yml

    sudo htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}

    oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

    sudo systemctl restart origin-master-api
}

start_docker() {
    if [ -z ${DISK} ]; then
        echo "Not setting the Docker storage."
    else
        sudo cp /etc/sysconfig/docker-storage-setup /etc/sysconfig/docker-storage-setup.bk

        sudo echo DEVS=${DISK} > /etc/sysconfig/docker-storage-setup
        sudo echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
        sudo echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
        sudo echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

        sudo systemctl stop docker

        sudo rm -rf /var/lib/docker
        sudo wipefs --all ${DISK}
        sudo docker-storage-setup
    fi

    if [ "${USERNAME}" != "root" ]; then
      sudo groupadd docker
      sudo usermod -aG docker ${USERNAME}
    fi

    sudo systemctl restart docker
    sudo systemctl enable docker
}

build_ssh() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        curl -s https://gitlab.com/nalbam/openshift/raw/master/ssh-keygen.sh | sudo bash

        if [ "${USERNAME}" != "root" ]; then
          sudo cp -rf /root/.ssh/config ~/.ssh/config
          sudo cp -rf /root/.ssh/id_rsa ~/.ssh/id_rsa
          sudo cp -rf /root/.ssh/id_rsa.pub ~/.ssh/id_rsa.pub

          sudo chown ${USERNAME}.${USERNAME} ~/.ssh/*

          cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        fi
    fi
}

build_hosts() {
    curl -s -o /tmp/hosts.tmp https://gitlab.com/nalbam/openshift/raw/master/hosts
    envsubst < /tmp/hosts.tmp > /tmp/hosts
    sudo cp -rf /tmp/hosts /etc/hosts
}

build_inventory() {
    curl -s -o /tmp/inventory https://gitlab.com/nalbam/openshift/raw/master/inventory
    envsubst < /tmp/inventory > inventory.ini

    if [ ! -f inventory.ini ]; then
        echo "inventory.ini is missing!"
        exit 1
    fi
}

echo "**********"
echo "* Your domain is $DOMAIN "
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* OpenShift version: $VERSION "
echo "**********"

install_dependency

install_ansible

build_ssh

build_hosts

build_inventory

start_docker

install_openshift

echo "**********"
echo "* Your console is https://console.$DOMAIN:8443/"
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* OpenShift version: $VERSION "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/"
echo "**********"

oc login -u ${USERNAME} -p ${PASSWORD} https://console.${DOMAIN}:8443/
