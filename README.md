# Getting Started

## 前提ツールの導入

gomplate をインストールする。

```
sudo ./tools/download_gomplate.sh $(python3 tools/get_osinfo.py)
```

## ネットワークの構築

```
WSL_IP=$(ip -4 addr show eth0 | awk '/inet /{print $2}' | cut -d/ -f1)
EXTERNAL_BASE_DOMAIN=$WSL_IP.sslip.io

WSL_NETWORK=$(ip -4 addr show eth0 | awk '/inet /{print $2}')
echo "command = ip link add br01 type bridge & ip addr add $WSL_NETWORK dev br01 & ip link set br01 up"
```

`/etc/wsl.conf` でWSL に固定IP を振ります。
`wsl.conf` は各ディストリビューション（コンテナ）毎に適用されます。

```
[boot]
command = ip link add br01 type bridge & ip addr add 10.2.0.3/16 dev br01 & ip link set br01 up
```

docker ネットワークを作成する。
これは kubernetes ノード（コンテナ）に固定ip を割り当てるためです（ip が変わるとubernetes ノードは起動しません）。

```
--subnet 10.23.0.0/16
docker network create --driver bridge fixed_compose_network
read -r SUBNET GATEWAY < <(docker network inspect fixed_compose_network | jq -r '.[0].IPAM.Config[0] | "\(.Subnet) \(.Gateway)"')
echo $SUBNET $GATEWAY
docker network rm fixed_compose_network

# subnet, gateway を固定しておかないと compose を実行できない
docker network create --driver bridge --subnet $SUBNET --gateway $GATEWAY fixed_compose_network
docker network inspect fixed_compose_network
```

構成ファイルを生成する。

```
python3 tools init --network fixed_compose_network --driver bridge --subnet $SUBNET --gateway $GATEWAY  --external_base_domain $EXTERNAL_BASE_DOMAIN --uid $(id -u) --gid $(id -g)
```

## knative の起動

ボリュームを作成します。

```
docker volume create platform-k0s
```

構成ファイルで動的に算出する部分を更新します。

```
python3 tools calculate
```

k0s + knative の起動とセットアップを行います。
初回は時間がかかったりフリーズしたりします。

その場合は Ctrl + C で停止し、再実行してください（何度実行しても同じ結果になるようになっています）。

```
make k0s-up
```

以下の応答例を参考に、疎通結果を確認してください。

```
Waiting for route to accept traffic at Host: hello-ksvc-http.default.172-31-97-7.sslip.io http://localhost:30080
Hello Edge!!!
```

```
Waiting for route to accept traffic at Host: hello-ksvc-grpc.default.172-31-97-7.sslip.io http://localhost:30080
hello.HelloService
```

## kong の起動






# Getting Started

`.env` を生成し、必要に応じて値を編集します。

```
make platform-configurate
```

アプリケーション実行基盤(knative)をセットアップします。

```
make container-build
```


platform を構築します。
`update-ca-certificates` が実行されるため、sudo パスワードを入力します。

```
make platform-recreate
```

Windows 環境の場合、Windows で証明書登録作業を行います。

* 証明書は、`Localhost Root CA` として登録されます。
* 別の `Localhost Root CA` が登録されている場合、`Windows + R` -> `certmgr.msc` で証明書マネージャーを開き、該当の証明書を削除します。


WSL の場合は、以下のようにディレクトリを開きます。

```
explorer.exe "$(wslpath -w "$PWD/volumes/step/certs")"
```

`root_ca.crt` をダブルクリックし、証明書のインストールをします。
証明書は、信頼されたルート証明機関に配置します。


ブラウザから以下のURLから hello が返ることを確認します。

```
https://hello-ksvc-http.default.knative.172-31-97-7.sslip.io/
```


Powershell から以下のコマンドを実行し、http 200 が返ることを確認します。

```
curl https://ca.platform.localtest.me/health
curl https://auth.platform.localtest.me/.well-known/openid-configuration 
curl https://console.platform.localtest.me/api/v1/login
curl https://s3.platform.localtest.me/minio/health/ready
```


# メモ

WSL のアドレスを抽出し、sslip のドメインを組み立てる（env_init.sh に定義済み）。

```
echo $(hostname -I | awk '{print $1}' | tr . -).sslip.io
```

```
http://172-31-97-7.sslip.io:8001/
```

sslip はワイルドカード証明書の発行が少し難しいらしい。



* https://s3.platform.localtest.me/
* https://ca.platform.localtest.me/
* https://auth.platform.localtest.me/

* https://ca.platform.localtest.me/
* https://auth.platform.localtest.me/signup/setup
* https://platform.localtest.me:8001: Kong Admin Api
* https://console.platform.localtest.me: Minio UI
* https://s3.platform.localtest.me: Minio API

# はじめに

https://auth.localtest.me/signup/setup


curl -v --http2 --insecure https://ca.localtest.me/



# 環境構築

## .env の作成

./bootstrap/env_init.sh

## docker-compose.override.yml の作成

必要に応じて docker-compose.override.yml を作成してください。
