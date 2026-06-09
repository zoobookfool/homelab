# homelab

Docker Compose と Ansible を使ったホームサーバ構築リポジトリです。
使いたいサービスだけを選んで環境構築できます。

> このリポジトリの目的・設計意図については [docs/portfolio.md](./docs/portfolio.md) を参照してください。

---

## 構成パターン

### パターンA: アプリサーバのみ

```
インターネット → アプリサーバ（VPS / AWS）
```

アプリサーバが直接外部に公開されるシンプルな構成です。

### パターンB: アプリサーバ + 踏み台サーバ

```
インターネット → 踏み台（VPS / AWS）→ アプリサーバ（VPS / AWS / 自宅サーバ）
```

踏み台サーバがリバースプロキシ・UDP リレーを担い、アプリサーバの IP を隠せます。

**どちらを選ぶ？**

```
自宅サーバを使う / IP を隠したい  →  B
VPS / AWS のみ・シンプルに構築    →  A
```

---

## サービス一覧

| サービス | compose ファイル | ドメイン | 外部SMTP | **最小**スペック |
|---|---|---|---|---|
| 監視ダッシュボード | `monitoring.yml` | 任意 | 不要 | 1コア / 1GB |
| Mastodon | `mastodon.yml` | **必須・変更不可** | **必須** | 2コア / 2GB |
| Element | `element.yml` | **必須・変更不可** | 不要 | 2コア / 2GB |
| Discord Bot | `discord_bot.yml` | 不要 | 不要 | 1コア / 1GB |
| ローカル AI 踏み台 | `ai_proxy.yml` | 任意 | 不要 | 1コア / 1GB |
| Factorio | `game_factorio.yml` | 不要 | 不要 | 2コア / 2GB |
| Windrose（UE5） | `game_windrose.yml` | 不要 | 不要 | 4コア / 8GB |

> 複数サービスを同一サーバで動かす場合は、各サービスの最小スペックを参考に必要なリソースを確保してください。  
> 踏み台サーバは Nginx のみ動かすため 1コア / RAM 512MB〜1GB で十分です。

---

## セットアップ

→ [docs/setup.md](./docs/setup.md) を参照してください。

---

## 秘匿情報の管理

以下のファイルは `.gitignore` で除外されています。別途バックアップしてください。

| ファイル | 内容 |
|---|---|
| `*/ansible/inventory.ini` | サーバの IP アドレス・ユーザー名 |
| `02_services/.env` | ドメイン・パスワード・秘密鍵 |
| `~/.ssh/id_ed25519_homelab` | サーバ接続用 SSH 秘密鍵 |
| `~/.ssl/<ドメイン>.pem/.key` | Cloudflare Origin Certificate（パターンB・ドメインあり時のみ） |

---

## ライセンス

MIT
