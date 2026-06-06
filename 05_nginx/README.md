# 05 Nginx（パターンA: 踏み台なし）

アプリサーバ（VPS / AWS）に Nginx・Certbot を直接導入し、外部公開の設定をします。
踏み台を使わずアプリサーバが直接インターネットに公開される構成です。

> パターンB（踏み台あり）の場合は [05_relay](../05_relay/README.md) を参照してください。

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

## 1. inventory ファイルの作成

`05_nginx/ansible/` に `inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 05_nginx/ansible/inventory.ini << 'EOF'
# Ansible inventory ファイル
# このファイルは秘匿情報を含むため Git にコミットしないこと（.gitignore で除外済み）
#
# 書き方の例：
# [app]
# 100.x.x.x ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

[app]
<アプリサーバのTailscale IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

---

## 2. Ansible の実行

```bash
cd 05_nginx/ansible
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass \
  -e "domain=<取得したドメイン名>"
```

ゲームサーバ（Factorio・Windrose）の UDP ポートも開放する場合は `-e "open_game_ports=true"` を追加します。

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass \
  -e "domain=<取得したドメイン名>" \
  -e "open_game_ports=true"
```

Playbook が設定する内容：

| 設定項目 | 内容 |
|---|---|
| UFW 設定 | HTTP(80)・HTTPS(443) を外部に開放 |
| UFW 設定 | ゲーム UDP ポートを開放（`open_game_ports=true` 時のみ） |
| Nginx インストール | 公式リポジトリから導入 |
| Certbot インストール | Let's Encrypt による SSL 証明書の自動取得・更新 |
| Nginx 設定 | 各サービスのリバースプロキシ設定を配置 |

---

## 3. SSL 証明書の取得

Ansible 完了後、アプリサーバに SSH 接続して証明書を取得します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<アプリサーバのTailscale IP>
```

```bash
# ワイルドカード証明書を取得（全サブドメインに対応）
sudo certbot --nginx -d example.com -d "*.example.com" --agree-tos
```

> 💡 ワイルドカード証明書は DNS-01 チャレンジが必要です。
> 取得時に DNS レコードへの TXT レコード追加を求められます。

---

## 4. 完了確認

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
