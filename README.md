# openshift

## basic
```
oc cluster up --public-hostname=console.nalbam.com --routing-suffix=apps.nalbam.com

oc login -u system:admin

oc policy add-role-to-user admin developer -n default
oc policy add-role-to-user admin developer -n openshift
oc policy add-role-to-user admin developer -n kube-system

oc cluster down
```
* https://github.com/openshift/origin

## kubectl
```
kubectl get deploy,pod,svc,ing,job,cronjobs --all-namespaces
kubectl get deploy,pod,svc,ing,job,cronjobs -n default
```
* https://github.com/nalbam/kubernetes

## source-to-image
```
oc project openshift

oc import-image -n openshift openshift/redhat-openjdk-18:1.3 --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest --confirm

oc create -n openshift -f https://raw.githubusercontent.com/nalbam/openshift/master/s2i/openjdk18-basic-s2i.json

oc delete template/openjdk18-basic-s2i
```
* https://github.com/openshift/source-to-image
* https://github.com/openshift/source-to-image/blob/master/examples/nginx-centos7/README.md
* https://github.com/openshift-s2i

## import image
```
oc import-image -n openshift openshift/sample-web:latest --from=docker.io/nalbam/sample-web:latest --confirm
```

## devops
```
oc new-project devops
oc policy add-role-to-user admin developer -n devops

# nexus3 - https://hub.docker.com/r/sonatype/nexus3/
oc new-app -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus3-template.yaml \
           -p NEXUS_VERSION=latest \
           -p MAX_MEMORY=2Gi

# gogs - https://hub.docker.com/r/openshiftdemos/gogs/
GOGS_HOST="gogs-devops.$(oc get route nexus -o template --template='{{.spec.host}}' | sed 's/nexus-devops.//g')"
oc new-app -f https://raw.githubusercontent.com/OpenShiftDemos/gogs-openshift-docker/master/openshift/gogs-template.yaml \
           -p GOGS_VERSION=latest \
           -p HOSTNAME=${GOGS_HOST} \
           -p SKIP_TLS_VERIFY=true

echo $(curl --post302 http://${GOGS_HOST}/user/sign_up \
  --form user_name=gogs \
  --form password=gogs \
  --form retype=gogs \
  --form email=gogs@gogs.com)

# sonarqube - https://hub.docker.com/r/openshiftdemos/sonarqube/
oc new-app -f https://raw.githubusercontent.com/OpenShiftDemos/sonarqube-openshift-docker/master/sonarqube-template.yaml \
           -p SONARQUBE_VERSION=7.0 \
           -p SONAR_MAX_MEMORY=4Gi

oc delete project devops
```
* https://github.com/openshiftdemos/

## spinnaker
```
oc new-project demo
oc policy add-role-to-user admin developer -n demo

git clone git@github.com:nalbam/charts.git

cd charts

helm install --name demo spinnaker --namespace=demo --timeout 3600

helm delete --purge demo

oc delete project devops
```
* https://github.com/nalbam/charts

## reference
* https://github.com/dwmkerr/terraform-aws-openshift/

## documents
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
* https://blog.novatec-gmbh.de/getting-started-minishift-openshift-origin-one-vm/

## examples
* https://github.com/openshift/origin/tree/master/examples/
* https://github.com/debianmaster/openshift-examples/

## pipeline
* https://github.com/openshift/origin/tree/master/examples/jenkins/pipeline/
