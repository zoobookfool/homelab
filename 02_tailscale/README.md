# 02 Tailscale

自宅サーバと VPS に Tailscale を導入し、プライベートネットワークを構築します。
また UFW を強化し、Tailscale 経由以外のアクセスをすべて遮断します。

---

## 前提条件

- [01_initial_setup](../01_initial_setup/README.md) が完了していること
- Tailscale アカウントを取得済みであること（https://tailscale.com）
- 自宅 PC・外出先タブレットにも Tailscale をインストール済みであること

> 💡 Tailscale は自宅 PC・タブレット・スマートフォン等にもインストールできます。
> 同じアカウントでログインすることで同一ネットワークに参加できます。

---

## ⚠️ この手順完了後の注意事項

**この手順が完了すると、自宅サーバへのアクセスは Tailscale 経由のみになります。**

- SSH（22番ポート）を含むすべてのポートが外部から遮断されます
- 以降の操作はすべて Tailscale に接続した状態で行います
- Tailscale に接続できない場合は物理アクセスが必要になります

---

## 1. Tailscale の準備

### 1-1. Auth Key の発行

Ansible による無人インストールのために Auth Key を発行します。

1. https://login.tailscale.com/admin/settings/keys を開く
2.「Generate auth key」をクリック
3. 以下の設定で生成する
   - Reusable: ON（自宅サーバ・VPS の両方に使うため）
   - Expiry: 任意（1日あれば十分）
4. 生成されたキーをメモしておく

> ⚠️ Auth Key は秘匿情報です。Git にコミットしないでください。

### 1-2. inventory ファイルの更新

`02_tailscale/ansible/inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 02_tailscale/ansible/inventory.ini << 'EOF'
# Ansible inventory ファイル
# このファイルは秘匿情報を含むため Git にコミットしないこと（.gitignore で除外済み）
#
# 書き方の例：
# [homeserver]
# 192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
#
# [vps]
# 203.0.113.1 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

[homeserver]
<自宅サーバのIPアドレス> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab

[vps]
<VPSのIPアドレス> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

---

## 2. Ansible の実行

### 2-1. Tailscale の導入（自宅サーバ・VPS 両方）

```bash
cd 02_tailscale/ansible
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass \
  -e "tailscale_auth_key=<発行したAuth Key>"
```

Playbook が設定する内容：

| 設定項目 | 内容 |
|---|---|
| Tailscale インストール | 公式リポジトリから導入 |
| Tailscale 認証 | Auth Key でログイン・ネットワーク参加 |
| 自動起動設定 | サーバ再起動後も自動で Tailscale が起動 |
| UFW 強化 | Tailscale インターフェース（tailscale0）からのみ SSH を許可 |
| UFW 強化 | それ以外からの全アクセスを遮断 |

---

## 3. 完了確認

### 3-1. Tailscale 管理画面で確認

https://login.tailscale.com/admin/machines を開き、自宅サーバと VPS が表示されていることを確認します。

### 3-2. Tailscale 経由で SSH 接続確認

自宅 PC の WSL2 上で実行します。

```bash
# Tailscale の IP アドレスで接続（管理画面で確認）
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<自宅サーバのTailscale IP>
```

接続できれば完了です。

### 3-3. 外部からのアクセスが遮断されていることを確認

```bash
# LAN の IP アドレスでは接続できないことを確認（タイムアウトになればOK）
ssh -i ~/.ssh/id_ed25519_homelab -o ConnectTimeout=5 <ユーザー名>@<自宅サーバのLAN IP>
```

---

## 完了後の接続方法

以降の手順はすべて **Tailscale の IP アドレス** を使って接続します。

```bash
# 以降の ansible-playbook はすべて Tailscale IP を inventory に記載して実行
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<TailscaleのIP>
```

---

## 次の手順

→ [03_docker](../03_docker/README.md)
