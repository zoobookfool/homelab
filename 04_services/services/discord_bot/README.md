# Discord Bot

カスタム Discord Bot のサーバです。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 1コア以上 |
| RAM | 512MB 以上 |
| ポート | 不要（外向きの WebSocket 接続のみ） |
| ドメイン | 不要 |
| Discord アカウント | **必要**（Bot トークンの取得に使用） |

---

## Bot トークンの取得

1. [Discord Developer Portal](https://discord.com/developers/applications) にアクセス
2. New Application → Bot → Reset Token でトークンを発行
3. Privileged Gateway Intents（Message Content Intent 等）を必要に応じて有効化
4. OAuth2 → URL Generator でサーバに招待する URL を生成

---

## 起動方法

### 1. 環境変数を設定

`/opt/homelab/.env` に以下を設定します。

```
DISCORD_BOT_TOKEN=<発行したBotトークン>
```

### 2. 起動

```bash
make up-discord-bot
```

---

## Bot のカスタマイズ

`services/discord_bot/` にある Python コードを編集してください。
依存パッケージは `requirements.txt` に記載します。

変更後はイメージを再ビルドして再起動します。

```bash
docker compose -f compose/discord_bot.yml build
make up-discord-bot
```
