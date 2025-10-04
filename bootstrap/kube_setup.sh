#!/bin/sh

set -e

# KUBECONFIG を編集し、ip の変更による影響を受けないようにする
docker compose exec -e KUBECONFIG=/var/lib/k0s/kubelet.conf kube k0s kubectl config set-cluster default --server=https://127.0.0.1:6443
docker compose exec kube apk add curl
docker compose exec kube apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing grpcurl

