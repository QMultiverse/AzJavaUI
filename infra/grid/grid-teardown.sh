#!/bin/bash
# infra/grid/grid-teardown.sh
# Called by Azure Pipelines after each test run.
# condition: always ensures this runs even if tests failed.

set -euo pipefail

RG="${RESOURCE_GROUP}"
BUILD_ID="${BUILD_ID}"

echo "[GRID] Tearing down | BUILD_ID=${BUILD_ID}"

for NAME in \
  "selenium-hub-${BUILD_ID}" \
  "selenium-chrome-${BUILD_ID}" \
  "selenium-edge-${BUILD_ID}"; do

  if az container show \
      --resource-group "${RG}" \
      --name "${NAME}" > /dev/null 2>&1; then
    az container delete \
      --resource-group "${RG}" \
      --name "${NAME}" \
      --yes --output none
    echo "[GRID] Deleted: ${NAME}"
  fi
done

echo "[GRID] Teardown complete. Billing stops now."
