#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DC="${DC:-dmd}"

cd "$SCRIPT_DIR"

dub test --build=unittest-cov --compiler="$DC"
dub run -c unittest-unthreaded --build=unittest-cov --compiler="$DC"
dub run -c unittest-light --build=unittest --compiler="$DC"
