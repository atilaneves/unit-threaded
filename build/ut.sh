#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DC="${DC:-dmd}"

[ -z ${TERM-} ] || clear

cd "$SCRIPT_DIR"/..

[ -z ${TERM-} ] || printf 'Regular tests\n--------------------\n\n'
dub test -q --build=unittest-cov --compiler="$DC"

[ -z ${TERM-} ] || printf '\n\nUnthreaded tests\n--------------------\n\n'
dub run -q -c unittest-unthreaded --build=unittest-cov --compiler="$DC"

[ -z ${TERM-} ] || printf '\n\nLight tests\n--------------------\n\n'
dub run -q -c unittest-light --build=unittest-cov --compiler="$DC"

for dn in $(ls -d subpackages/*)
do
    # the autorunner subpackage cannot be tested itself; see tests/integration_tests/autorunner
    if [[ "$dn" != "subpackages/autorunner" ]]; then
        [ -z ${TERM-} ] || printf '\n\n'$dn' tests\n--------------------\n\n'
        dub test --build=unittest-cov -q --compiler="$DC" --root="$dn"
    fi
done
