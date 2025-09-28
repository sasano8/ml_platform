# TODO

* [x] : https 化
    * linux 環境
        * [x] : SSL 検証の成功
        * [x] : http2 確認
        * [ ] : *default.apps.platform.localtest.me 領域の https 化
        * [x] : grpc 接続（コンテナに直接 plaintext）
        * [ ] : grpc 接続（kong 経由で plaintext などで接続）
    * Windows 環境
        * [x] : SSL 検証の成功
        * [x] : Chrome での http/2 確認
        * [ ] : Curl での http/2 確認（http1.1 しか対応していない）
    * [ ] : http1.1 確認（一般的に http2 に未対応のクライアントもまだあるので、http1.1を用意した方がいいらしい）
* kubernetes 連携
  * [x] : docker で動かせる kubernetes 構築
    * [x] : k0s（その他候補: k3s, k3d(k3s のラッパー)）
  * [x] : kubernetes 用のワイルドカードドメインサービスの構築
* [ ] : SSO
* [ ] : デバイス管理
* [ ] : token exchange
* [ ] : localtest から sslip への移行
  * [ ]: localtet では、あるホストから localtest を参照した時に、127.0.0.1 で解決されるため、別のホストを参照できない
