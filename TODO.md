# TODO

* [x] : https 化
    * linux 環境
        * [x] : SSL 検証の成功
        * [x] : http2 確認
        * [x] : *default.apps.platform.localtest.me 領域の https 化
        * [x] : nginx を経由した websocket への Upgrade
        * [x] : kong を経由した websocket への Upgrade
        * [x] : websocketking.com を経由した websocket への接続（ブラウザは wss でないと接続を許可しない）
        * [x] : grpc 接続（コンテナに直接 plaintext）
        * [x] : grpc 接続（kong 経由で接続）
        * [ ] : grpc, https 両対応（現状は ingress, nginx で httpsかgrpcsか切り替えて、どちらかしか有効にならない
          * nginx での if は難あり
          * kind: Gateway を使うと両対応できるかもしれない。ingress は HTTPS or GRPCS なのでどうにもならない
          * そんなことより kourier とか使った方がいい
    * Windows 環境
        * [x] : SSL 検証の成功
        * [x] : Chrome での http/2 確認
        * [ ] : Curl での http/2 確認（http1.1 しか対応していない）
    * [ ] : http1.1 確認（一般的に http2 に未対応のクライアントもまだあるので、http1.1を用意した方がいいらしい）
* http 最適化
  * [ ] : バッファーを無効化しパススルーのように動作させる
  * [ ] : nginx-svc にリクエストを投げると nginx-svc 宛に転送されるため無限ループする。対処を考える。
* kubernetes 連携
  * [x] : docker で動かせる kubernetes 構築
    * [x] : k0s（その他候補: k3s, k3d(k3s のラッパー)）
  * [x] : kubernetes 用のワイルドカードドメインサービスの構築
* [ ] : SSO
* [ ] : デバイス管理
* [ ] : token exchange
* [ ] : localtest から sslip への移行
  * [ ]: localtet では、あるホストから localtest を参照した時に、127.0.0.1 で解決されるため、別のホストを参照できない
