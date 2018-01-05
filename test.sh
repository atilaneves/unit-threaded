#!/bin/bash

set -euo pipefail

dub test
dub run -c unittest-unthreaded --build=unittest
# See issue #96
#dub run -c unittest-light --build=unittest
