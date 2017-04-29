#!/bin/bash

set -euo pipefail

dub test
dub run -c unittest-unthreaded --build=unittest
dub run -c unittest-light --build=unittest
