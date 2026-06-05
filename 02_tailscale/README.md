# 02 Tailscale

アプリサーバに Tailscale を導入し、プライベートネットワークを構築します。
UFW ロックダウンは Tailscale 接続を確認してから別ステップで実行します。

> パターンB（踏み台あり）の場合、踏み台サーバへの Tailscale 導入は [05_vps](../05_vps/README.md) で行います。

---

## 前提条件

- [01_initial_setup](../01_initial_setup/README.md) が完了していること
- Tailscale アカウントを取得済みであること（https://tailscale.com）
- 操作端末（自宅 PC）にも Tailscale をインストール済みであること

---

## 1. Auth Key の発行

Ansible による無人インストールのために Auth Key を発行します。

1. https://login.tailscale.com/admin/settings/keys を開く
2.「Generate auth key」をクリック
3. 以下の設定で生成する
   - Reusable: ON
   - Expiry: 任意（1日あれば十分）
4. 生成されたキーをメモしておく

> ⚠️ Auth Key は秘匿情報です。Git にコミットしないでください。

---

## 2. inventory ファイルの作成

`02_tailscale/ansible/inventory.ini` を作成します。
このファイルは **Git にコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 02_tailscale/ansible/inventory.ini << 'EOF'
[app]
<アプリサーバのLAN IP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

---

## 3. Tailscale の導入

```bash
cd 02_tailscale/ansible
ansible-playbook -i inventory.ini playbook_tailscale.yml \
  -e "tailscale_auth_key=<発行したAuth Key>"
```

Playbook が設定する内容：

| 設定項目 | 内容 |
|---|---|
| Tailscale インストール | 公式スクリプトで導入 |
| Tailscale 認証 | Auth Key でログイン・ネットワーク参加 |
| 自動起動設定 | サーバ再起動後も自動で Tailscale が起動 |

---

## 4. Tailscale 接続の確認

> ⚠️ **この確認が完了してから UFW ロックダウンを実行してください。**
> 確認前にロックダウンすると Tailscale が繋がらない場合にサーバへ到達不能になります。

### 4-1. Tailscale 管理画面で確認

https://login.tailscale.com/admin/machines を開き、アプリサーバが表示されていることを確認します。
表示された Tailscale IP をメモします（例：`100.x.x.x`）。

### 4-2. 操作端末からの接続確認

操作端末の Tailscale に接続した状態で実行します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<TailscaleのIP>
```

接続できれば次のステップに進みます。

---

## 5. UFW ロックダウン

Tailscale 接続が確認できたら inventory を Tailscale IP に書き換えて実行します。

```bash
# inventory を Tailscale IP に更新
cat > 02_tailscale/ansible/inventory.ini << 'EOF'
[app]
<TailscaleのIP> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF

# UFW ロックダウンを実行
ansible-playbook -i inventory.ini playbook_ufw_lockdown.yml
```

設定される内容：

| 設定項目 | 内容 |
|---|---|
| UFW 強化 | Tailscale インターフェース（tailscale0）からのみ SSH を許可 |
| UFW 強化 | それ以外からの全アクセスを遮断 |

**この手順完了後、サーバへのアクセスは Tailscale 経由のみになります。**

---

## 完了後の接続方法

以降の手順はすべて **Tailscale の IP アドレス** を使って接続します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<TailscaleのIP>
```

---

## 次の手順

→ [03_docker](../03_docker/README.md)
