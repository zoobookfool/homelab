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

> 💡 以下のように `compose/` 配下のファイルを直接指定するコマンドは `--env-file .env` を付けて
> `/opt/homelab` から実行してください（`-f` で指定したファイルのディレクトリがプロジェクトディレクトリと
> 認識され、`.env` が見つからず変数展開に失敗するため。`make` コマンドには同様の対策が組み込み済みです）。

### 1. 環境変数を設定

`/opt/homelab/.env` に以下を設定します。

```
DOMAIN=example.com
MASTODON_DB_PASSWORD=<ランダムな文字列>
MASTODON_SECRET_KEY_BASE=<ランダムな文字列（64文字以上）>
MASTODON_OTP_SECRET=<ランダムな文字列（64文字以上・SECRET_KEY_BASEとは別の値）>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<ランダムな文字列（3つとも別の値）>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<同上>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<同上>
MASTODON_VAPID_PRIVATE_KEY=<rake mastodon:webpush:generate_vapid_key で生成>
MASTODON_VAPID_PUBLIC_KEY=<rake mastodon:webpush:generate_vapid_key で生成>
MASTODON_SMTP_SERVER=<SMTPサーバ>
MASTODON_SMTP_PORT=587
MASTODON_SMTP_LOGIN=<SMTPユーザー名>
MASTODON_SMTP_PASSWORD=<SMTPパスワード>
MASTODON_SMTP_FROM_ADDRESS=noreply@example.com

# 踏み台/リレー経由で公開する場合のみ（後述「外部公開」を参照）
TRUSTED_PROXY_IP=<リレーサーバのTailscale IP>
```

> 💡 `DOMAIN` は他サービス（Grafana 等）とも共有するベースドメインです（例: `example.com`）。
> Mastodon 自体は `mastodon.<DOMAIN>` で公開され、`LOCAL_DOMAIN`（連合・アカウント ID に使う値）も
> 自動的に `mastodon.<DOMAIN>` になるよう `compose/mastodon.yml` 側で設定済みです。
> **`LOCAL_DOMAIN` は一度サーバを起動すると変更できない**ため、公開用 URL（[03_proxy](../../../../03_proxy/README.md) で設定する `mastodon.<ドメイン>`）と必ず一致させる必要があります。

> ⚠️ **`SECRET_KEY_BASE` / `OTP_SECRET` / `ACTIVE_RECORD_ENCRYPTION_*` は、コンテナを起動する前に値を設定してください。**
> 公式に案内される生成コマンド（`rake secret`、`rails db:encryption:init`）はいずれも Rails の起動
> （＝有効な `SECRET_KEY_BASE`）を必要とするため、これらが未設定のまま `make up-mastodon` してから
> 生成しようとすると「コンテナが起動できない → 生成コマンドも実行できない」という鶏と卵の状態に陥ります。
> `openssl` で同等の値を、コンテナを起動せずに生成できます（実行結果は他人に見せず、変数ごとに別の値を生成すること）。
> ```bash
> openssl rand -hex 64
> ```
>
> VAPID キーペアは逆に Rails の起動が必要なため、`make up-mastodon` で正常に起動した**後**に生成してください
> （[2. データベースのセットアップ](#2-データベースのセットアップ)を参照）。
> ```bash
> docker compose --env-file .env -f compose/mastodon.yml run --rm mastodon-web bundle exec rake mastodon:webpush:generate_vapid_key
> ```
> 生成した値を `.env` に追記したら、コンテナを再作成して反映します。
> ```bash
> docker compose --env-file .env -f compose/mastodon.yml up -d --force-recreate mastodon-web mastodon-sidekiq
> ```

### 2. データベースのセットアップ

```bash
make up-mastodon
docker compose --env-file .env -f compose/mastodon.yml run --rm mastodon-web bundle exec rails db:setup
```

### 3. 管理者アカウントの作成

```bash
docker compose --env-file .env -f compose/mastodon.yml run --rm mastodon-web bin/tootctl accounts create \
  <ユーザー名> --email <メールアドレス> --confirmed --role Owner
```

> ⚠️ 登録を承認制にしている場合（デフォルト）、上記コマンドは「メール確認済み」状態とロールを設定しますが、
> **承認（approved）状態にはなりません**。そのままだと、作成した管理者アカウント自身が
> 「サーバ管理者による審査待ち」のままログイン後の操作がほぼ全てブロックされ、かつ承認できる他の管理者もいない
> という詰み状態になります。続けて以下を実行し、自分自身を承認してください。
> ```bash
> docker compose --env-file .env -f compose/mastodon.yml run --rm mastodon-web bin/tootctl accounts approve <ユーザー名>
> ```
> 反映後はページを再読み込み（変化がなければ再ログイン）すると、承認待ちのバナーが消え管理メニューが表示されます。

---

## 外部公開

[03_proxy](../../../../03_proxy/README.md) で Nginx リバースプロキシを設定してください。

```
https://mastodon.<ドメイン名>
```

ActivityPub フェデレーション（他のサーバと繋がる機能）はドメインが必須です。

> ⚠️ 踏み台/リレーサーバ経由で公開する構成（[03_proxy](../../../../03_proxy/README.md)）の場合、
> ログインしようとすると「We're sorry, but something went wrong on our end」という 500 エラーになることがあります。
> ログに `ActionDispatch::RemoteIp::IpSpoofAttackError (IP spoofing attack?! client <IP> is not a trusted proxy ...)`
> が出ていれば、リレーサーバの IP が Rails の信頼済みプロキシ一覧に無いことが原因です。
> `.env` に `TRUSTED_PROXY_IP=<リレーサーバのTailscale IP>` を設定してコンテナを再作成すれば解消します
> （`compose/mastodon.yml` の `env_file` 経由でそのまま渡る変数のため、compose ファイルの編集は不要です）。
> ```bash
> docker compose --env-file .env -f compose/mastodon.yml up -d --force-recreate mastodon-web mastodon-sidekiq
> ```
