# セットアップ手順

以降の操作は **WSL2（Ubuntu）上** で実行します。

### 事前準備（未設定の場合のみ）

**Git のインストール**

```bash
sudo apt update && sudo apt install -y git
```

**Ansible のインストール**

```bash
sudo apt update && sudo apt install -y ansible
```

**SSH キーの作成**

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_homelab -C "homelab"
```

生成した公開鍵 (`~/.ssh/id_ed25519_homelab.pub`) をサーバに登録しておきます。

---

## 手動編集ファイル一覧

作業を通じて手動で記載が必要なファイルです。

| タイミング | ファイル | 内容 |
|---|---|---|
| 手順 0 | `02_services/.env` | ドメイン・パスワード・API キーなど |
| 手順 0 | `01_network/ansible/inventory.ini` の `[app_init]` | 初期接続 IP・ユーザー名 |
| 手順 0 | `03_proxy/ansible/playbook.yml` の `vars` | ドメイン・踏み台 IP・リレー有無（手順 3 前に設定） |
| 手順 1a 完了後 | `01_network/ansible/inventory.ini` の `[app]` | `ansible_host=` に Tailscale IP を記入 |
| 手順 1a 完了後 | `02_services/.env` の `DOCKER_BIND_IP`（ゲーム使用時は `GAME_BIND_IP` も） | Tailscale IP を設定 |

---

## 0. ローカルで設定ファイルを準備する

### リポジトリをクローン

```bash
git clone git@github.com:zoobookfool/homelab.git
cd homelab
```

### 使わないサービスの compose ファイルを削除

`02_services/compose/` から使わないサービスのファイルを削除します。

```bash
# 例：monitoring と Mastodon だけ使う場合
rm 02_services/compose/element.yml
rm 02_services/compose/discord_bot.yml
rm 02_services/compose/ai_proxy.yml
rm 02_services/compose/game_factorio.yml
rm 02_services/compose/game_windrose.yml
```

残ったファイルだけがサーバにデプロイされ、`make up-all` の対象になります。

### .env を設定

```bash
cp 02_services/.env.example 02_services/.env
nano 02_services/.env
```

使うサービスのセクションだけ埋めます。使わないサービスの項目は空欄のままで構いません。

> ⚠️ `DOCKER_BIND_IP` はこの時点では空欄にしておいてください。  
> 手順 1 完了後に Tailscale IP が確定するので、そのタイミングで設定します。

### inventory ファイルを作成

全手順で共通して使う inventory ファイルを1つ作成します。

```bash
cat > 01_network/ansible/inventory.ini << 'EOF'
# 手順 1a 用（初期接続 IP）
[app_init]
app_init ansible_host=<公開 IP または LAN IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

# 手順 1b 以降（Tailscale IP — 手順 1a 完了後に記入）
[app]
app ansible_host= ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

# パターンB のみ
[relay]
relay ansible_host=<踏み台サーバ IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

> inventory ファイルは `.gitignore` で除外されています。

---

## 1. Tailscale 網を構築する（アプリサーバ）

### Auth Key を取得する

