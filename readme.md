# Tanzu e2e Install Automation

## Background
Automate the install of common tooling for end2end demos.  This project assumes that you have a clean cluster with a bastion host that can
run docker and assorted bash scripts.  This has been tested with the standard Ubuntu bastion host provisioned by TKG.


## Pre-install
```bash
sudo apt install docker.io git

sudo groupadd docker

sudo usermod -aG docker ubuntu

newgrp docker 
```

## Run install

```bash
curl -o deploy.tar https://tanzu-e2e-install.s3.amazonaws.com/deploy.tar -vL

tar xvf deploy.tar

cd e2e-deploy

chmod +x env-install.sh

#make sure you have kubectl access to your cluster

#edit the values.yaml to customize your install

./env-install.sh

```

## Deploy a Pipeline


```bash
 kp secret create harbor-creds --registry harbor.<your domain> --registry-user admin -n petclinic

```

```bash
fly -t concourse login -c "https://concourse.<your domain>" -u "<user from values" -p "<password from values>" 
fly -t concourse set-pipeline -c pipeline/spring-petclinic.yaml -p spring-petclinic 

```



```bash
ytt -f e2e-repo/pipeline/secrets.yaml -f e2e-repo/pipeline/values.yaml \
  --data-value commonSecrets.harborDomain=harbor.{{}} \
  --data-value commonSecrets.kubeconfigBuildServer=$(yq d ~/.kube/config 'clusters[0].cluster.certificate-authority' | yq w - 'clusters[0].cluster.certificate-authority-data' "$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)" | yq r - -j) \
  --data-value commonSecrets.kubeconfigAppServer=$(yq d ~/.kube/config 'clusters[0].cluster.certificate-authority' | yq w - 'clusters[0].cluster.certificate-authority-data' "$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)" | yq r - -j) \
  --data-value commonSecrets.concourseHelperImage=harbor.<your domain>/concourse/concourse-helper \
  --data-value petclinic.wavefront.deployEventName=petclinic-deploy \
  --data-value petclinic.configRepo=https://github.com/tanzu-end-to-end/spring-petclinic-config \
  --data-value petclinic.host=petclinic-{{ session_namespace }}.{{ ingress_domain }} \
  --data-value petclinic.image=harbor.e2e.tsfrt.info/{{ session_namespace }}/spring-petclinic \
  --data-value petclinic.tbs.namespace={{ session_namespace }} \
  --data-value petclinic.wavefront.applicationName=petclinic-{{ session_namespace }} \
  --data-value "petclinic.codeRepo=${PETCLINIC_GIT_URL}" \
   | kubectl apply -f- -n concourse-{{ session_namespace }}

```

