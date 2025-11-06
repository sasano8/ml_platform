#!/bin/sh

set -e

WSLPATH=$(wslpath -w "$PWD/volumes/step/certs")

echo "Please add root_ca.crt to windows. Windows + R -> certmgr.msc"
printf '%s\n' "${WSLPATH}"  # make 経由だと\が制御文字と認識されてしまうので、printf を使う
