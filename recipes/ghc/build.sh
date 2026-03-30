#!/usr/bin/env bash
set -euo pipefail

# GHC bindist install: configure with prefix, then make install
./configure --prefix="$PREFIX"
make install
