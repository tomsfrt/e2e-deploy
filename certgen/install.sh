set -x
WORKING_DIR=$(dirname "$0")
pull_secret=$WORKING_DIR/../common/pull-secret.yaml

kubectl apply -f 
ytt --ignore-unknown-comments -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yam -f values.yaml -f $pull_secret > $WORKING_DIR/certmgr.yml

kapp deploy -a certmgr -n certmgr -f $WORKING_DIR/certmgr.yml --diff-changes --yes

ytt --ignore-unknown-comments -f $WORKING_DIR/issuer.yaml -f values.yaml  | kubectl apply -f-