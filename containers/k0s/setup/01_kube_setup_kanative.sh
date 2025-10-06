#!/bin/sh

set -e

# https://knative.dev/blog/articles/knative-serving-in-k0s/#create-custom-knative-deployment-files
ACTION=apply
KN_VER=knative-v1.19.6  # 一致するバージョンがないので仕方ない
KO_VER=knative-v1.19.5

# k0s kubectl get ns knative-serving || kubectl create ns knative-serving
mkdir -p /var/lib/k0s/manifests/knative
cd /var/lib/k0s/manifests/knative

ls -l
curl -fsSL https://github.com/knative/serving/releases/download/knative-v1.19.6/serving-crds.yaml -o serving-crds.yaml
curl -fsSL https://github.com/knative/serving/releases/download/${KN_VER}/serving-core.yaml -o serving-core.yaml
curl -fsSL https://github.com/knative-extensions/net-kourier/releases/download/${KO_VER}/kourier.yaml -o kourier.yaml

cat <<EOF > /var/lib/k0s/manifests/knative/hello-knative.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello-knative
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "1"
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go:latest
          env:
            - name: TARGET
              value: "Edge!!"
EOF


