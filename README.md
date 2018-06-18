# openshift

## basic
```bash
oc cluster up --public-hostname=console.nalbam.com --routing-suffix=apps.nalbam.com

oc login -u system:admin

oc policy add-role-to-user admin admin -n default
oc policy add-role-to-user admin admin -n openshift
oc policy add-role-to-user admin admin -n kube-system

oc cluster down
```
* https://github.com/openshift/origin

## kubectl
```bash
kubectl get deploy,pod,svc,ing,job,cronjobs --all-namespaces
kubectl get deploy,pod,svc,ing,job,cronjobs -n default
```
* https://github.com/nalbam/kubernetes

### project
```bash
oc new-project ops
oc new-project dev
oc new-project qa

oc policy add-role-to-user admin admin -n ops
oc policy add-role-to-user admin admin -n dev
oc policy add-role-to-user admin admin -n qa
```

## sample
```bash
oc import-image sample-node --from=docker.io/nalbam/sample-node --confirm -n dev
oc new-app sample-node -n dev
```

## s2i
```bash
oc import-image spring --from=docker.io/nalbam/s2i-spring --confirm -n ops
oc import-image tomcat --from=docker.io/nalbam/s2i-tomcat --confirm -n ops

oc import-image openjdk18 --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift --confirm -n ops

# template
oc create -f https://raw.githubusercontent.com/nalbam/sample-spring/master/openshift/templates/pipeline.json
oc delete template/sample-spring-pipeline
```
* https://github.com/openshift-s2i
* https://github.com/openshift/source-to-image
* https://github.com/openshift/source-to-image/blob/master/examples/nginx-centos7/README.md
* https://access.redhat.com/containers/?tab=overview#/registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift

## ops
```bash
# jenkins
oc new-app jenkins-ephemeral -n ops

oc policy add-role-to-user edit system:serviceaccount:ops:jenkins -n dev
oc policy add-role-to-user edit system:serviceaccount:ops:jenkins -n qa

# nexus3 - https://hub.docker.com/r/sonatype/nexus3/
oc new-app -f https://raw.githubusercontent.com/nalbam/openshift/master/template/nexus3.yaml \
           -p NEXUS_VERSION=3.12.0 \
           -p VOLUME_CAPACITY=50Gi \
           -p MAX_MEMORY=2Gi \
           -n ops

# sonarqube - https://hub.docker.com/r/openshiftdemos/sonarqube/
oc new-app -f https://raw.githubusercontent.com/nalbam/openshift/master/template/sonarqube.yaml \
           -p SONARQUBE_VERSION=7.0 \
           -p SONAR_VOLUME_CAPACITY=2Gi \
           -p SONAR_MAX_MEMORY=4Gi \
           -n ops

# gogs - https://hub.docker.com/r/openshiftdemos/gogs/
GOGS_HOST="gogs-ops.$(oc get route nexus -o template --template='{{.spec.host}}' -n ops | sed 's/nexus-ops.//g')"
oc new-app -f https://raw.githubusercontent.com/nalbam/openshift/master/template/gogs.yaml \
           -p GOGS_VERSION=latest \
           -p HOSTNAME=${GOGS_HOST} \
           -p SKIP_TLS_VERIFY=true \
           -n ops

echo $(curl --post302 http://${GOGS_HOST}/user/sign_up \
  --form user_name=gogs \
  --form password=gogs \
  --form retype=gogs \
  --form email=gogs@gogs.com)
```
* https://github.com/openshiftdemos/

## prometheus
```bash
# prometheus
oc import-image prometheus --from=registry.access.redhat.com/openshift3/prometheus --confirm -n ops

oc new-app -f https://raw.githubusercontent.com/openshift/origin/master/examples/prometheus/prometheus.yaml

oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/prometheus/node-exporter.yaml -n kube-system
oc adm policy add-scc-to-user -z prometheus-node-exporter -n kube-system hostaccess
oc annotate ns kube-system openshift.io/node-selector= --overwrite
```
* https://github.com/openshift/origin/tree/master/examples/prometheus
* https://access.redhat.com/containers/?start=40#/registry.access.redhat.com/openshift3/prometheus

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
