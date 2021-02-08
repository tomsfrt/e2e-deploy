set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

kubectl --dry-run create ns certmanager -o yaml | kubectl apply -f-
ytt --ignore-unknown-comments -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yam -f $pull_secret -f values.yaml  > $WORKING_DIR/certmgr.yaml

kapp deploy -a certmgr -n certmanager -f $WORKING_DIR/certmgr.yaml --diff-changes --yes

ytt --ignore-unknown-comments -f $WORKING_DIR/issuer.yaml -f values.yaml | kubectl apply -f-