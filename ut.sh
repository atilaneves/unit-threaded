#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DC="${DC:-dmd}"

clear

cd "$SCRIPT_DIR"

printf 'Regular tests\n--------------------\n\n'
dub test -q --build=unittest-cov --compiler="$DC"

printf '\n\nUnthreaded tests\n--------------------\n\n'
dub run -q -c unittest-unthreaded --build=unittest-cov --compiler="$DC"

printf '\n\nLight tests\n--------------------\n\n'
dub run -q -c unittest-light --build=unittest --compiler="$DC"
