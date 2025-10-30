#!/bin/sh

set -e

VERSION=v4.3.3
ARCH=linux-amd64

curl -o /usr/local/bin/gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/download/$VERSION/gomplate_$ARCH
chmod 755 /usr/local/bin/gomplate
