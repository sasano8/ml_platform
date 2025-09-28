#!/bin/sh

set -e

# curl のインストール
docker compose exec kube apk add curl
docker compose exec kube apk add helm

# サンプルアプリのインストール
docker compose exec kube k0s kubectl apply -f /mnt/kube/default --recursive
sleep 20
IP=$(docker compose exec kube k0s kubectl get svc httpbin -o jsonpath='{.spec.clusterIP}')
docker compose exec kube curl -H httpbin.default.apps.platform.localtest.me http://$IP/get


# アンインストール
# docker compose exec kube helm uninstall ingress-nginx -n ingress-nginx
# sleep 30
# docker compose exec kube k0s kubectl delete namespace/ingress-nginx
# sleep 5

# ワイルドカードサービスのセットアップ
docker compose exec kube k0s kubectl delete -f /mnt/kube/nginx --recursive || true
docker compose exec kube k0s kubectl apply -f /mnt/kube/nginx --recursive
sleep 20
IP=$(docker compose exec kube k0s kubectl get svc nginx-svc -o jsonpath='{.spec.clusterIP}')
docker compose exec kube curl -H 'Host: httpbin.default.apps.platform.localtest.me' http://$IP/get


# イングレスのセットアップ
docker compose exec kube helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
docker compose exec kube helm repo update
docker compose exec kube helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.ingressClass=nginx \
  --set controller.ingressClassResource.name=nginx \
  --set controller.watchIngressWithoutClass=false \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

sleep 20
docker compose exec kube curl -H 'Host: httpbin.default.apps.platform.localtest.me' http://localhost:30080/get

# 実環境上からの疎通
curl http://httpbin.default.apps.platform.localtest.me/get
