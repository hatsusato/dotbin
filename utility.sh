#!/bin/bash

set -eu -o pipefail
if test "${DEBUG+'bound'}"; then
    # '$DEBUG' is bound variable
    set -vx
fi
readonly BIN_DIR=$(realpath "$(dirname "${UTILITY_FILE}")")
export PATH="/bin:/usr/bin"
export LANG='C'
