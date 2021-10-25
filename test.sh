#!/bin/bash
set -e

source ./config.sh

echo
echo "==== $0: Test Alertmanager"

# sending an alert
RET=$(curl http://localhost:${HTTPPORT}/alert/api/v1/alerts -H "Content-Type: application/json" -d '[{
  "labels": {
    "alertname":"AlertmangerInstallationTest",
    "source": "curl",
    "severity": "none",
    "action": "ignore"
   },
  "annotations": {
    "summary": "Ignore - Testalert only",
    "description": "*IGNORE* - This alert was issued as a test of the Alertmanager installation. This is a one-time only alert"
  }}]') 
echo
if [[ $(echo "${RET}" | npx jq -r ".status") != "success" ]]; then
  echo "$0: Alertmanager test fail for sending an alert. exit."
  echo "$0: Return was ${RET}."
  exit 1
fi

RET=$( curl http://localhost:${HTTPPORT}/alert/api/v1/silences -H "Content-Type: application/json" -d '{
  "matchers": [
    {
       "name": "alertname",
       "value": "KubeControllerManagerDown"
    }
  ],
  "startsAt": "2020-10-25T22:12:33.533330795Z",
  "endsAt": "2025-10-25T23:11:44.603Z",
  "createdBy": "test.sh",
  "comment": "Silence",
  "status": {
    "state": "active"
  }
}')
echo 
if [[ $(echo "${RET}" | npx jq -r ".status") != "success" ]]; then
  echo "$0: Alertmanager test fail for sending a silence. exit."
  echo "$0: Return was ${RET}."
  exit 1
fi

