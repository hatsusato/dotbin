#!/bin/bash

set -eu -o pipefail
if test "${DEBUG+'bound'}"; then
    # '$DEBUG' is bound variable
    set -vx
fi
readonly BIN_DIR=$(realpath "$(dirname "${UTILITY_FILE}")")
export PATH="/bin:/usr/bin"
export LANG='C'

Error() {
    local -i err=$?
    if ((err == 0)); then
        err=1
    fi
    if (($# == 0)); then
        cat - >&2
    else
        local name=$(basename "$0")
        local empty=$(head -c ${#name} </dev/zero | tr '\0' ' ')
        for msg in "$@"
        do
            echo "${name}: ${msg}"
            name="${empty}"
        done >&2
    fi
    exit ${err}
}
Assert() {
    local -i err=$?
    if ((err == 0)); then
        err=1
    fi
    for msg in "$@"
    do
        echo "${msg}"
    done >&2
    return ${err}
}
