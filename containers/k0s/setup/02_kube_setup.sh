#!/bin/sh

set -e


# これは ip 変更時に動かなくなることを回避（ローカルホストで常に見つかるように）する
# certificate-authority-data がかけるのでなにか予期しないことがおきるかも？
# 初回起動前に存在しないので起動後に実行する
# KUBECONFIG=/var/lib/k0s/kubelet.conf kubectl config set-cluster default --server=https://127.0.0.1:6443
EXTERNAL_DOMAIN=$EXTERNAL_DOMAIN

# シンボリックリンクは動かない
cd -- "$(dirname -- "$0")" || exit 1

# apiserverが立ち上がるのを待つ
echo "[wait] apiserver"
until kubectl get --raw='/readyz' >/dev/null 2>&1; do
  sleep 1
  echo "[wait] apiserver"
done

# ノードが立ち上がるのを待つ
# 初期化時に error: no matching resources found が出る
echo "[wait] kube node"
kubectl wait node --all --for=condition=Ready --timeout=180m

# knative が有効になるまで待機
echo "[wait] knative"
kubectl wait -n knative-serving deploy/webhook --for=condition=Available --timeout=60m

# ingress に kourier を指定
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

# 外部ドメインの指定
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type=json \
  -p='[{"op":"replace","path":"/data","value":{"'$EXTERNAL_DOMAIN'":""}}]'


# ingressPort -> nodePort -> targetPort の設定
kubectl -n kourier-system patch svc kourier --type merge -p '{
  "spec": {
    "ports": [
      {"name":"http2-external","port":80,"nodePort":30080,"targetPort":8080,"protocol":"TCP"},
      {"name":"https-external","port":443,"nodePort":30443,"targetPort":8443,"protocol":"TCP"}
    ]
  }
}'



kubectl get nodes -o wide
kubectl -n kourier-system get endpoints kourier -o wide
kubectl -n kourier-system get pod -o wide
kubectl -n kourier-system get service
kubectl -n kourier-system describe svc kourier
kubectl -n kube-system get ds kube-proxy
kubectl -n knative-serving get cm config-network -o jsonpath='{.data.ingress-class}'; echo

echo "[wait] kourier endpoints"
kubectl get endpoints -n kourier-system
kubectl wait -n kourier-system --for=jsonpath='{.subsets[0].addresses[0].ip}' endpoints/kourier --timeout=180m
kubectl get endpoints -n kourier-system
