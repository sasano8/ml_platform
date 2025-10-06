#!/bin/sh

set -e


# これは ip 変更時に動かなくなることを回避（ローカルホストで常に見つかるように）する
# certificate-authority-data がかけるのでなにか予期しないことがおきるかも？
# 初回起動前に存在しないので起動後に実行する
KUBECONFIG=/var/lib/k0s/kubelet.conf kubectl config set-cluster default --server=https://127.0.0.1:6443
HOST_DOMAIN=$APP_DOMAIN

# ingress に kourier を指定
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

# 外部ドメインの指定
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"knative.platform.localtest.me":""}}'

# これは動かなかった
# kubectl -n kourier-system patch svc kourier --type merge -p '{
#   "spec":{"type":"NodePort",
#     "ports":[
#       {"name":"http2","port":80,"nodePort":30080},
#       {"name":"https","port":443,"nodePort":30443}
# ]}}'

# ingressPort -> nodePort -> targetPort の設定
kubectl -n kourier-system patch svc kourier --type merge -p '{
  "spec": {
    "ports": [
      {"name":"http2-external","port":80,"nodePort":30080,"targetPort":8080,"protocol":"TCP"},
      {"name":"https-external","port":443,"nodePort":30443,"targetPort":8443,"protocol":"TCP"}
    ]
  }
}'



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

kubectl apply -f /var/lib/k0s/manifests/knative/hello-knative.yaml
kubectl wait --for=condition=Ready kservice/hello-knative -n default --timeout=180s

# curl -v -H "Host: hello-knative.default.knative.platform.localtest.me" http://127.0.0.1:8081
curl -v -H "Host: hello-knative.default.knative.platform.localtest.me" http://$HOST_DOMAIN:30080
# curl -H "Host: hello-knative.default.knative.platform.localtest.me" http://172.23.0.1:30080

# curl http://hello.default.knative.platform.localtest.me:30080


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
