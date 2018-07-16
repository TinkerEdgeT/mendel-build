#!/bin/bash

set -e
set -x

# Run continuous.sh first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash ${SCRIPT_DIR}/continuous.sh

m docker-make-repo

m sign-repo

# Copy signed repo to artifacts
cp -r ${PRODUCT_OUT}/repo/debian_repo ${KOKORO_ARTIFACTS_DIR}
