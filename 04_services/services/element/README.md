# Element（Matrix Synapse）

Matrix プロトコルのホームサーバ（Synapse）と Web クライアント（Element）です。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 2コア以上 |
| RAM | 2GB 以上 |
| ポート | TCP 443（HTTPS） |
| ドメイン | **必須・後から変更不可**（Matrix ID に使用） |
| 外部 SMTP | 不要 |

> ⚠️ ドメインは一度決めたら変更できません。よく検討してから設定してください。

---

## 起動方法

### 1. 設定ファイルの生成

```bash
docker compose -f compose/element.yml run --rm synapse generate
```

生成された `services/element/homeserver.yaml` を確認・編集します。

### 2. 起動

```bash
make up-element
```

---

## 外部公開

[05_relay](../../../../05_relay/README.md) で Nginx リバースプロキシを設定してください。
Matrix フェデレーション（他のサーバと通信）には `matrix.<ドメイン名>` が必要です。

```
Element Web:        https://element.<ドメイン名>
Matrix サーバ:      https://matrix.<ドメイン名>
```

---

## ユーザー登録

デフォルトでは外部からの登録を無効化しています。
管理者が手動でアカウントを作成します。

```bash
docker exec -it synapse register_new_matrix_user \
  -u <ユーザー名> -p <パスワード> -a \
  -c /data/homeserver.yaml http://localhost:8008
```
