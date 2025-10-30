#!/bin/sh

set -e


# これは ip 変更時に動かなくなることを回避（ローカルホストで常に見つかるように）する
# certificate-authority-data がかけるのでなにか予期しないことがおきるかも？
# 初回起動前に存在しないので起動後に実行する
# KUBECONFIG=/var/lib/k0s/kubelet.conf kubectl config set-cluster default --server=https://127.0.0.1:6443
APP_DOMAIN=$APP_DOMAIN

# シンボリックリンクは動かない
cd -- "$(dirname -- "$0")" || exit 1

# apiserverが立ち上がるのを待つ
echo "[wait] apiserver"
until kubectl get --raw='/readyz' >/dev/null 2>&1; do
  sleep 1
  echo "[wait] apiserver"
done

# ノードが立ち上がるのを待つ
echo "[wait] kube node"
kubectl wait node --all --for=condition=Ready --timeout=60m

# ingress に kourier を指定
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

# 外部ドメインの指定
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"'$APP_DOMAIN'":""}}'


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

# kubectl -n default logs -l serving.knative.dev/service=hello --tail=50
# kubectl -n default get pod -l serving.knative.dev/service=hello

# knative が有効になるまで待機
kubectl wait -n knative-serving deploy/webhook \
  --for=condition=Available --timeout=5m

kubectl apply -f ./hello-kservice.yaml
kubectl wait --for=condition=Ready kservice/hello-kservice -n default --timeout=180s
kubectl get ksvc
kubectl wait -n default --for=condition=Ready pod -l 'serving.knative.dev/service=hello-kservice' --timeout=180s
kubectl get pods

echo "[wait] kourier endpoints"
kubectl get endpoints -n kourier-system
kubectl wait -n kourier-system --for=jsonpath='{.subsets[0].addresses[0].ip}' endpoints/kourier --timeout=180m
kubectl get endpoints -n kourier-system

# できればかならず成功する状態を判定してから実行したい
echo "Waiting for route to accept traffic at http://hello-kservice.default.$APP_DOMAIN:30080"
# f: 4xx/5xx エラーで失敗扱いにする s: 進捗バーなど非表示
until curl -v -fs http://hello-kservice.default.$APP_DOMAIN:30080; do
  sleep 5
done


# apk add dnsmasq
# vi /etc/dnsmasq.conf

# # <domain>/<node_ip>
# address=/.knative.platform.localtest.me/172.23.0.1
# exec dnsmasq -k

# /etc/resolv.conf # の先頭に以下を書く 127.0.0.1:53 で待ち受けている
# nameserver 127.0.0.1



# autoTLS

# k0s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: step-acme
# spec:
#   acme:
#     server: https://step-ca:9000/acme/acme/directory   # ← step-ca の ACME directory
#     email: you@example.com
#     privateKeySecretRef:
#       name: step-acme-account-key
#     solvers:
#     - http01:
#         ingress:
#           class: kong
