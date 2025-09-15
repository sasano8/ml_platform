

* http://auth.localtest.me/signup/setup
* http://localtest.me:8001: Kong Admin Api
* http://console.localtest.me: Minio UI
* http://s3.localtest.me: Minio API


# はじめに

https://auth.localtest.me/signup/setup


curl -v --http2 --insecure https://ca.localtest.me/



# 環境構築

## .env の作成

./bootstrap/env_init.sh

## docker-compose.override.yml の作成

必要に応じて docker-compose.override.yml を作成してください。
