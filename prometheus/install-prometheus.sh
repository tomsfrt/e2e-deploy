set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

ytt -f $WORKING_DIR/prom-helm-values.yaml -f $1 | helm template bitnami/kube-prometheus --name-template prometheus -f- > $WORKING_DIR/chart.yaml

ytt -f $WORKING_DIR/prom-dependencies.yaml -f $1 -f $WORKING_DIR/chart.yaml -f $pull_secret --file-mark 'chart.yaml:type=yaml-plain' | kapp deploy -a prometheus -n prometheus -f- --diff-changes --yes