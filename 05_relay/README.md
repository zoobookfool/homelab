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

## 5. SSL 証明書の取得（ドメインあり時のみ）

`domain` を設定した場合のみ実施します。

### DNS レコードの設定

| レコード | ホスト名 | 値 |
|---|---|---|
| A | `@` | 踏み台の IP アドレス |
| A | `*` | 踏み台の IP アドレス（ワイルドカード） |

### 証明書の取得

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<踏み台のTailscale IP>
sudo certbot --nginx -d example.com -d "*.example.com" --agree-tos
```

> ワイルドカード証明書は DNS-01 チャレンジが必要です。
> 取得時に DNS レコードへの TXT レコード追加を求められます。

---

## 次の手順

→ [06_backup](../06_backup/README.md)
