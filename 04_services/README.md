# 04 Services

Docker Compose で各サービスを起動します。

---

## 前提条件

- [03_docker](../03_docker/README.md) が完了していること
- `.env` ファイルを作成済みであること（→ [.env の設定](#env-の設定)）
- 自宅 PC が Tailscale に接続済みであること

---

## .env の設定

`.env.example` をコピーして `.env` を作成し、各値を設定します。
`.env` は **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cp .env.example .env
```

エディタで `.env` を開いて各値を設定してください。
設定項目の詳細は `.env.example` のコメントを参照してください。

---

## サービス一覧

| サービス | ドメイン例 | 起動コマンド |
|---|---|---|
| 監視ダッシュボード | `monitoring.example.com` | `make up-monitoring` |
| Mastodon | `mastodon.example.com` | `make up-mastodon` |
| Element | `element.example.com` | `make up-element` |
| Discord Bot | - | `make up-discord-bot` |
| ローカル AI 踏み台 | `ai.example.com` | `make up-ai-proxy` |
| Factorio サーバ | - | `make up-game-factorio` |
| Windrose（UE5） | - | `make up-game-windrose` |

---

## 起動コマンド一覧

```bash
# 常時起動サービスをまとめて起動
make up-core

# サービスを個別に起動
make up-monitoring
make up-mastodon
make up-element
make up-discord-bot
make up-ai-proxy
make up-game-factorio
make up-game-windrose

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

## 初回起動時の注意

### Mastodon

初回のみデータベースのセットアップが必要です。

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

初回のみ設定ファイルの生成が必要です。

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

> 💡 バックアップ対象は `/opt/homelab/` 以下です。
> 詳細は [06_backup](../06_backup/README.md) を参照してください。

---

## 次の手順

→ [05_vps](../05_vps/README.md)
