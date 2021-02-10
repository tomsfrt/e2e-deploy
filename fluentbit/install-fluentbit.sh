set -x
WORKING_DIR=$(dirname "$0")

kubectl apply -n fluentbit -f $WORKING_DIR/fluent-bit-service-account.yaml
kubectl apply -n fluentbit -f $WORKING_DIR/fluent-bit-role.yaml
kubectl apply -n fluentbit -f $WORKING_DIR/fluent-bit-role-binding.yaml
kubectl apply -n fluentbit -f $WORKING_DIR/fluent-bit-configmap.yaml
kubectl apply -n fluentbit -f $WORKING_DIR/fluent-bit-ds.yaml