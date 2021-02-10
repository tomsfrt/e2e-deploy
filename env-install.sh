#!/usr/bin/env bash

set -e
WORKING_DIR=$(dirname "$0")
source $WORKING_DIR/functions.sh
INSTALL_REPO=https://tanzu-e2e-install.s3.amazonaws.com/deploy.tar

if [[ -z $WORKING_DIR/values.yaml ]]; then
    echo "Missing values.yaml, setup your values.yaml file and run again"
fi

KAPP_VERSION=v0.35.0
YTT_VERSION=v0.31.0
HELM_VERSION=helm-v3.5.2-linux-amd64
KUBECTL_VERSION=v1.20.0
GIT_VERSION=git-2.9.5
KBLD_VERSION=v0.29.0

#ytt
 wget -O ytt "https://github.com/vmware-tanzu/carvel-ytt/releases/download/${YTT_VERSION}/ytt-linux-amd64"
 chmod +x ytt 
 sudo mv ytt /usr/local/bin

#kapp
 wget -O kapp "https://github.com/vmware-tanzu/carvel-kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64"
 chmod +x kapp 
 sudo mv kapp /usr/local/bin

#helm
 wget -o get_helm.sh https://get.helm.sh/${HELM_VERSION}.tar.gz
 tar -xvf ${HELM_VERSION}.tar.gz
 chmod +x linux-amd64/helm
 sudo mv linux-amd64/helm /usr/local/bin

#kbld
 wget -O kbld https://github.com/vmware-tanzu/carvel-kbld/releases/download/${KBLD_VERSION}/kbld-linux-amd64
 chmod +x kbld 
 sudo mv kbld /usr/local/bin

#kubectl
 wget -O kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
 chmod +x kubectl 
 sudo mv kubectl /usr/local/bin

#kp
wget -O kp https://github.com/vmware-tanzu/kpack-cli/releases/download/v0.2.0/kp-linux-0.2.0
 chmod +x kp 
 sudo mv kp /usr/local/bin

#yq
wget -O yq https://github.com/mikefarah/yq/releases/download/v4.5.0/yq_linux_amd64
 chmod +x yq
 sudo mv yq /usr/local/bin

#install fly
curl -sSL "https://github.com/concourse/concourse/releases/download/v6.7.3/fly-6.7.3-linux-amd64.tgz" |sudo tar -C /usr/local/bin/ --no-same-owner -xzv fly
 
curl -o deploy.tar $INSTALL_REPO -vL
tar xvf deploy.tar

#grab values that are needed for script
user=$(yq e '.common.dockerUser' values.yaml )
password=$(yq e '.common.dockerPassword' values.yaml )
domain=$(yq e '.ingress.domain' values.yaml )
registry="harbor.$domain"
email=$(yq e '.common.dockerEmail' values.yaml )
secret_name=$(yq e '.common.imagePullSecret' values.yaml )
tanzu_user=$(yq e '.tanzu.user' values.yaml )
tanzu_password=$(yq e '.tanzu.password' values.yaml )
harbor_password=$(yq e '.harbor.adminPassword' values.yaml )
docker=$(yq e '.registry.dockerhub' values.yaml )
#contour
curl -L  https://projectcontour.io/quickstart/contour.yaml > contour.yaml
ytt --ignore-unknown-comments -f contour.yaml -f $WORKING_DIR/values.yaml -f $WORKING_DIR/common/pull-secret.yaml -f $WORKING_DIR/common/lb-external-traffic.yaml | kubectl apply -f-
create_docker_secret "projectcontour" $user $password $email $secret_name

kubectl get services envoy -n projectcontour
read -p "create wildcard entry for your lb and press enter to proceed..."

#certgen
$WORKING_DIR/certgen/install.sh values.yaml
create_docker_secret "cert-manager" $user $password $email $secret_name

read -p "Cert-manager installed and cluster issuer created [hit enter]..."

#harbor
if [ -z "$skip_harbor" ]
then

  kubectl create ns harbor -o yaml --dry-run=client| kubectl apply -f-
  create_docker_secret "harbor" $user $password $email $secret_name
  $WORKING_DIR/harbor/install-harbor.sh values.yaml
fi

echo "Harbor installed..."
echo "Create a public project in harbor named tanzu-build-service"
read -p "Hit enter to proceed..."

#concourse
kubectl create ns concourse -o yaml --dry-run=client| kubectl apply -f-
create_docker_secret "concourse" $user $password $email $secret_name
$WORKING_DIR/concourse/install-concourse.sh values.yaml

read -p "Concourse installed [hit enter]..."

#build service
tar xvf build-service-1.0.3.tar -C /tmp
docker login registry.pivotal.io -u $tanzu_user -p $tanzu_password
docker login $registry/tanzu-build-service/build-service -u admin -p $harbor_password

kbld relocate -f /tmp/images.lock --lock-output /tmp/images-relocated.lock --repository "$registry/tanzu-build-service/build-service"
install_tbs "$registry/tanzu-build-service/build-service" "admin" $harbor_password
sleep 20
kp import -f descriptor-100.0.55.yaml 

read -p "Tanzu Build Service installed [hit enter]..."

#kubeapps
kubectl create ns kubeapps -o yaml --dry-run=client| kubectl apply -f-
create_docker_secret "kubeapps" $user $password $email $secret_name
$WORKING_DIR/kubeapps/install-kubeapps.sh values.yaml

sleep 10

kubectl get -n kubeapps secret $(kubectl get serviceaccount -n kubeapps kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo
echo "login token"
read -p "kubeapps installed [hit enter]..."

#prometheus
kubectl create ns prometheus -o yaml --dry-run=client| kubectl apply -f-
create_docker_secret "prometheus" $user $password $email $secret_name
$WORKING_DIR/prometheus/install-prometheus.sh values.yaml

#grafana
kubectl create ns grafana -o yaml --dry-run=client| kubectl apply -f-
create_docker_secret "grafana" $user $password $email $secret_name
$WORKING_DIR/grafana/install-grafana.sh values.yaml

#petclinic
kubectl create ns mysql -o yaml --dry-run=client| kubectl apply -f-
create_db $docker "mysql"







