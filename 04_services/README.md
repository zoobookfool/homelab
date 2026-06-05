# 04 Services

Docker Compose で各サービスを起動します。
使いたいサービスだけを選んで起動できます。

---

## 前提条件

[03_docker](../03_docker/README.md) が完了していること。

### サービスごとの前提条件

| サービス | ドメイン | 外部SMTP | 特記事項 |
|---|---|---|---|
| 監視ダッシュボード | 任意 | 不要 | ドメインなしでも Tailscale 経由でアクセス可 |
| Mastodon | **必須・後から変更不可** | **必須** | ActivityPub のため |
| Element | **必須・後から変更不可** | 不要 | Matrix フェデレーションのため |
| Discord Bot | 不要 | 不要 | Discord Developer Portal でトークン取得が必要 |
| ローカル AI 踏み台 | 任意 | 不要 | 自宅 PC で Ollama 等が起動していること |
| Factorio | 不要 | 不要 | UDP 34197 の開放が必要（踏み台 or アプリサーバ） |
| Windrose（UE5） | 不要 | 不要 | UDP 7777 の開放・Dedicated Server バイナリが必要（踏み台 or アプリサーバ） |

---

## .env の設定

`.env.example` をコピーして `.env` を作成し、**起動するサービスに必要な項目だけ**設定します。
`.env` は **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cp .env.example .env
```

---

## 使いたいサービスを選んで構築する

### 1. 起動するサービスを決める

上の前提条件テーブルを確認し、起動するサービスを決めます。

### 2. .env に必要な項目を設定する

`.env` を開き、起動するサービスに対応するセクションの項目を埋めます。
**起動しないサービスの項目は空欄のままで構いません。**

例：監視ダッシュボードだけ起動する場合に必要な設定：

```bash
DOMAIN=example.com
TZ=Asia/Tokyo
GRAFANA_ADMIN_PASSWORD=<任意のパスワード>
```

### 3. サービスを起動する

```bash
make up-monitoring
```

### 4. 外部公開の設定をする（外部公開する場合）

構成パターンに応じて次の手順に進みます。

| パターン | 次の手順 |
|---|---|
| パターンA（踏み台なし） | [05_nginx](../05_nginx/README.md)：アプリサーバに Nginx を直接設定する |
| パターンB（踏み台あり） | [05_vps](../05_vps/README.md)：踏み台サーバに Nginx を設定する |

外部公開しない場合（監視・Discord Bot・AI 踏み台のみ）は 05 の手順は不要です。

---

## 起動コマンド一覧

```bash
# 個別に起動
make up-monitoring       # 監視ダッシュボード
make up-mastodon         # Mastodon
make up-element          # Element
make up-discord-bot      # Discord Bot
make up-ai-proxy         # ローカル AI 踏み台
make up-game-factorio    # Factorio サーバ
make up-game-windrose    # Windrose（UE5）サーバ

# 常時起動サービスをまとめて起動
make up-core

# すべて起動
make up-all

# 個別に停止
make down-monitoring
make down-mastodon
# ... など

# すべて停止
make down

# ログを確認
make logs-mastodon
make logs-monitoring
# ... など
```

---

## 初回起動時の追加手順

### Mastodon

データベースのセットアップ：

```bash
make up-mastodon
docker compose -f compose/mastodon.yml run --rm web bundle exec rails db:setup
```

管理者アカウントの作成：

```bash
docker compose -f compose/mastodon.yml run --rm web bin/tootctl accounts create \
  <ユーザー名> --email <メールアドレス> --confirmed --role Owner
```

### Element（Matrix Synapse）

設定ファイルの生成：

```bash
docker compose -f compose/element.yml run --rm synapse generate
```

生成された `services/element/homeserver.yaml` を編集してから起動します。

---

## データの保存場所

すべてのサービスデータはホストの `/opt/homelab/` 以下に保存されます。

```
/opt/homelab/
├── mastodon/
├── monitoring/
├── element/
├── discord_bot/
└── game/
    ├── factorio/
    └── windrose/
```

---

## 次の手順

- パターンA（踏み台なし）で外部公開する → [05_nginx](../05_nginx/README.md)
- パターンB（踏み台あり）で外部公開する → [05_vps](../05_vps/README.md)
- 外部公開しない → [06_backup](../06_backup/README.md)
