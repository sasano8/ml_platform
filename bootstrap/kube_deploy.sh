#!/bin/sh

set -e

# 疎通確認用ツールのインストール
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
GRPCCURL=$(go env GOPATH)/bin/grpcurl
echo $GRPCCURL

# kubectl のエイリアス
docker compose exec kube sh -lc 'printf "%s\n" "#!/usr/bin/env sh" "exec k0s kubectl \"\$@\"" > /usr/local/bin/kubectl'
docker compose exec kube chmod +x /usr/local/bin/kubectl

# curl のインストール
docker compose exec kube apk add curl
docker compose exec kube apk add helm

# サンプルアプリのインストール
docker compose exec kube k0s kubectl delete -f /mnt/kube/default --recursive || true
docker compose exec kube k0s kubectl apply -f /mnt/kube/default --recursive
sleep 20

# s: 進捗を表示しない S: エラー時だけメッセージを出力
docker compose exec kube k0s kubectl run -i --rm curl --image=curlimages/curl --restart=Never -- -sS http://httpbin.default.svc.cluster.local/get

# 疎通に使える公開サービス: echo.websocket.org(wssのみ) ws.ifelse.io(ws,wss)
docker compose exec kube k0s kubectl run -i --env="NPM_CONFIG_UPDATE_NOTIFIER=false" --rm nodejs --image=node:20-alpine -- sh -lc "npx -y wscat -c ws://ws-echo.default.svc.cluster.local/ -x 'hello'"

# grpc の確認。-insecure もあるが、これは証明書の検証をスキップするだけで、証明書による暗号化をしないというわけではない
docker compose exec kube k0s kubectl run -it --rm grpcurl --image=fullstorydev/grpcurl --restart=Never -- -plaintext grpcbin.default.svc.cluster.local:80 list

# ワイルドカードサービスのセットアップ
docker compose exec kube k0s kubectl delete -f /mnt/kube/nginx --recursive || true
docker compose exec kube k0s kubectl apply -f /mnt/kube/nginx --recursive
sleep 20

# nginx-svc への接続は無限ループしてそう。何か工夫がいる。
# IP=$(docker compose exec kube k0s kubectl get svc nginx-svc -o jsonpath='{.spec.clusterIP}')
# docker compose exec kube curl -H 'Host: nginx-svc.default.apps.platform.localtest.me' http://$IP:30080/


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
# docker compose exec kube curl -H 'Host: httpbin.default.apps.platform.localtest.me' http://localhost:30080/get
# docker compose exec kube curl -H 'Host: ws-echo.default.apps.platform.localtest.me' http://localhost:30080/
# docker compose exec kube curl -v -H 'Host: grpcbin.default.apps.platform.localtest.me' http://localhost:30080/

IP=$(docker compose exec kube k0s kubectl get svc nginx-svc -o jsonpath='{.spec.clusterIP}')
docker compose exec kube curl -H 'Host: httpbin.default.apps.platform.localtest.me' http://$IP/get
docker compose exec kube k0s kubectl run -i --env="NPM_CONFIG_UPDATE_NOTIFIER=false" --rm nodejs --image=node:20-alpine -- sh -lc "npx -y wscat -c ws://$IP/ -H 'Host: ws-echo.default.apps.platform.localtest.me' -x 'hello'"

# docker compose exec kube curl -H 'Host: grpcbin.default.apps.platform.localtest.me' http://$IP/  # Empty reply from server(curl じゃ疎通できない)



# 実環境上からの疎通
# http2 化はできていない
# curl --http2 http://httpbin.default.apps.platform.localtest.me/get
# curl --http2 http://ws-echo.default.apps.platform.localtest.me/

curl http://httpbin.default.apps.platform.localtest.me/get
curl http://ws-echo.default.apps.platform.localtest.me/

docker run -i --net=host -e="NPM_CONFIG_UPDATE_NOTIFIER=false" --rm node:20-alpine sh -lc "npx -y wscat -c ws://ws-echo.default.apps.platform.localtest.me/ -x 'hello'"



# grpc の疎通ができない
# $GRPCCURL -plaintext grpcbin.default.apps.platform.localtest.me:80 list

# $(go env GOPATH)/bin/grpcurl -plaintext grpcbin.default.apps.platform.localtest.me:80 list

#--http2-prior-knowledge 


# $(go env GOPATH)/bin/grpcurl -vv -plaintext grpcb.in:9000 list
# $(go env GOPATH)/bin/grpcurl -vv grpcb.in:9001 list
