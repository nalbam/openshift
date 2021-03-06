#!/bin/bash

export USER=${USER:=$(whoami)}

# Private IP
export IP="$(ip route get 1.1.1.1 | awk '{print $NF; exit}')"

export DOMAIN=${DOMAIN:="$(curl -s ipinfo.io/ip).nip.io"}
export USERNAME=${USERNAME:="admin"}
export PASSWORD=${PASSWORD:="password"}
export VERSION=${VERSION:="v3.7.2"}
export BRANCH=${BRANCH:="release-3.7"}
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
    yum update -y

    # for docker (rhel)
    yum-config-manager --enable rhui-REGION-rhel-server-extras

    yum repolist | grep epel
    if [ $? -eq 1 ]; then
        rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

        # for pip, zile
        yum-config-manager --enable epel

        # for ansible-2.5.0
        yum-config-manager --enable epel-testing
    fi

    yum install -y git wget zip zile docker ansible gettext net-tools libffi-devel httpd-tools \
                   python-cryptography python-passlib python-devel python-pip pyOpenSSL.x86_64 \
                   openssl-devel java-1.8.0-openjdk-headless \
                   NetworkManager "@Development Tools"
}

install_ansible() {
    which ansible || pip install -Iv ansible

    [ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

    pushd openshift-ansible
    git fetch && git checkout ${BRANCH}
    popd
}

install_openshift() {
    ansible-playbook -i inventory.ini openshift-ansible/playbooks/byo/config.yml -vvv

    htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}

    oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

    systemctl restart origin-master-api
}

start_service() {
    systemctl | grep "NetworkManager.*running"
    if [ $? -eq 1 ]; then
        systemctl start NetworkManager
        systemctl enable NetworkManager
    fi

    if [ -z ${DISK} ]; then
        echo "Not setting the Docker storage."
    else
        cp /etc/sysconfig/docker-storage-setup /etc/sysconfig/docker-storage-setup.bk

        echo DEVS=${DISK} > /etc/sysconfig/docker-storage-setup
        echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
        echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
        echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

        systemctl stop docker

        rm -rf /var/lib/docker
        wipefs --all ${DISK}
        docker-storage-setup
    fi

    if [ "${USER}" != "root" ]; then
      groupadd docker
      usermod -aG docker ${USER}
    fi

    systemctl restart docker
    systemctl enable docker
}

build_ssh() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        curl -s https://raw.githubusercontent.com/nalbam/openshift/master/bin/ssh-keygen.sh | bash

        if [ "${USER}" != "root" ]; then
            if [ ! -f /tmp/authorized_keys ]; then
                mkdir -p /root/.aws
                mkdir -p /root/.ssh

                cp -rf ~/.ssh/config /root/.ssh/config
                cp -rf ~/.ssh/id_rsa /root/.ssh/id_rsa
                cp -rf ~/.ssh/id_rsa.pub  /root/.ssh/id_rsa.pub

                cat /root/.ssh/authorized_keys > /tmp/authorized_keys
                cat /root/.ssh/id_rsa.pub >> /tmp/authorized_keys

                cp -rf /tmp/authorized_keys /root/.ssh/authorized_keys

                chmod 700 /root/.ssh
                chmod 600 /root/.ssh/authorized_keys
                chmod 600 /root/.ssh/id_rsa
            fi
        fi
    fi
}

build_hosts() {
    curl -s -o /tmp/hosts.tmp https://raw.githubusercontent.com/nalbam/openshift/master/bin/hosts
    envsubst < /tmp/hosts.tmp > /tmp/hosts
    cp -rf /tmp/hosts /etc/hosts
}

build_inventory() {
    curl -s -o /tmp/inventory.tmp https://raw.githubusercontent.com/nalbam/openshift/master/bin/inventory
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

build_hosts

build_ssh

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
