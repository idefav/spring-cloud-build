#!/bin/bash

[[ -z $DEBUG ]] || set -o xtrace

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${ROOT_DIR}/../../.."
echo "Root directory is [${ROOT_DIR}]"

function usage {
    echo "usage: $0: <download-shellcheck|run-shellcheck|download-bats|run-bats|initialize-submodules>"
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

function shellcheck_installed() {
    shellcheck --version && return 0 || return 1
}

SHELLCHECK_VERSION="v0.6.0"
SHELLCHECK_INSTALLED="$( shellcheck_installed && echo "true" || echo "false" )"
echo "Shellcheck installed? [${SHELLCHECK_INSTALLED}]"
if [[ "${SHELLCHECK_INSTALLED}" != "false" ]]; then
    SHELLCHECK_BIN="shellcheck"
else
    SHELLCHECK_BIN="${ROOT_DIR}/../target/shellcheck-${SHELLCHECK_VERSION}/shellcheck"
fi
echo "Shellcheck binary location [${SHELLCHECK_BIN}]"

case $1 in
    download-shellcheck)
        if [[ "${OSTYPE}" == linux* && ! -z "${SHELLCHECK_BIN}" && "${SHELLCHECK_INSTALLED}" == "false" ]]; then
            SHELLCHECK_ARCHIVE="shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
            SHELLCHECK_ARCHIVE_SHA512SUM="d88733e95aea8e970c373a3f677a3eb272f14c12d3e9c93f81463b5fe406b43acdd3046d10c092f40c070a96a5fac1cf7e18b35ed790d76ecced6af32e2c8a85"
            if [[ -x "${ROOT_DIR}/../target/shellcheck-${SHELLCHECK_VERSION}/shellcheck" ]]; then
                echo "shellcheck already downloaded - skipping..."
                exit 0
            fi
            wget -P "${ROOT_DIR}/../target/" \
                "https://storage.googleapis.com/shellcheck/${SHELLCHECK_ARCHIVE}"
            pushd "${ROOT_DIR}/../target/"
            echo "${SHELLCHECK_ARCHIVE_SHA512SUM} ${SHELLCHECK_ARCHIVE}" | sha512sum -c -
            tar xvf "${SHELLCHECK_ARCHIVE}"
            rm -vf -- "${SHELLCHECK_ARCHIVE}"
            popd
        else
            if [[ "${SHELLCHECK_INSTALLED}" == "false" ]]; then
                echo "It seems that automatic installation is not supported on your platform."
                echo "Please install shellcheck manually:"
                echo "    https://github.com/koalaman/shellcheck#installing"
                exit 1
            fi
        fi
        ;;
    run-shellcheck)
            echo "Running shellcheck"
            if [[ "${SHELLCHECK_INSTALLED}" != "false" ]]; then
                SHELLCHECK_BIN="shellcheck"
            fi
            "${SHELLCHECK_BIN}" "${ROOT_DIR}"/src/main/asciidoc/*.sh
            echo "Shellcheck passed sucessfully!"
        ;;
    download-bats)
        if [[ -x "${ROOT_DIR}/../target/bats/bin/bats" ]]; then
            echo "bats already downloaded - skipping..."
            exit 0
        fi
        git clone https://github.com/bats-core/bats-core.git "${ROOT_DIR}/../target/bats"
        ;;
    run-bats)
            echo "Running bats"
            SHELLCHECK_BIN="${ROOT_DIR}/../target/bats/bin/bats"
            "${SHELLCHECK_BIN}" "${ROOT_DIR}"/src/test/bats
            echo "Bats passed sucesfully!"
        ;;
    initialize-submodules)
        files="$( ls "${ROOT_DIR}/src/test/bats/test_helper/bats-assert/" || echo "" )"
        pushd "${ROOT_DIR}/../"
            if [ ! -z "${files}" ]; then
                echo "Submodules already initialized";
                git submodule foreach git pull origin master || echo "Failed to pull - continuing the script"
            else
                echo "Initilizing submodules"
                git submodule init
                git submodule update
                git submodule foreach git pull origin master || echo "Failed to pull - continuing the script"
            fi
        popd
        ;;
    *)
        usage
        ;;
esac