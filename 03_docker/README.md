# 03 Docker

アプリサーバに Docker・Docker Compose をインストールします。

---

## 前提条件

- [02_tailscale](../02_tailscale/README.md) が完了していること
- 自宅 PC が Tailscale に接続済みであること

---

## 1. inventory ファイルの作成

`03_docker/ansible/` に `inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 03_docker/ansible/inventory.ini << 'EOF'
[app]
<アプリサーバのTailscale IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

> 💡 02_tailscale 完了後は LAN の IP ではなく Tailscale の IP を使います。
> Tailscale の IP は https://login.tailscale.com/admin/machines で確認できます。

---

## 2. Ansible の実行

```bash
cd 03_docker/ansible
ansible-playbook -i inventory.ini playbook.yml
```

Playbook が設定する内容：

| 設定項目 | 内容 |
|---|---|
| Docker のインストール | 公式スクリプト（`get.docker.com`）で導入 |
| Docker の自動起動設定 | サーバ再起動後も自動起動 |
| ユーザーを docker グループに追加 | `sudo` なしで docker コマンドを使えるように |

---

## 3. 完了確認

Ansible 完了後、アプリサーバに SSH 接続して確認します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<アプリサーバのTailscale IP>
```

```bash
# Docker のバージョン確認
docker --version

# Docker Compose のバージョン確認
docker compose version

# 動作確認
docker run --rm hello-world
```

`Hello from Docker!` と表示されれば完了です。

---

## 次の手順

→ [04_services](../04_services/README.md)
