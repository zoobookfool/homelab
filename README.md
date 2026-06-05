# homelab

Docker Compose と Ansible を使ったホームサーバ構築リポジトリです。
使いたいサービスだけを選んで環境構築できます。

> このリポジトリの目的・設計意図については [docs/portfolio.md](./docs/portfolio.md) を参照してください。
> 自分用の環境管理手順については [docs/self_management.md](./docs/self_management.md) を参照してください。

---

## 構成パターンを選ぶ

まず、どのサーバ構成で構築するかを決めます。

### パターンA: 踏み台なし

アプリサーバ（VPS / AWS）が直接外部に公開されるシンプルな構成です。

```
インターネット → アプリサーバ（VPS / AWS）
```

### パターンB: 踏み台あり

踏み台サーバ（VPS / AWS）がリバースプロキシ・UDP リレーを担い、アプリサーバの IP を隠す構成です。
**自宅サーバをアプリサーバとして使う場合は B 一択です。**

```
インターネット → 踏み台（VPS / AWS）→ アプリサーバ（VPS / AWS / 自宅サーバ）
```

### どちらを選ぶ？

```
自宅サーバを使う               → B（必須）

VPS / AWS のみ
  アプリサーバの IP を隠したい  → B
  シンプルに構築したい          → A
```

---

## ハードウェア要件

### アプリサーバ

| サービス | 最小スペック |
|---|---|
| 監視ダッシュボード・Discord Bot・AI 踏み台 | 1コア / RAM 1GB |
| Mastodon | 2コア / RAM 2GB |
| Element | 2コア / RAM 2GB |
| Factorio | 2コア / RAM 2GB |
| Windrose（UE5） | 4コア / RAM 8GB |

複数サービスを同一サーバで動かす場合はスペックを合算してください。

### 踏み台（パターンB のみ）

1コア / RAM 512MB〜1GB（Nginx のみを動かすため軽量）

---

## サービス一覧と前提条件

| サービス | ドメイン | 外部SMTP | 特記事項 |
|---|---|---|---|
| 監視ダッシュボード | 任意 | 不要 | ドメインなしでも Tailscale 経由でアクセス可 |
| Mastodon | **必須・後から変更不可** | **必須** | ActivityPub のため |
| Element | **必須・後から変更不可** | 不要 | Matrix フェデレーションのため |
| Discord Bot | 不要 | 不要 | Discord Developer Portal でトークン取得が必要 |
| ローカル AI 踏み台 | 任意 | 不要 | 自宅 PC で Ollama 等が起動していること |
| Factorio | 不要 | 不要 | UDP 34197 の開放が必要（踏み台 or アプリサーバ） |
| Windrose（UE5） | 不要 | 不要 | UDP 7777 の開放・Dedicated Server バイナリが必要 |

---

## 共通の前提条件

以下が整っている状態から手順が始まります。

- アプリサーバに Ubuntu Server 26.04 LTS がインストール済みであること
- パターンB の場合は踏み台サーバにも Ubuntu Server 26.04 LTS がインストール済みであること
- Tailscale アカウントを取得済みであること（https://tailscale.com）
- 操作端末に Git・WSL2・Ansible がインストール済みであること
- Mastodon・Element を使う場合はドメインを取得済みであること

---

## 構築手順

手順は番号順に実行します。パターンによって 05 の要否が変わります。

| 手順 | 内容 | パターンA | パターンB |
|---|---|---|---|
| [01_initial_setup](./01_initial_setup/README.md) | OS 初期設定・SSH・UFW | ○ | ○（アプリサーバ） |
| [02_tailscale](./02_tailscale/README.md) | Tailscale 導入・UFW ロックダウン | ○ | ○（アプリサーバ） |
| [03_docker](./03_docker/README.md) | Docker・Docker Compose 導入 | ○ | ○ |
| [04_services](./04_services/README.md) | サービスの起動 | ○ | ○ |
| [05_vps](./05_vps/README.md) | 踏み台の Nginx・UFW 設定 | — | ○（踏み台サーバ） |

> `06_backup` はバックアップ設定です。運用開始後に設定してください。

---

## サービスの起動

`04_services/` に移動して `make` コマンドで起動します。

```bash
cd 04_services

# 使いたいサービスだけ起動
make up-monitoring
make up-mastodon
make up-element
make up-discord-bot
make up-ai-proxy
make up-game-factorio
make up-game-windrose

# すべて停止
make down
```

サービスごとの詳細・初回設定手順は [04_services/README.md](./04_services/README.md) を参照してください。

---

## 秘匿情報の管理

以下のファイルは `.gitignore` で除外されています。各手順の README を参照して作成してください。

| ファイル | 内容 |
|---|---|
| `*/ansible/inventory.ini` | サーバの IP アドレス・ユーザー名 |
| `04_services/.env` | ドメイン名・パスワード等 |
| `~/.ssh/id_ed25519_homelab` | サーバ接続用 SSH 秘密鍵 |

---

## ライセンス

MIT
