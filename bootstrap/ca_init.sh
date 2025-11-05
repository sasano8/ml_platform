#!/bin/sh

set -e

# パスワードファイル生成
mkdir -p $PWD/volumes/step/secrets
openssl rand -base64 32 > $PWD/volumes/step/secrets/password

# アプリケーション構成ファイルの出力と、./volumes/step 配下に root_ca.crt を出力する
python3 -m tools ca_init

# # 元ファイルの所有権のままroot領域に格納
sudo cp -p ./volumes/step/certs/root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
sudo update-ca-certificates  # /etc/ssl/certs/ca-certificates.crt に出力される（curl はここを読むが、httpx などは読まない）

WSLPATH=$(wslpath -w "$PWD/volumes/step/certs")

echo "Please add root_ca.crt to windows. Windows + R -> certmgr.msc"
printf '%s\n' "${WSLPATH}"  # make 経由だと\が制御文字と認識されてしまうので、printf を使う
