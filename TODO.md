# TODO

* [x] : https 化
    * linux 環境
        * [x] : SSL 検証の成功
        * [x] : http2 確認
    * Windows 環境
        * [x] : SSL 検証の成功
        * [x] : Chrome での http/2 確認
        * [ ] : Curl での http/2 確認（http1.1 しか対応していない）
    * [ ] : http1.1 確認（一般的に http2 に未対応のクライアントもまだあるので、http1.1を用意した方がいいらしい）
* [ ] : SSO
* [ ] : デバイス管理
* [ ] : token exchange
* [ ] : localtest から sslip への移行
  * [ ]: localtet では、あるホストから localtest を参照した時に、127.0.0.1 で解決されるため、別のホストを参照できない
