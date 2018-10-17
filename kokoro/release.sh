#!/bin/bash

set -e
set -x

# Run continuous.sh first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash ${SCRIPT_DIR}/continuous.sh
