set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

ytt -f $WORKING_DIR/fluentd-helm-values.yaml -f $1 | helm template \
--set aggregator.configMap=elasticsearch-output \
--set aggregator.extraEnv[0].name=elasticsearch-elasticsearch-data.elasticsearch.svc.cluster.local \
--set aggregator.extraEnv[1].name=9200 \
--include-crds bitnami/fluentd \
-n fluentd \
 --name-template fluentd \
 -f- > $WORKING_DIR/chart.yaml

ytt -f $WORKING_DIR/fluentd-dependencies.yaml -f $1 -f $WORKING_DIR/chart.yaml -f $pull_secret --file-mark 'chart.yaml:type=yaml-plain' | kapp deploy -a fluentd -n fluentd -f- --diff-changes --yes