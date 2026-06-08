# 05 踏み台サーバ

踏み台サーバ（VPS / AWS）に Tailscale・Nginx・UFW を導入し、外部公開の設定をします。

---

## 前提条件

- 踏み台サーバ（VPS / AWS）に Ubuntu Server 26.04 LTS がインストール済みであること（1コア・RAM 1GB 推奨）
- [01_initial_setup](../01_initial_setup/README.md) および [02_tailscale](../02_tailscale/README.md) を踏み台サーバに対して実行済みであること
- [04_services](../04_services/README.md) が完了していること

---

## 設定できること

| 機能 | 変数 | 必要なもの |
|---|---|---|
| Factorio UDP リレー | `relay_factorio: true` | アプリサーバの Tailscale IP |
| Windrose UDP+TCP リレー | `relay_windrose: true` | アプリサーバの Tailscale IP |
| Grafana リバースプロキシ | `domain: "example.com"` | ドメイン・DNS 設定 |
| Mastodon リバースプロキシ | `domain: "example.com"` | ドメイン・DNS 設定 |
| Element リバースプロキシ | `domain: "example.com"` | ドメイン・DNS 設定 |
| AI プロキシ | `domain: "example.com"` | ドメイン・DNS 設定 |

> **ゲームサーバのみ使う場合はドメイン不要です。**
> Windrose は `relay_windrose: true` にすることで自宅サーバの IP アドレスを友人に見せずに接続できます。

---

## 1. inventory ファイルの作成

`05_relay/ansible/inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 05_relay/ansible/inventory.ini << 'EOF'
[relay]
<踏み台サーバのTailscale IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

---

## 2. playbook.yml の変数を設定

`05_relay/ansible/playbook.yml` の `vars` セクションを編集します。

```yaml
vars:
  app_server_ip: "100.x.x.x"  # ← アプリサーバの Tailscale IP を設定（必須）

  relay_factorio: true         # ← Factorio を外部公開する場合
  relay_windrose: true         # ← Windrose を外部公開する場合（自宅 IP 隠蔽）

  domain: ""                   # ← Mastodon・Element 等を使う場合のみ設定
```

> 💡 `domain` を設定する場合は、先に [5. SSL 証明書の準備](#5-ssl-証明書の準備ドメインあり時のみ) を済ませて
> `~/.ssl/<ドメイン>.pem` / `.key` を用意しておいてください。Ansible 実行時に自動配置されます。

---

## 3. Ansible の実行

```bash
cd 05_relay/ansible
ansible-playbook -i inventory.ini playbook.yml \
  -e "tailscale_auth_key=<発行したAuth Key>"
```

Playbook が設定する内容：

| 設定項目 | 内容 |
|---|---|
| Tailscale | 踏み台サーバをアプリサーバと同じ Tailscale ネットワークに参加させる |
| UFW | 有効にしたサービスのポートのみ外部に開放 |
| Nginx stream | UDP/TCP をアプリサーバに転送（ゲームサーバリレー） |
| Nginx http | 各サービスのリバースプロキシ設定を配置（ドメインあり時のみ） |

---

## 4. ゲームサーバの接続確認

### Factorio

クライアントから `<踏み台 IP>:34197` に直接接続できることを確認します。

```
Factorio → マルチプレイヤー → 直接接続 → 踏み台のIP:34197
```

### Windrose（自宅 IP 隠蔽）

`relay_windrose: true` で踏み台経由のリレーが有効になります。
加えて、アプリサーバ側の `ServerDescription.json` で直接接続モードに切り替えます。

```bash
# アプリサーバに SSH 接続して設定を変更
docker exec windrose sh -c 'cat /server/R5/ServerDescription.json'
```

`UseDirectConnection: true` に変更し、`DirectConnectionServerAddress` を踏み台の IP に設定します。

```json
{
  "UseDirectConnection": true,
  "DirectConnectionServerAddress": "<踏み台のIP>",
  "DirectConnectionServerPort": 7777
}
```

コンテナを再起動後、新しい招待コードを共有します。

---

## 5. SSL 証明書の準備（ドメインあり時のみ）

`domain` を設定した場合のみ実施します。
このリポジトリでは **Cloudflare Origin Certificate** を使用します（証明書の自動更新運用が不要・有効期限 15 年）。

### 5-1. DNS レコードの設定（Cloudflare）

| レコード | ホスト名 | 値 | プロキシ |
|---|---|---|---|
| A | `@` | 踏み台の IP アドレス | プロキシ済み（オレンジ） |
| A | `*` | 踏み台の IP アドレス（ワイルドカード） | プロキシ済み（オレンジ） |

> プロキシを有効にすることで踏み台の IP アドレスがユーザーから隠れます。

### 5-2. SSL/TLS モードの設定（Cloudflare）

Cloudflare ダッシュボード → **SSL/TLS** → 暗号化モードを **「フル（厳格）」** に設定します。

### 5-3. Origin Certificate の発行（Cloudflare）

Cloudflare ダッシュボード → **SSL/TLS → 原点サーバー → 証明書を作成**

| 項目 | 値 |
|---|---|
| 秘密鍵のタイプ | RSA |
| ホスト名 | `<ドメイン>` と `*.<ドメイン>` |
| 有効期限 | 15 年 |

発行された**証明書**と**秘密鍵**を操作端末（WSL2）に保存します。

```bash
mkdir -p ~/.ssl && chmod 700 ~/.ssl

nano ~/.ssl/<ドメイン>.pem   # 証明書を貼り付けて保存
nano ~/.ssl/<ドメイン>.key   # 秘密鍵を貼り付けて保存

chmod 644 ~/.ssl/<ドメイン>.pem
chmod 600 ~/.ssl/<ドメイン>.key
```

> ⚠️ 秘密鍵は機密情報です。チャット・Issue・コミットには絶対に含めないでください。

### 5-4. Ansible 実行時に自動配置

`playbook.yml` を実行すると、上記のファイルが自動的に踏み台サーバの `/etc/nginx/ssl/` に配置され、
Nginx の SSL 設定（`ssl_certificate` / `ssl_certificate_key`）がそのパスを参照します。
（`cloudflare_cert_path` / `cloudflare_key_path` 変数のデフォルトは `~/.ssl/<ドメイン>.pem` / `.key`）

---

## 次の手順

→ [06_backup](../06_backup/README.md)
