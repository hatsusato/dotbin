#!/bin/bash

set -eu -o pipefail
if test "${DEBUG+'bound'}"; then
    # '$DEBUG' is bound variable
    set -vx
fi
readonly BIN_DIR=$(realpath "$(dirname "${BASH_SOURCE}")")
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
Command() {
    if (($# == 0)); then
        Assert 'Logic error: there is no command specified'
    fi
    local options='-type f -print -quit'
    local cmd=$(find -L "${BIN_DIR}" -name "$1" ${options} 2>/dev/null)
    if test -x "${cmd}"; then
        PATH="${BIN_DIR}:${PATH}" "${cmd}" "${@:2}"
    elif test "${cmd}"; then
        Error <<<"Command: '$1' is not executable"
    else
        Error <<<"Command: '$1' does not exist"
    fi
}
ScriptFile() {
    realpath "$0"
}
ScriptDir() {
    dirname "$(ScriptFile)"
}
Bound() {
    test "${!1+'bound'}"
}
Parse() {
    if (($# == 0)); then
        Assert 'Logic error: there is no argument to parse'
    fi
    case "$1" in
        --?* )
            parsed_="${1#*=}"
            return 1;;
        -??* )
            parsed_="${1:2}"
            return 1;;
        -? )
            if (($# == 1)); then
                Error "argument after '$1' is missing"
            fi
            parsed_="$2"
            return 2;;
        * )
            parsed_="$1"
            return 0;;
    esac
}
