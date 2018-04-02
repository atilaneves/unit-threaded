#!/bin/bash

rrset -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$SCRIPT_DIR"/issue61
dub run --build=unittest-cov

cd "$SCRIPT_DIR"/issue109
dub run --build=unittest-cov

cd "$SCRIPT_DIR"/issue116
dub run --build=unittest-cov
