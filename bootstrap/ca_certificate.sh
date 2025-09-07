#!/bin/sh

set -e

docker compose up -d step-ca

sleep 5

docker compose exec step-ca step ca certificate \
  "*.platform.localtest.me" /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/wild.platform.localtest.me.key \
  --provisioner admin@example.com \
  --http-listen http://localhost:9000 \
  --root /home/step/certs/root_ca.crt \
  --san "*.platform.localtest.me" \
  --provisioner-password-file /home/step/secrets/password

#  --san platform.localtest.me \

# docker compose exec step-ca step ca certificate \
#   "localtest.me" /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/wild.platform.localtest.me.key \
#   --provisioner admin@example.com \
#   --http-listen http://localhost:9000 \
#   --root /home/step/certs/root_ca.crt \
#   --san "ca.localtest.me" \
#   --san "auth.localtest.me" \
#   --san "platform.localtest.me" \
#   --san "*.platform.localtest.me" \
#   --provisioner-password-file /home/step/secrets/password


# はじめに ca.localtest.me.crt を列挙する
docker compose exec step-ca sh -c "cat /home/step/certs/wild.platform.localtest.me.crt /home/step/certs/intermediate_ca.crt > /home/step/certs/fullchain.wild.platform.localtest.me.crt"
