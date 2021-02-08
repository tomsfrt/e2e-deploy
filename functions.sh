create_docker_secret() {
  namespace=$1
  user=$2
  pass=$3
  email=$4
  name=$5
  kubectl create secret docker-registry $name --dry-run=client --docker-username=$user --docker-password=$pass --docker-email=$email -n $namespace -o yaml | kubectl apply -f -
}

install_tbs() {
  REG=$1
  USER=$2
  PASS=$3
  
  ytt -f /tmp/values.yaml \
      -f /tmp/manifests/ \
      -v docker_repository="${REG}" \
      -v docker_username=${USER} \
      -v docker_password=${PASS} \
      | kbld -f /tmp/images-relocated.lock -f- \
      | kapp deploy -a tanzu-build-service -f- -y

}

create_db() {
  dockerhub=$1
  namespace=$2
  export MYSQL_REGISTRY=$dockerhub
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  helm upgrade -i petclinic-db bitnami/mysql -n $namespace --version 6.14.11 -f <(cat petclinic-db-values.yaml | envsubst)
}