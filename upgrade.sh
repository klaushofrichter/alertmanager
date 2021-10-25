#!/bin/bash
set -e

source ./config.sh

echo
echo "==== $0: Require KUBECONFIG"
[[ -z "${KUBECONFIG}" ]] && echo "KUBECONFIG not defined. Exit." && exit 1
echo "export KUBECONFIG=${KUBECONFIG}"

echo
echo "==== $0: upgrade prometheus-community stack (this may show warnings related to beta APIs)"
cat prom-values.yaml.template extra-am-values.yaml.template | envsubst "${ENVSUBSTVAR}" | helm upgrade --values - prom prometheus-community/kube-prometheus-stack -n monitoring
kubectl rollout restart statefulset.apps/alertmanager-prom-kube-prometheus-stack-alertmanager -n monitoring # alertmanager needs to restart to pickup config changes
#kubectl rollout restart deployment prom-kube-prometheus-stack-operator -n monitoring  # prometheus restart may not be needed
kubectl rollout status deployment.apps prom-grafana -n monitoring --request-timeout 5m
kubectl rollout status deployment.apps prom-kube-state-metrics -n monitoring --request-timeout 5m
kubectl rollout status deployment.apps prom-kube-prometheus-stack-operator -n monitoring --request-timeout 5m
kubectl rollout status statefulset.apps/alertmanager-prom-kube-prometheus-stack-alertmanager -n monitoring --request-timeout 5m
helm history prom -n monitoring

./test.sh
./slack.sh "Cluster ${CLUSTER}: kube-prometheus-stack updated using ${AMVALUES} values file."

echo 
echo "==== $0: Various information"
echo "export KUBECONFIG=${KUBECONFIG}"
echo "Lens: monitoring/prom-kube-prometheus-stack-prometheus:9090/prom"
echo "prometheus: http://localhost:${HTTPPORT}/prom"
echo "alertmanager: http://localhost:${HTTPPORT}/alert"
echo "grafana: http://localhost:${HTTPPORT}  (use admin/${GRAFANA_PASS} to login)"
[ -x ${AMTOOL} ] && sleep 4 && ${AMTOOL} config routes
