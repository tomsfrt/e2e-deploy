set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update

ytt -f $WORKING_DIR/concourse-helm-values.yaml -f $1 | helm template concourse/concourse --name-template concourse -f- > $WORKING_DIR/chart.yaml

ytt -f $WORKING_DIR/concourse-dependencies.yaml -f $WORKING_DIR/ingress-path-overlay.yaml -f $WORKING_DIR/chart.yaml -f $1 -f $pull_secret --file-mark 'chart.yaml:type=yaml-plain' | kapp deploy -a concourse -n concourse -f- --diff-changes --yes
