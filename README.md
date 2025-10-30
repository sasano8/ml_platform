# Getting Started

## 前提ツールの導入

gomplate をインストールする。

```
sudo ./tools/download_gomplate.sh $(python3 tools/get_osinfo.py)
```

## knative の起動

衝突しないネットワーク範囲を探す

```
docker network inspect -f '{{.Name}} {{range .IPAM.Config}}{{.Subnet}} {{end}}' $(docker network ls -q)
```

docker-compose.yml に埋め込む変数を生成します。

```
python3 tools/conf_generate.py --external_host 172.30.0.2 > .env.json
```

k0s + knative の起動とセットアップを行います。

```
make k0s-up
```

kservice の疎通確認を行うので以下の応答例を参考に、HTTP ステータス 200 が返り、`Hello Edge!!!` の応答を確認してください。

```
* Connected to hello-kservice.default.172-30-0-2.sslip.io (172.30.0.2) port 30080
* using HTTP/1.x
> GET / HTTP/1.1
HTTP/1.1 200 OK
Hello Edge!!!
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
https://hello-knative.default.knative.platform.localtest.me
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
