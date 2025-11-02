#!/bin/sh

set -e


EXTERNAL_DOMAIN=$EXTERNAL_DOMAIN

# シンボリックリンクは動かない
cd -- "$(dirname -- "$0")" || exit 1

NODEIP=localhost

echo "Waiting for route to accept traffic at Host: hello-ksvc-http.default.$EXTERNAL_DOMAIN http://$NODEIP:30080"
kubectl apply -f ../services/hello-ksvc-http.yml
# kubectl wait --for=condition=Ready kservice/hello-ksvc-http -n default --timeout=180s
# kubectl wait -n default --for=condition=Ready pod -l 'serving.knative.dev/service=hello-ksvc-http' --timeout=180s
# f: 4xx/5xx エラーで失敗扱いにする s: 進捗バーなど非表示
until curl -v -fs -H "Host: hello-ksvc-http.default.$EXTERNAL_DOMAIN" http://$NODEIP:30080; do
  sleep 5
done

kubectl apply -f ../services/hello-ksvc-grpc.yml

echo "Waiting for route to accept traffic at Host: hello-ksvc-grpc.default.$EXTERNAL_DOMAIN http://$NODEIP:30080"
until grpcurl -v -plaintext -authority "hello-ksvc-grpc.default.$EXTERNAL_DOMAIN" $NODEIP:30080 list; do
  sleep 5
done

kubectl get ksvc
kubectl get pods

kubectl apply -f ../services/hello-ksvc-httpbin.yml
kubectl apply -f ../services/hello-ksvc-websocket.yml
