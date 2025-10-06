#!/bin/sh

set -e

docker compose up -d step-ca

sleep 5

docker compose exec step-ca step ca certificate \
  "platform.localtest.me" /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/wild.platform.localtest.me.key \
  --provisioner admin@example.com \
  --http-listen http://localhost:9000 \
  --root /home/step/certs/root_ca.crt \
  --san "platform.localtest.me" \
  --san "*.platform.localtest.me" \
  --san "*.default.apps.platform.localtest.me" \
  --san "*.default.knative.platform.localtest.me" \
  --provisioner-password-file /home/step/secrets/password



# 連鎖順は重要
# wild.platform.localtest.me.crt（サーバー証明書リーフ）-> intermediate_ca.crt（中間CA）の順で連結。
# クライアントは、leaf → intermediate → root の連鎖を検証する（rootはクライアントに導入済みの前提）
docker compose exec step-ca sh -c "cat /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/intermediate_ca.crt > /home/step/certs/fullchain.wild.platform.localtest.me.crt"
