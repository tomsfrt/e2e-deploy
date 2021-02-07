set -x

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update


ytt -f prom-helm-values.yaml -f $1 | helm template bitnami/kube-prometheus --name-template prometheus  -f- > chart.yaml

ytt -f prom-dependencies.yaml -f chart.yaml -f $1 --file-mark 'chart.yaml:type=yaml-plain' | kapp deploy -a prometheus -n prometheus -f- --diff-changes --yes

