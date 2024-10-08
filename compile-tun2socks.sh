#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

if [[ ! -d $NDK_HOME ]]; then
	echo "Android NDK: NDK_HOME not found. please set env \$NDK_HOME"
	exit 1
fi

TMPDIR=$(mktemp -d)
clear_tmp () {
  rm -rf $TMPDIR
}

trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; clear_tmp; exit 1' ERR INT
install -m644 $__dir/tun2socks.mk $TMPDIR/

pushd $TMPDIR
git clone --depth=1 https://github.com/XTLS/badvpn.git
git clone --depth=1 https://github.com/shadowsocks/libancillary.git
$NDK_HOME/ndk-build \
	NDK_PROJECT_PATH=. \
	APP_BUILD_SCRIPT=./tun2socks.mk \
	APP_ABI=arm64-v8a \
	APP_PLATFORM=android-29 \
	NDK_LIBS_OUT=$TMPDIR/libs \
	NDK_OUT=$TMPDIR/tmp \
	APP_SHORT_COMMANDS=false LOCAL_SHORT_COMMANDS=false -B -j 8

tar cvfz $__dir/libtun2socks.so.tgz libs
popd

rm -rf $TMPDIR
