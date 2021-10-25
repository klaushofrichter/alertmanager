#!/bin/bash
# this uninstalls kube-prometheus-stack 

set -e

echo
echo "==== $0: Require KUBECONFIG"
[[ -z "${KUBECONFIG}" ]] && echo "KUBECONFIG not defined. Exit." && exit 1
echo "export KUBECONFIG=${KUBECONFIG}"

#
# Delete prometheus installation and namespace if namespace is present
if [[ ! -z $(kubectl get namespace | grep "^monitoring" ) ]]; then

  echo
  echo "==== $0: Helm uninstall release (this may fail)"
  helm uninstall prom monitoring || true

  echo 
  echo "==== $0: Check if webhooks admissions for kube-prometheus are remaining"
  items=$(kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io -o json | npx jq '.items | length')
  while [ $items -gt 0 ]; do
    items=$(( ${items} - 1 ))
    name=$(kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io -o json | npx jq -r ".items[${items}].metadata.name")
    indicator="$(echo ${name} | cut -d '-' -f2)-$(echo ${name} | cut -d '-' -f3)"
    if [[ ${indicator} == "kube-prometheus" ]]; then
      echo "validatingwebhookconfigurations \"${name}\" to be deleted..."
      kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io ${name}
    else
      echo "validatingwebhookconfigurations \"${name}\" remains..."
    fi
  done

  echo 
  echo "==== $0: Check if MutatingWebhookConfiguration for kube-prometheus are remaining"
  items=$(kubectl get MutatingWebhookConfiguration -o json | npx jq '.items | length')
  while [ $items -gt 0 ] 
  do
    items=$(( ${items} - 1 ))
    name=$(kubectl get MutatingWebhookConfiguration -o json | npx jq -r ".items[${items}].metadata.name")
    indicator="$(echo ${name} | cut -d '-' -f2)-$(echo ${name} | cut -d '-' -f3)"
    if [[ ${indicator} == "kube-prometheus" ]]; then
      echo "MutatingWebhookConfiguration \"${name}\" to be deleted"
      kubectl delete MutatingWebhookConfiguration ${name}
    else
      echo "MutatingWebhookConfiguration \"${name}\" remains installed"
    fi
  done

  echo
  echo "==== $0: Delete namespace \"monitoring\" (this may take a while)"
  kubectl delete namespace monitoring
else
  echo
  echo "==== $0: Namespace \"monitoring\" does not exist, no need to remove."
fi

