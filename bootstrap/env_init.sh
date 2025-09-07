#!/bin/sh

set -e

echo UID=$(id -u)
echo GID=$(id -g)

echo MINIO_ROOT_USER=minioadmin
echo MINIO_ROOT_PASSWORD=minioadmin123

echo KONG_HTTP_PORT=80
echo KONG_HTTPS_PORT=8443
