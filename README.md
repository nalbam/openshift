# openshift

* see: https://github.com/nalbam/basecamp/blob/master/openshift.md

## install 3.7
```
export DISK=/dev/sdf

export VERSION=v3.7.2
export BRANCH=release-3.7

export DOMAIN=nalbam.com

curl -s https://raw.githubusercontent.com/nalbam/openshift/master/install.sh | bash
```
 * https://github.com/openshift/openshift-ansible/tree/release-3.7

## install 3.9
```
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible
git checkout release-3.9

wget https://raw.githubusercontent.com/nalbam/openshift/master/inventory-local

sudo ansible-playbook -i inventory-local playbooks/prerequisites.yml
sudo ansible-playbook -i inventory-local playbooks/deploy_cluster.yml -vvv
```
 * https://github.com/openshift/openshift-ansible/tree/release-3.9
 * https://docs.docker.com/storage/storagedriver/device-mapper-driver/

## minishift
```
minishift start --vm-driver=virtualbox
```

## reference
* https://github.com/dwmkerr/terraform-aws-openshift/

## documents
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
* https://blog.novatec-gmbh.de/getting-started-minishift-openshift-origin-one-vm/

## examples
* https://github.com/openshiftdemos/
* https://github.com/openshift/origin/tree/master/examples/
* https://github.com/debianmaster/openshift-examples/

## pipeline
* https://github.com/openshift/origin/tree/master/examples/jenkins/pipeline/
