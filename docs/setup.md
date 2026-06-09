# セットアップ手順

> 以降の操作は **WSL2（Ubuntu）上** で実行します。  
> Ansible のインストールや SSH キーの作成がまだの場合は先に [01_network](../01_network/README.md) を参照してください。

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
vi 02_services/.env
```

使うサービスのセクションだけ埋めます。使わないサービスの項目は空欄のままで構いません。

> ⚠️ `DOCKER_BIND_IP` はこの時点では空欄にしておいてください。  
> 手順 1 完了後に Tailscale IP が確定するので、そのタイミングで設定します。

### inventory ファイルを作成

**アプリサーバ用:**

```bash
cat > 01_network/ansible/inventory.ini << 'EOF'
[app]
<サーバのIPアドレス> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

> この時点では LAN IP または VPS 公開 IP を記入します。

**パターンB 踏み台サーバ用（追加で作成）:**

```bash
cat > 03_proxy/ansible/inventory.ini << 'EOF'
[relay]
<踏み台サーバのIPアドレス> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

> inventory ファイルは `.gitignore` で除外されています。

---

## 1. Tailscale 網を構築する（アプリサーバ）

### 1a. OS 初期設定 + Tailscale インストール

```bash
ansible-playbook -i 01_network/ansible/inventory.ini 01_network/ansible/playbook.yml \
  -e "tailscale_auth_key=<Auth Key>"
```

完了すると Tailscale IP が表示されます。

### inventory と .env を更新する

`01_network/ansible/inventory.ini` の IP を Tailscale IP に書き換えます。

```
[app]
100.x.x.x  ← Tailscale IP に変更
```

`02_services/.env` の `DOCKER_BIND_IP` も設定します。

```
# パターンA
DOCKER_BIND_IP=127.0.0.1

# パターンB
DOCKER_BIND_IP=100.x.x.x  ← アプリサーバの Tailscale IP
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

> `02_services/ansible/` には inventory.ini を別途作成せず、`01_network` のものを流用します。

Ansible がファイルのデプロイ → Mastodon / Element の初期化 → `make up-all` による起動 を自動で行います。

---

## 3. リバースプロキシを設定する（外部公開する場合）

ドメインなし・Tailscale 経由のみでアクセスするサービスはこの手順は不要です。

### 03_proxy/ansible/playbook.yml の vars を設定

**パターンA（アプリサーバに Nginx を設定）:**

```yaml
vars:
  domain: "example.com"
```

**パターンB（踏み台サーバに Nginx を設定）:**

```yaml
vars:
  app_server_ip: "100.x.x.x"   # アプリサーバの Tailscale IP
  domain: "example.com"         # ドメインあり時のみ
  relay_factorio: true          # Factorio を外部公開する場合
  relay_windrose: true          # Windrose を外部公開する場合
```

### Ansible を実行

```bash
ansible-playbook -i 03_proxy/ansible/inventory.ini 03_proxy/ansible/playbook.yml \
  -e "tailscale_auth_key=<Auth Key>"   # パターンB のみ
```

> SSL 証明書（Cloudflare Origin Certificate）の準備が必要な場合は [03_proxy/README.md](../03_proxy/README.md) を参照してください。

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
