# 自分用環境管理

サーバの再構築・環境リセット時の手順をまとめています。

---

## 環境再構築手順

サーバが交換・リセットになった場合、以下の手順で同じ環境を再現します。

### 1. 事前準備（自宅 PC で）

```bash
# リポジトリを取得
git clone git@github.com:zoobookfool/homelab.git
cd homelab
```

WSL2 に Ansible がインストールされていることを確認します。

```bash
ansible --version
```

### 2. 設定ファイルを復元する

**inventory.ini を再作成する**

`01_network/ansible/inventory.ini` を作成します。  
IP アドレスは Tailscale の管理画面（https://login.tailscale.com/admin/machines）で確認します。

**`.env` をバックアップから復元する**

```bash
# パスワードマネージャー等のバックアップから 02_services/.env を復元
cp <バックアップの.env> 02_services/.env
```

> ⚠️ `.env` は Git で管理されていないため、別途バックアップが必要です。  
> パスワードマネージャーへの保存を推奨します。

### 3. 各手順を順番に実行する

詳細は [docs/setup.md](./setup.md) を参照してください。

| 手順 | コマンド | 備考 |
|---|---|---|
| 01_network (OS + Tailscale) | `ansible-playbook -i 01_network/ansible/inventory.ini 01_network/ansible/playbook.yml -e "tailscale_auth_key=<key>"` | 完了後 IP を inventory に反映 |
| 01_network (UFW) | `ansible-playbook -i 01_network/ansible/inventory.ini 01_network/ansible/playbook_lockdown.yml` | |
| 02_services | `ansible-playbook -i 01_network/ansible/inventory.ini 02_services/ansible/playbook.yml` | .env 転送・サービス起動まで自動 |
| 03_proxy | `ansible-playbook -i 03_proxy/ansible/inventory.ini 03_proxy/ansible/playbook.yml` | |

---

## 各サービスを別サーバで動かす

> 🚧 将来対応。現バージョンでは未対応です。

サービスごとに compose ファイルが独立しているため、新しいサーバで `01〜02` を実行してから対象サービスの `make up-<サービス名>` を実行することで移行できる見込みです。
手順の整備は今後対応予定です。

---

## バックアップからの復旧

バックアップ手順・リストア手順は [04_backup](../04_backup/README.md) を参照してください。

---

## 定期メンテナンス

| 作業 | タイミング | 手順 |
|---|---|---|
| OS アップデート | 適宜 | `sudo apt update && sudo apt upgrade` |
| Docker イメージ更新 | 適宜 | `docker compose --env-file .env -f compose/<サービス>.yml pull && make up-<サービス>` |
| Tailscale 更新 | 適宜 | `sudo apt update && sudo apt install tailscale` |
| SSL 証明書更新 | 自動（Certbot） | `sudo certbot renew --dry-run` で確認 |
