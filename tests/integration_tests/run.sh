#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DC="${DC:-dmd}"

clear

cd "$SCRIPT_DIR"/issue61
echo issue61
dub run -q --build=unittest-cov --compiler="$DC"

cd "$SCRIPT_DIR"/issue109
echo issue109
dub run -q --build=unittest-cov --compiler="$DC"

cd "$SCRIPT_DIR"/runTestsMain
echo runTestsMain
dub run -q --build=unittest-cov --compiler="$DC"



cd "$SCRIPT_DIR"/issue121
echo issue121
dub test -q  --compiler="$DC" && issue121_status=0 || issue121_status=1

if [[ $issue121_status -eq 0 ]]; then
    echo "ERROR: issue121 should have failed but didn't"
    exit 1
else
    printf "\\nDisregard the stack trace for issue121, it's supposed to fail\\n"
fi


cd "$SCRIPT_DIR"/issue157
echo issue157
dub run -q --build=unittest-cov --compiler="$DC"

cd "$SCRIPT_DIR"/issue187
echo issue187
dub run -q --build=unittest-cov --compiler="$DC"


cd "$SCRIPT_DIR"/property-light
echo property-light
dub run -q && prop_light_status=0 || prop_light_status=1

if [[ $prop_light_status -eq 0 ]]; then
    echo "ERROR: property-light should have failed but didn't"
    exit 1
else
    printf "\\nDisregard the stack trace for property-light, it's supposed to fail\\n"
fi
