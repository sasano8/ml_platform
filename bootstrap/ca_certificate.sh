#!/bin/sh

set -e

docker compose up -d stepca

sleep 5

# ca-url http://stepca.172-31-97-7.sslip.io:9000

docker compose exec stepca step ca certificate \
  "172-31-97-7.sslip.io" /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/wild.platform.localtest.me.key \
  --provisioner admin@example.com \
  --http-listen http://stepca.172-31-97-7.sslip.io:9000 \
  --root /home/step/certs/root_ca.crt \
  --san "172-31-97-7.sslip.io" \
  --san "stepca.172-31-97-7.sslip.io" \
  --san "*.knative.172-31-97-7.sslip.io" \
  --san "*.default.knative.172-31-97-7.sslip.io" \
  --san "*.default.grpcs.knative.172-31-97-7.sslip.io" \
  --provisioner-password-file /home/step/secrets/password



# 連鎖順は重要
# wild.platform.localtest.me.crt（サーバー証明書リーフ）-> intermediate_ca.crt（中間CA）の順で連結。
# クライアントは、leaf → intermediate → root の連鎖を検証する（rootはクライアントに導入済みの前提）
docker compose exec stepca sh -c "cat /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/intermediate_ca.crt > /home/step/certs/fullchain.wild.platform.localtest.me.crt"
