#!/bin/sh

set -e

docker compose up -d stepca

sleep 5

# sans を含めた証明書を発行する
python3 -m tools ca_certificate


# 連鎖順は重要
# wild.platform.localtest.me.crt（サーバー証明書リーフ）-> intermediate_ca.crt（中間CA）の順で連結。
# クライアントは、leaf → intermediate → root の連鎖を検証する（rootはクライアントに導入済みの前提）
docker compose exec stepca sh -c "cat /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/intermediate_ca.crt > /home/step/certs/fullchain.wild.platform.localtest.me.crt"
