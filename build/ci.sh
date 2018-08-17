#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"$SCRIPT_DIR"/ut.sh
"$SCRIPT_DIR"/../tests/integration_tests/run.sh
