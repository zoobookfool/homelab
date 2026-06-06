# Mastodon

分散型 SNS Mastodon の自己ホストサーバです。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 2コア以上 |
| RAM | 2GB 以上 |
| ポート | TCP 443（HTTPS） |
| ドメイン | **必須・後から変更不可**（アカウント ID に使用） |
| 外部 SMTP | **必須**（メール認証に使用） |

> ⚠️ ドメインは一度決めたら変更できません。よく検討してから設定してください。

---

## 起動方法

### 1. 環境変数を設定

`/opt/homelab/.env` に以下を設定します。

```
DOMAIN=mastodon.example.com
MASTODON_DB_PASSWORD=<ランダムな文字列>
MASTODON_SECRET_KEY_BASE=<ランダムな文字列（64文字以上）>
MASTODON_OTP_SECRET=<ランダムな文字列（64文字以上）>
MASTODON_SMTP_SERVER=<SMTPサーバ>
MASTODON_SMTP_PORT=587
MASTODON_SMTP_LOGIN=<SMTPユーザー名>
MASTODON_SMTP_PASSWORD=<SMTPパスワード>
MASTODON_SMTP_FROM_ADDRESS=noreply@example.com
```

### 2. データベースのセットアップ

```bash
make up-mastodon
docker compose -f compose/mastodon.yml run --rm web bundle exec rails db:setup
```

### 3. 管理者アカウントの作成

```bash
docker compose -f compose/mastodon.yml run --rm web bin/tootctl accounts create \
  <ユーザー名> --email <メールアドレス> --confirmed --role Owner
```

---

## 外部公開

[05_relay](../../../../05_relay/README.md) で Nginx リバースプロキシを設定してください。

```
https://mastodon.<ドメイン名>
```

ActivityPub フェデレーション（他のサーバと繋がる機能）はドメインが必須です。
