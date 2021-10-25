#!/bin/bash
# this installs kube-prometheus-stack

set -e

source ./config.sh

echo
echo "==== $0:  Require KUBECONFIG"
[[ -z "${KUBECONFIG}" ]] && echo "KUBECONFIG not defined. Exit." && exit 1
echo "export KUBECONFIG=${KUBECONFIG}"

echo 
echo "==== $0: remove prometheus installation"
./unprom.sh

echo
echo "==== $0: install prometheus-community stack (this may show warnings related to beta APIs)"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
cat prom-values.yaml.template ${AMVALUES} | envsubst "${ENVSUBSTVAR}" | helm install --values - prom prometheus-community/kube-prometheus-stack -n monitoring
cat dashboard.json.template | envsubst "${ENVSUBSTVAR}" > /tmp/dashboard.json
kubectl create configmap ${APP}-dashboard-configmap -n monitoring --from-file="/tmp/dashboard.json"
kubectl patch configmap ${APP}-dashboard-configmap -p '{"metadata":{"labels":{"grafana_dashboard":"1"}}}' -n monitoring
rm /tmp/dashboard.json

echo 
echo "==== $0: Remove dashboards that may not make sense for K3D"
kubectl delete configmap -n monitoring prom-kube-prometheus-stack-etcd
kubectl delete configmap -n monitoring prom-kube-prometheus-stack-proxy
kubectl delete configmap -n monitoring prom-kube-prometheus-stack-controller-manager

echo
echo "==== $0: Wait for everything to roll out"
kubectl rollout status deployment.apps prom-grafana -n monitoring --request-timeout 5m
kubectl rollout status deployment.apps prom-kube-state-metrics -n monitoring --request-timeout 5m
kubectl rollout status deployment.apps prom-kube-prometheus-stack-operator -n monitoring --request-timeout 5m

echo
echo "==== $0: wait for prom-grafana ingress to be available"
while [ "$(kubectl get ing prom-grafana -n monitoring -o json | npx jq -r .status.loadBalancer.ingress[0].ip)" = "null" ]
do
  i=$[$i+1]
  [ "$i" -gt "60" ] && echo "this took too long... exit." && exit 1
  echo -n "."
  sleep 2
done
sleep 1
echo "done"

#
# running a simple test
./test.sh
./slack.sh "Cluster ${CLUSTER}: kube-prometheus-stack installed using ${AMVALUES} values file."

echo 
echo "==== $0: Various information"
echo "export KUBECONFIG=${KUBECONFIG}"
echo "Lens: monitoring/prom-kube-prometheus-stack-prometheus:9090/prom"
echo "prometheus: http://localhost:${HTTPPORT}/prom"
echo "alertmanager: http://localhost:${HTTPPORT}/alert"
echo "grafana: http://localhost:${HTTPPORT}  (use admin/${GRAFANA_PASS} to login)"
[ -x ${AMTOOL} ] && sleep 4 && ${AMTOOL} config routes
