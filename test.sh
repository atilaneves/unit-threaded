#!/bin/bash

set -euo pipefail

DC="${DC:-dmd}"
if [ "${DETERMINISTIC_HINT:-0}" -eq 1 ]; then
    ARGS=(--single)
else
    ARGS=()
fi
dub test --build=unittest-cov --compiler="$DC" -- "${ARGS[@]}"
dub run -c unittest-unthreaded --build=unittest-cov --compiler="$DC" -- "${ARGS[@]}"
# See issue #96
#dub run -c unittest-light --build=unittest -- "${ARGS[@]}"
