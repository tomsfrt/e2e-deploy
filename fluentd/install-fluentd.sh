set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

ytt  -f $1 -f $WORKING_DIR/chart.yaml -f $pull_secret --file-mark 'chart.yaml:type=yaml-plain' | kapp deploy -a fluentd -n fluentd -f- --diff-changes --yes
