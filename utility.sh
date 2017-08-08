#!/bin/bash

set -eu -o pipefail
if test "${DEBUG+'bound'}"; then
    # '$DEBUG' is bound variable
    set -vx
fi
readonly BIN_DIR=$(dirname "${BASH_SOURCE}")
export PATH='/bin:/usr/bin'
export LC_ALL='C'

Emptify() {
    </dev/zero head -c ${#1} | tr '\0' ' '
}
ErrorMessage() {
    if (($# == 0)); then
        cat - >&2
    else
        local name=$(basename "$0")
        local empty=$(Emptify "${name}")
        for msg in "$@"; do
            echo "${name}: ${msg}"
            name="${empty}"
        done >&2
    fi
}
Error() {
    local -i err=$?
    if ((err == 0)); then
        err=1
    fi
    ErrorMessage "$@"
    exit ${err}
}
Assert() {
    local -i err=$?
    if ((err == 0)); then
        err=1
    fi
    ErrorMessage "$@"
    return ${err}
}
Command() {
    PATH="${BIN_DIR}:${PATH}" eval "$@"
}
ScriptFile() {
    realpath "$0"
}
ScriptDir() {
    dirname "$(ScriptFile)"
}
Bound() {
    if (($# == 1)); then
        test "${!1+'bound'}"
    else
        (("$1" <= "$2"))
    fi
}
Parse() {
    if (($# == 0)); then
        <<<'Logic error: no argument to parse' Assert
    fi
    case "$1" in
        --?* )
            parsed_="${1#*=}"
            return 1;;
        -??* )
            parsed_="${1:2}"
            return 1;;
        -? )
            if ! Bound 2 $#; then
                Error "argument after '$1' is missing"
            fi
            parsed_="$2"
            return 2;;
        * )
            parsed_="$1"
            return 0;;
    esac
}
AtExit() {
    err=$?
    if Bound tmpfiles_; then
        rm -f "${tmpfiles_[@]}"
    fi
    exit ${err}
}
Tempfiles() {
    if Bound tmpfiles_; then
        Error 'tmporary files have already created'
    fi
    declare -i count="${1-}"
    if ((count <= 0)); then
        count=1
    fi
    trap AtExit EXIT
    declare -ag tmpfiles_
    for i in $(seq ${count}); do
        tmpfiles_+=($(mktemp))
    done
}
