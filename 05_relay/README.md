# 05 踏み台サーバ

踏み台サーバ（VPS / AWS）に Tailscale・Nginx・Certbot を導入し、外部公開の設定をします。

---

## 前提条件

- 踏み台サーバ（VPS / AWS）に Ubuntu Server 26.04 LTS がインストール済みであること（1コア・RAM 1GB 推奨）
- [04_services](../04_services/README.md) が完了していること
- ドメインを取得済みであること
- DNS レコードを踏み台サーバの IP アドレスに向けていること

### DNS レコードの設定例

| レコード | ホスト名 | 値 |
|---|---|---|
| A | `@` | VPS の IP アドレス |
| A | `*` | VPS の IP アドレス（ワイルドカード） |

> 💡 ワイルドカード `*` を設定しておくと `mastodon.example.com` 等のサブドメインが自動で VPS に向きます。

---

## 1. 踏み台サーバの初期設定（サーバコンソールで実施）

VPS / AWS の管理画面からコンソール（またはシリアルコンソール）を開き、以下を実行します。

### 1-1. SSH サーバの確認

```bash
sudo systemctl status ssh
```

### 1-2. 自宅 PC の公開鍵を登録

```bash
mkdir -p ~/.ssh
echo "<id_ed25519_homelab.pub の内容>" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

> 💡 公開鍵の確認は自宅 PC の WSL2 で実行します。
> ```bash
> cat ~/.ssh/id_ed25519_homelab.pub
> ```

---

## 2. inventory ファイルの作成

`05_relay/ansible/` に `inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 05_relay/ansible/inventory.ini << 'EOF'
# Ansible inventory ファイル
# このファイルは秘匿情報を含むため Git にコミットしないこと（.gitignore で除外済み）
#
# 書き方の例：
# [relay]
# 203.0.113.1 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

[relay]
<踏み台サーバのIPアドレス> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

---

## 3. Ansible の実行

```bash
cd 05_relay/ansible
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass \
  -e "tailscale_auth_key=<発行したAuth Key>" \
  -e "domain=<取得したドメイン名>"
```

Playbook が設定する内容：

| 設定項目 | 内容 |
|---|---|
| Tailscale インストール | 公式リポジトリから導入 |
| Tailscale 認証 | Auth Key でログイン・ネットワーク参加 |
| UFW 設定 | HTTP(80)・HTTPS(443)・ゲーム UDP ポートのみ外部に開放 |
| UFW 設定 | SSH は Tailscale 経由のみ許可 |
| Nginx インストール | 公式リポジトリから導入 |
| Certbot インストール | Let's Encrypt による SSL 証明書の自動取得・更新 |
| Nginx 設定 | 各サービスのリバースプロキシ設定を配置 |

---

## 4. SSL 証明書の取得

Ansible 完了後、VPS に SSH 接続して証明書を取得します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<踏み台サーバのTailscale IP>
```

```bash
# ワイルドカード証明書を取得（全サブドメインに対応）
sudo certbot --nginx -d example.com -d "*.example.com" --agree-tos
```

> 💡 ワイルドカード証明書は DNS-01 チャレンジが必要です。
> 取得時に DNS レコードへの TXT レコード追加を求められます。

---

## 5. UDP リレーの設定（ゲームサーバ）

Nginx stream モジュールを使って UDP パケットをアプリサーバに転送します。
Ansible 完了後、`/etc/nginx/nginx.conf` に以下を追記します。

```nginx
stream {
    server {
        listen 34197 udp;
        proxy_pass <アプリサーバのTailscale IP>:34197;
    }
    server {
        listen 7777 udp;
        proxy_pass <アプリサーバのTailscale IP>:7777;
    }
}
```

設定後、Nginx を再起動します。

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 6. 完了確認

ブラウザで以下にアクセスして動作を確認します。

| URL | 確認内容 |
|---|---|
| `https://monitoring.example.com` | Grafana のログイン画面 |
| `https://mastodon.example.com` | Mastodon のトップ画面 |
| `https://element.example.com` | Element のログイン画面 |
| `https://ai.example.com` | AI プロキシ（Ollama API） |

---

## Nginx 設定ファイルの場所

各サービスの Nginx 設定例は `roles/nginx/` 以下にあります。

```
roles/nginx/
├── mastodon.conf.example
├── element.conf.example
├── monitoring.conf.example
└── ai_proxy.conf.example
```

---

## 次の手順

→ [06_backup](../06_backup/README.md)
