#!/bin/bash

set -eu -o pipefail
if test "${DEBUG+'bound'}"; then
    # '$DEBUG' is bound variable
    set -vx
fi
readonly BIN_DIR=$(dirname "${BASH_SOURCE}")
export PATH='/bin:/usr/bin'
export LC_ALL='C'

HasStdin() {
    ! test -t 0
}
Emptify() {
    </dev/zero head -c ${#1} | tr '\0' ' '
}
ErrorMessage() {
    if HasStdin; then
        local name=$(cat -)
    else
        local name=$(basename "$0")
    fi
    if test "${name}"; then
        name+=': '
    fi
    local -r empty=$(Emptify "${name}")
    for msg in "$@"; do
        echo "${name}${msg}"
        name="${empty}"
    done >&2
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
    PATH="${BIN_DIR}:${PATH}" eval "${@@Q}"
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
        <<<'Parse' Error 'no argument specified'
    fi
    declare -g parsed_
    case "$1" in
        --?* )
            parsed_="${1#*=}"
            return 1;;
        -??* )
            parsed_="${1:2}"
            return 1;;
        -? )
            if ! Bound 2 $#; then
                <<<'Parse' Error "argument after '$1' is missing"
            fi
            parsed_="$2"
            return 2;;
        * )
            parsed_="$1"
            return 0;;
    esac
}
AtExit() {
    local -i err=$?
    if Bound tmpfiles_; then
        rm -f "${tmpfiles_[@]}"
    fi
    exit ${err}
}
Tmpfiles() {
    if Bound tmpfiles_; then
        <<<'Tmpfiles' Error 'temporary files have already created'
    fi
    local -i count="${1-}"
    if ((count <= 0)); then
        count=1
    fi
    trap AtExit EXIT
    declare -ag tmpfiles_
    for i in $(seq ${count}); do
        tmpfiles_+=($(mktemp))
    done
}
