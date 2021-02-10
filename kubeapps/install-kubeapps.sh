set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

ytt -f $WORKING_DIR/kubeapps-helm-values.yaml -f $1 | helm template bitnami/kubeapps --include-crds --name-template kubeapps -f- > $WORKING_DIR/chart.yaml

#kubeapps always fails with kapp
ytt -f $WORKING_DIR/kubeapps-dependencies.yaml -f $WORKING_DIR/integrate-contour-overlay.yaml -f $WORKING_DIR/chart.yaml -f $1 -f $pull_secret --file-mark 'chart.yaml:type=yaml-plain' > $WORKING_DIR/install.yaml
kubectl delete -f $WORKING_DIR/install.yaml -n kubeapps
kubectl apply -f $WORKING_DIR/install.yaml -n kubeapps
