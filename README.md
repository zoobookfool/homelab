# homelab

Docker Compose と Ansible を使ったホームサーバ構築リポジトリです。
使いたいサービスだけを選んで環境構築できます。

> このリポジトリの目的・設計意図については [docs/portfolio.md](./docs/portfolio.md) を参照してください。
> 自分用の環境管理手順については [docs/self_management.md](./docs/self_management.md) を参照してください。

---

## サービス一覧と前提条件

| サービス | ドメイン | 外部SMTP | 特記事項 |
|---|---|---|---|
| 監視ダッシュボード | 任意 | 不要 | ドメインなしでも Tailscale 経由でアクセス可 |
| Mastodon | **必須・後から変更不可** | **必須** | ActivityPub のため |
| Element | **必須・後から変更不可** | 不要 | Matrix フェデレーションのため |
| Discord Bot | 不要 | 不要 | Discord Developer Portal でトークン取得が必要 |
| ローカル AI 踏み台 | 任意 | 不要 | 自宅 PC で Ollama 等が起動していること |
| Factorio | 不要 | 不要 | VPS で UDP 34197 の開放が必要 |
| Windrose（UE5） | 不要 | 不要 | VPS で UDP 7777 の開放・Dedicated Server バイナリが必要 |

---

## 共通の前提条件

- Ubuntu Server 26.04 LTS がインストール済みのサーバがあること
- VPS（ConoHa 1コア・RAM 1GB 以上）があること
- Tailscale アカウントを取得済みであること（https://tailscale.com）
- 操作端末に Git・WSL2・Ansible がインストール済みであること
- Mastodon・Element を使う場合はドメインを取得済みであること

---

## 構築手順

手順は番号順に実行します。

| 手順 | 内容 |
|---|---|
| [01_initial_setup](./01_initial_setup/README.md) | OS 初期設定・SSH・UFW |
| [02_tailscale](./02_tailscale/README.md) | Tailscale 導入・UFW ロックダウン |
| [03_docker](./03_docker/README.md) | Docker・Docker Compose 導入 |
| [04_services](./04_services/README.md) | サービスの起動 |
| [05_vps](./05_vps/README.md) | VPS の Nginx・UFW 設定 |

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
