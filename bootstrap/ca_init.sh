#!/bin/sh

set -e

# パスワードファイル生成
mkdir -p $PWD/volumes/step/secrets
openssl rand -base64 32 > $PWD/volumes/step/secrets/password

# 初期化
# ここで Root/Intermediate が生成され、config/ca.json などができます。
# プロビジョナー（発行者）に JWK を使うので、後で CLI/API から発行が楽です。
# dns は外部アドレス
# address は内部アドレス
docker run --rm -it \
  --user $(id -u):$(id -g) \
  -v $PWD/volumes/step:/home/step \
  smallstep/step-ca \
  step ca init \
    --password-file /home/step/secrets/password \
    --deployment-type standalone \
    --dns ca.platform.localtest.me \
    --address :9000 \
    --name "Localhost" \
    --provisioner admin@example.com

# 元ファイルの所有権のままroot領域に格納
sudo cp -p ./volumes/step/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
sudo update-ca-certificates  # /etc/ssl/certs/ca-certificates.crt に出力される（curl はここを読むが、httpx などは読まない）
echo Please add root_ca.crt to windows.
