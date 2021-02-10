set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

ytt -f $1 -f $WORKING_DIR/chart.yaml -f $pull_secret --ignore-unknown-comments | kapp deploy -a kibana -n kibana -f- --diff-changes --yes 