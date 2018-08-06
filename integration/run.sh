#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

clear

cd "$SCRIPT_DIR"/issue61
dub run --build=unittest-cov

cd "$SCRIPT_DIR"/issue109
dub run --build=unittest-cov

cd "$SCRIPT_DIR"/issue116
dub run --build=unittest-cov

cd "$SCRIPT_DIR"/runTestsMain
dub run --build=unittest-cov

cd "$SCRIPT_DIR"/issue121
dub test && issue121_status=0 || issue121_status=1

if [[ $issue121_status -eq 0 ]]; then
    echo "ERROR: issue121 should have failed but didn't"
    exit 1
else
    printf "\\nDisregard the error messages for issue121, it's supposed to fail\\n"
fi
