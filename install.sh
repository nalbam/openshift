#!/bin/bash

export USER=${USER:=$(whoami)}

export IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

export DOMAIN=${DOMAIN:="${IP}.nip.io"}
export USERNAME=${USERNAME:="${USER}"}
export PASSWORD=${PASSWORD:="password"}
export VERSION=${VERSION:="v3.7.2"}
export DISK=${DISK:=""}

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
      # for docker (rhel)
      sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
    fi

    sudo yum repolist | grep epel
    if [ $? -eq 1 ]; then
      # for pip, zile
      sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi

    sudo yum update -y
    sudo yum install -y git nano wget zip zile gettext net-tools libffi-devel docker \
                        python-cryptography python-passlib python-devel python-pip pyOpenSSL.x86_64 \
                        openssl-devel httpd-tools java-1.8.0-openjdk-headless NetworkManager \
                        "@Development Tools"
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

start_service() {
    sudo systemctl | grep "NetworkManager.*running"
    if [ $? -eq 1 ]; then
        sudo systemctl start NetworkManager
        sudo systemctl enable NetworkManager
    fi

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

    if [ "${USER}" != "root" ]; then
      sudo groupadd docker
      sudo usermod -aG docker ${USER}
    fi

    sudo systemctl restart docker
    sudo systemctl enable docker
}

build_ssh() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        curl -s https://raw.githubusercontent.com/nalbam/openshift/master/ssh-keygen.sh | bash

        if [ "${USER}" != "root" ]; then
            if [ ! -f /tmp/authorized_keys ]; then
                sudo mkdir -p /root/.aws
                sudo mkdir -p /root/.ssh

                sudo cp -rf ~/.ssh/config /root/.ssh/config
                sudo cp -rf ~/.ssh/id_rsa /root/.ssh/id_rsa
                sudo cp -rf ~/.ssh/id_rsa.pub  /root/.ssh/id_rsa.pub

                sudo cat /root/.ssh/authorized_keys > /tmp/authorized_keys
                sudo cat /root/.ssh/id_rsa.pub >> /tmp/authorized_keys

                sudo cp -rf /tmp/authorized_keys /root/.ssh/authorized_keys

                sudo chmod 600 /root/.ssh/authorized_keys
                sudo chmod 600 /root/.ssh/config
            fi
        fi
    fi
}

build_hosts() {
    curl -s -o /tmp/hosts.tmp https://raw.githubusercontent.com/nalbam/openshift/master/hosts
    envsubst < /tmp/hosts.tmp > /tmp/hosts
    sudo cp -rf /tmp/hosts /etc/hosts
}

build_inventory() {
    curl -s -o /tmp/inventory.tmp https://raw.githubusercontent.com/nalbam/openshift/master/inventory
    envsubst < /tmp/inventory.tmp > inventory.ini

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

start_service

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
