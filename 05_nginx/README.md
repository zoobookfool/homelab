# 05 Nginx（パターンA: 踏み台なし）

アプリサーバ（VPS / AWS）に Nginx・Certbot を直接導入し、外部公開の設定をします。
踏み台を使わずアプリサーバが直接インターネットに公開される構成です。

> パターンB（踏み台あり）の場合は [05_vps](../05_vps/README.md) を参照してください。

---

## 前提条件

- [04_services](../04_services/README.md) が完了していること
- ドメインを取得済みであること（Mastodon・Element を使う場合）
- DNS レコードをアプリサーバの IP アドレスに向けていること

### DNS レコードの設定例

| レコード | ホスト名 | 値 |
|---|---|---|
| A | `@` | アプリサーバの IP アドレス |
| A | `*` | アプリサーバの IP アドレス（ワイルドカード） |

> 💡 ワイルドカード `*` を設定しておくと `mastodon.example.com` 等のサブドメインが自動でアプリサーバに向きます。

---

## 1. UFW のポート開放

02_tailscale で全ポートを Tailscale 経由のみに制限しているため、HTTP / HTTPS を外部に開放します。
アプリサーバに SSH 接続して実行します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<アプリサーバのTailscale IP>
```

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
sudo ufw status
```

ゲームサーバを使う場合は UDP ポートも開放します。

```bash
# Factorio
sudo ufw allow 34197/udp

# Windrose（UE5）
sudo ufw allow 7777/udp
```

---

## 2. Nginx・Certbot のインストール

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
```

---

## 3. Nginx の設定

各サービスの設定ファイルを `/etc/nginx/conf.d/` に配置します。
設定例は `roles/nginx/` 以下にあります。

```
roles/nginx/
├── mastodon.conf.example
├── element.conf.example
├── monitoring.conf.example
└── ai_proxy.conf.example
```

設定例をコピーして編集します（`example.com` を自分のドメインに置き換えます）。

```bash
sudo cp /path/to/mastodon.conf.example /etc/nginx/conf.d/mastodon.conf
sudo nano /etc/nginx/conf.d/mastodon.conf
```

設定を反映します。

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 4. SSL 証明書の取得

```bash
# ワイルドカード証明書を取得（全サブドメインに対応）
sudo certbot --nginx -d example.com -d "*.example.com" --agree-tos
```

> 💡 ワイルドカード証明書は DNS-01 チャレンジが必要です。
> 取得時に DNS レコードへの TXT レコード追加を求められます。

---

## 5. 完了確認

ブラウザで以下にアクセスして動作を確認します。

| URL | 確認内容 |
|---|---|
| `https://monitoring.example.com` | Grafana のログイン画面 |
| `https://mastodon.example.com` | Mastodon のトップ画面 |
| `https://element.example.com` | Element のログイン画面 |
| `https://ai.example.com` | AI プロキシ（Ollama API） |

---

## 次の手順

→ [06_backup](../06_backup/README.md)
