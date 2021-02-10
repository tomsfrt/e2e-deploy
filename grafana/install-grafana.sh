set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

ytt -f $WORKING_DIR/grafana-helm-values.yaml -f $1 | helm template --include-crds bitnami/grafana -n grafana --name-template grafana -f- > $WORKING_DIR/chart.yaml

ytt -f $1 -f $WORKING_DIR/chart.yaml -f $pull_secret --file-mark 'chart.yaml:type=yaml-plain' | kapp deploy -a grafana -n grafana -f- --diff-changes --yes