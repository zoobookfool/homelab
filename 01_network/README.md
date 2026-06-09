# 01 Network

OS 初期設定・Tailscale VPN の構築を行います。

## 事前準備（ローカルマシン）

### Ansible のインストール（WSL2）

```bash
sudo apt update
sudo apt install -y ansible
```

### サーバ接続用 SSH キーの作成

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_homelab -C "homelab"
```

生成した公開鍵 (`~/.ssh/id_ed25519_homelab.pub`) をサーバに登録してから以降の手順を進めます。

---

セットアップ手順は [docs/setup.md](../docs/setup.md) を参照してください。
