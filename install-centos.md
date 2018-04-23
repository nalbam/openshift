## install
```
curl -s https://raw.githubusercontent.com/nalbam/openshift/master/bin/install-master.sh | bash

vi /etc/sysconfig/docker
INSECURE_REGISTRY='--selinux-enabled --insecure-registry 172.30.0.0/16 --insecure-registry registry.access.redhat.com'

sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker
```
* https://wiki.centos.org/SpecialInterestGroup/PaaS/OpenShift-Quickstart

### OC CLUSTER (All-in-One)
```
wget $(curl -s https://api.github.com/repos/openshift/origin/releases/latest | grep browser_download_url | grep linux | grep server | cut -d'"' -f4)
tar -xvzf openshift-origin-server-*-linux-64bit.tar.gz
cd openshift-origin-server-*-linux-64bit
sudo cp -rf hyperkube kubectl oadm oc openshift /usr/local/bin/

sudo ln -s /usr/local/bin/oc /usr/bin/oc
sudo ln -s /usr/local/bin/openshift /usr/bin/openshift

oc cluster up --public-hostname=console.nalbam.com --routing-suffix=apps.nalbam.com
```

### yum origin (x)
```
sudo yum install -y centos-release-openshift-origin origin-clients 
```

## domain (x)
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
sudo rm -rf /usr/bin/oc /usr/bin/openshift
sudo rm -rf /usr/local/bin/hyperkube /usr/local/bin/kubectl /usr/local/bin/oadm /usr/local/bin/oc /usr/local/bin/openshift
```