1. [Tailscale 管理画面の Keys ページ](https://login.tailscale.com/admin/settings/keys) を開く
2. **Generate auth key** をクリック
3. 必要に応じて設定して生成する
   - **Reusable**: パターンB で踏み台サーバにも同じキーを使う場合は ON にする（OFF だと1台目で使い切り、2台目は別キーが必要）
   - **Expiration**: 1日に短縮する。インストール用の一時的なキーなので、使い終わったら無効になるようにしておく
4. 生成された `tskey-auth-...` から始まる文字列をコピーする（画面を閉じると再表示できないので注意）

### 1a. OS 初期設定 + Tailscale インストール

```bash
ansible-playbook -i 01_network/ansible/inventory.ini 01_network/ansible/playbook.yml \
  -e "tailscale_auth_key=<Auth Key>"
```

完了すると Tailscale IP が表示されます。

### inventory と .env を更新する

`01_network/ansible/inventory.ini` の `[app]` の `ansible_host=` に Tailscale IP を記入します。

```
[app]
app ansible_host=100.x.x.x  ← ここに Tailscale IP を記入
```

`02_services/.env` の `DOCKER_BIND_IP` も設定します。

```
# パターンA
DOCKER_BIND_IP=127.0.0.1

# パターンB
DOCKER_BIND_IP=100.x.x.x  ← アプリサーバの Tailscale IP
```

ゲームサーバ（Factorio / Windrose）を使う場合は `GAME_BIND_IP` も設定します。

```
# パターンA（直接公開）
GAME_BIND_IP=          ← 空欄のまま

# パターンB（踏み台でリレー）
GAME_BIND_IP=100.x.x.x ← アプリサーバの Tailscale IP（実 IP の露出を防ぐ）
```

### 1b. UFW ロックダウン

```bash
ansible-playbook -i 01_network/ansible/inventory.ini 01_network/ansible/playbook_lockdown.yml
```

以降、アプリサーバへの接続は Tailscale 経由のみになります。

---

## 2. サービスをデプロイする（アプリサーバ）

```bash
ansible-playbook -i 01_network/ansible/inventory.ini 02_services/ansible/playbook.yml
```

Ansible がファイルのデプロイ → Mastodon / Element の初期化 → `make up-all` による起動 を自動で行います。

---

## 3. リバースプロキシを設定する（外部公開する場合）

ドメインなし・Tailscale 経由のみでアクセスするサービスはこの手順は不要です。

> ⚠️ 実行前に、使用する各サブドメイン（`mastodon.` `element.` `matrix.` `monitoring.` `ai.`）の
> DNS A レコードを公開サーバ（パターンA: アプリサーバ / パターンB: 踏み台サーバ）に向けておいてください。
> パターンA では Let's Encrypt の証明書取得（Ansible が自動実行）に DNS 設定が必須です。

### Cloudflare Origin Certificate の準備（パターンB のみ）

Cloudflare ダッシュボード → **SSL/TLS → Origin Server → Create Certificate** で証明書を生成し、ローカルに保存します。

```bash
mkdir -p ~/.ssl
# 証明書を ~/.ssl/<ドメイン>.pem に保存
# 秘密鍵を ~/.ssl/<ドメイン>.key に保存
```

### 03_proxy/ansible/playbook.yml の vars を設定

**パターンA（アプリサーバに Nginx を設定）— 1つ目のプレイの vars:**

```yaml
vars:
  domain: "example.com"
  certbot_email: "you@example.com"   # Let's Encrypt の期限通知用
  certbot_subdomains:                # 使わないサービスは削る
    - mastodon
    - element
    - matrix
    - monitoring
    - ai
```

> 証明書の取得・自動更新は Ansible 実行時に Certbot が処理します。

**パターンB（踏み台サーバに Nginx を設定）— 2つ目のプレイの vars:**

```yaml
vars:
  app_server_ip: "100.x.x.x"   # アプリサーバの Tailscale IP
  domain: "example.com"         # ドメインあり時のみ
  relay_factorio: true          # Factorio を外部公開する場合
  relay_windrose: true          # Windrose を外部公開する場合
```

### Ansible を実行

```bash
ansible-playbook -i 01_network/ansible/inventory.ini 03_proxy/ansible/playbook.yml \
  -e "tailscale_auth_key=<Auth Key>"   # パターンB のみ
```

---

## 4. 各サービスを確認する

Mastodon・Element の初期化は Ansible（手順 2）が自動で行います。  
起動後に以下を確認してください。

### Mastodon

ブラウザで `https://mastodon.<ドメイン>` にアクセスし、`.env` の `MASTODON_ADMIN_USERNAME` でログインできることを確認します。

### Element（Matrix Synapse）

ブラウザで `https://element.<ドメイン>` にアクセスし、サーバ `matrix.<ドメイン>` でログインできることを確認します。

### Factorio

起動後 `/opt/homelab/game/factorio/config/server-settings.json` が自動生成されます。サーバ名・パスワード等を設定してコンテナを再起動してください。

### Windrose（UE5）

```bash
# 招待コードを確認（起動完了まで 1〜2 分かかります）
docker exec windrose cat /server/R5/ServerDescription.json
```

`InviteCode` の値を友人に共有します。

---

## 補足：サービス管理コマンド

サーバの `/opt/homelab` で実行します。

```bash
# 個別に起動・停止
make up-monitoring
make up-mastodon
make up-element
make up-discord-bot
make up-ai-proxy
make up-game-factorio
make up-game-windrose

make down-<サービス名>

# すべて起動 / 停止
make up-all
make down

# ログ確認
make logs-<サービス名>
```

> `04_backup` はバックアップ設定です。運用開始後に設定してください。→ [04_backup](../04_backup/README.md)
