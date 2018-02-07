#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DC="${DC:-dmd}"
if [ "${DETERMINISTIC_HINT:-0}" -eq 1 ]; then
    ARGS=(--single)
else
    ARGS=()
fi

cd "$SCRIPT_DIR/issue61"
dub run --build=unittest-cov --compiler="$DC" -- "${ARGS[@]}"
