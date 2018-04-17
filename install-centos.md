## install
```
curl -s https://raw.githubusercontent.com/nalbam/openshift/master/bin/install-master.sh | bash

sudo yum install centos-release-openshift-origin
sudo yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion origin-clients 
sudo yum install docker python-rhsm-certificates

#edit /etc/sysconfig/docker file and add --insecure-registry 172.30.0.0/16 to the OPTIONS parameter.
sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' \ 

sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker
```
* https://wiki.centos.org/SpecialInterestGroup/PaaS/OpenShift-Quickstart

### OC CLUSTER
```
wget $(curl -s https://api.github.com/repos/openshift/origin/releases/latest | grep browser_download_url | grep linux | grep server | cut -d'"' -f4)
tar -xvzf openshift-origin-server-*-linux-64bit.tar.gz
cd openshift-origin-server-*-linux-64bit
sudo cp -rf hyperkube kubectl oadm oc openshift /usr/local/bin/

sudo ln -s /usr/local/bin/oc /usr/bin/oc
sudo ln -s /usr/local/bin/openshift /usr/bin/openshift

oc cluster up
```

## domain
```
oc expose svc/frontend --hostname=console.nalbam.com

sudo ~/certbot/certbot-auto certonly --standalone \
  --email me@nalbam.com -d console.nalbam.com

oc create route edge --service=frontend \
    --cert=/home/nalbam/console.nalbam.com/fullchain.pem \
    --key=/home/nalbam/console.nalbam.com/privkey.pem \
    --ca-cert=/home/nalbam/console.nalbam.com/isrgrootx1.pem \
    --hostname=console.nalbam.com
```
* https://docs.openshift.com/container-platform/3.9/dev_guide/routes.html

## remove
```
rm -rf /usr/local/bin/oc /usr/local/bin/openshift
rm -rf /usr/local/bin/hyperkube /usr/local/bin/kubectl /usr/local/bin/oadm /usr/local/bin/oc /usr/local/bin/openshift
```
