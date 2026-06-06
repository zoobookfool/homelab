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

## 1. inventory ファイルの作成

`04_services/ansible/inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 04_services/ansible/inventory.ini << 'EOF'
[app]
<アプリサーバのTailscale IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

---

## 2. サービスファイルをサーバにデプロイ

Ansible でサーバに compose ファイル・設定ファイルを転送し、`.env` を作成します。

```bash
ansible-playbook -i 04_services/ansible/inventory.ini 04_services/ansible/playbook.yml \
  -e "grafana_admin_password=<Grafanaのパスワード>"
```

デプロイされるディレクトリ（サーバ上）：

```
/opt/homelab/
├── compose/         # Docker Compose ファイル
├── services/        # サービス設定ファイル
├── Makefile
├── .env             # 環境変数（.env.example から自動生成）
└── monitoring/      # データディレクトリ（自動作成）
    ├── prometheus/
    └── grafana/
```

---

## 3. .env の設定

デプロイ後、サーバの `/opt/homelab/.env` を編集して**起動するサービスに必要な項目だけ**設定します。
`.env` は **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<TailscaleのIP>
vi /opt/homelab/.env
```

起動するサービスに対応するセクションの項目を埋めます。**起動しないサービスの項目は空欄のままで構いません。**

例：監視ダッシュボードだけ起動する場合に必要な設定：

```
DOMAIN=example.com
TZ=Asia/Tokyo
GRAFANA_ADMIN_PASSWORD=<デプロイ時に設定済み>
```

---

## 4. サービスを起動する

### Ansible で起動する（推奨）

```bash
# 監視ダッシュボード
ansible-playbook -i 04_services/ansible/inventory.ini 04_services/ansible/playbook_monitoring.yml
```

### SSH 接続して直接起動する

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<TailscaleのIP>
cd /opt/homelab
make up-monitoring
```

---

## 5. 外部公開の設定をする（外部公開する場合）

構成パターンに応じて次の手順に進みます。

| パターン | 次の手順 |
|---|---|
| パターンA（踏み台なし） | [05_nginx](../05_nginx/README.md)：アプリサーバに Nginx を直接設定する |
| パターンB（踏み台あり） | [05_relay](../05_relay/README.md)：踏み台サーバに Nginx を設定する |

外部公開しない場合（監視・Discord Bot・AI 踏み台のみ）は 05 の手順は不要です。

---

## 起動コマンド一覧

> サーバに SSH 接続し、`/opt/homelab` で実行します。

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

### Factorio

起動後、`/opt/homelab/game/factorio/` にサーバ設定ファイルが自動生成されます。

```
/opt/homelab/game/factorio/
├── config/
│   └── server-settings.json   # サーバ名・説明・パスワード・公開設定など
├── saves/                     # セーブデータ
└── mods/                      # MOD（任意）
```

`server-settings.json` を編集してサーバ名やパスワードを設定した後、コンテナを再起動します：

```bash
make down-game-factorio
make up-game-factorio
```

**接続方法（友人への共有）：**

| 方法 | 手順 |
|---|---|
| 直接接続 | Factorio → マルチプレイヤー → 直接接続 → `<サーバのIP>:34197` |
| サーバリスト | `server-settings.json` の `visibility.public` を `true` にして公開 |

> UDP 34197 のポート開放が必要です（踏み台 or アプリサーバのファイアウォール）。

### Windrose（UE5）

起動に 1〜2 分かかります。`R5/ServerDescription.json` が生成されれば起動完了です。

```bash
# サーバが起動するまで待ってから招待コードを確認
docker exec windrose cat /server/R5/ServerDescription.json
```

`InviteCode` の値（例: `9192a58a`）を友人に共有します。

**接続方法（友人への共有）：**

1. 友人が Windrose を起動
2. **Play → Connect to Server** で招待コードを入力

> デフォルト設定（`UseDirectConnection: false`）では P2P/ICE 接続のためポート開放不要です。
> 直接接続を使う場合は `ServerDescription.json` で `UseDirectConnection: true` に変更し、UDP+TCP 7777 を開放してください。

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
- パターンB（踏み台あり）で外部公開する → [05_relay](../05_relay/README.md)
- 外部公開しない → [06_backup](../06_backup/README.md)
