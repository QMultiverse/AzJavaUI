#!/bin/bash
# infra/grid/grid-deploy.sh
# Called by Azure Pipelines at the start of each UI test run.
# NOT replaced by Bicep — this is operational, not infrastructure.

set -euo pipefail

RG="${RESOURCE_GROUP}"
CHROME_SESSIONS="${CHROME_SESSIONS:-4}"

HUB_NAME="selenium-hub-${BUILD_ID}"

echo "[GRID] Deploying | BUILD_ID=${BUILD_ID}"

# Deploy Hub
# FQDN is always: <dnsNameLabel>.<location>.azurecontainer.io
HUB_FQDN="${HUB_NAME}.${LOCATION}.azurecontainer.io"
az container create \
  --resource-group "${RG}" --name "${HUB_NAME}" \
  --image selenium/hub:4.20.0 \
  --ports 4444 4442 4443 \
  --ip-address Public --cpu 1 --memory 2 \
  --dns-name-label "${HUB_NAME}" \
  --restart-policy Never --output none \
  --os-type Linux

# Deploy Chrome and Edge nodes
for BROWSER in chrome edge; do
  SESSIONS=$([[ "$BROWSER" == 'chrome' ]] && echo ${CHROME_SESSIONS} || echo 2)
  NAME="selenium-${BROWSER}-${BUILD_ID}"
  # FQDN is always: <dnsNameLabel>.<location>.azurecontainer.io
  FQDN="${NAME}.${LOCATION}.azurecontainer.io"
  az container create \
    --resource-group "${RG}" --name "${NAME}" \
    --image selenium/node-${BROWSER}:4.20.0 \
    --cpu 2 --memory 4 --restart-policy Never \
    --ip-address Public \
    --dns-name-label "${NAME}" \
    --ports 5555 \
    --environment-variables \
      SE_EVENT_BUS_HOST=${HUB_FQDN} \
      SE_EVENT_BUS_PUBLISH_PORT=4442 \
      SE_EVENT_BUS_SUBSCRIBE_PORT=4443 \
      SE_NODE_HOST="${FQDN}" \
      SE_NODE_MAX_SESSIONS=${SESSIONS} \
    --os-type Linux \
    --output none
done

# Health check
until curl -sf "http://${HUB_FQDN}:4444/wd/hub/status" | \
  python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin)['value']['ready'] else 1)"; do
  sleep 5
done

GRID_URL="http://${HUB_FQDN}:4444/wd/hub"
echo "##vso[task.setvariable variable=SELENIUM_GRID_URL]${GRID_URL}"
echo "[GRID] Ready at ${GRID_URL}"
