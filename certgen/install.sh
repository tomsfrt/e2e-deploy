set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

kubectl create ns cert-manager -o yaml --dry-run=client| kubectl apply -f-
ytt -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml -f $pull_secret -f values.yaml  > $WORKING_DIR/certmgr.yaml

kapp deploy -a cert-manager -n cert-manager -f $WORKING_DIR/certmgr.yaml --diff-changes --yes

ytt -f $WORKING_DIR/issuer.yaml -f values.yaml | kubectl apply -f-