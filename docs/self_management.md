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

入っていない場合は [01_initial_setup](../01_initial_setup/README.md) の「Ansible のインストール」を参照してください。

### 2. 各手順を順番に実行

| 手順 | 実行コマンド | 備考 |
|---|---|---|
| [01_initial_setup](../01_initial_setup/README.md) | `ansible-playbook -i inventory.ini playbook.yml` | 最初だけ物理アクセスが必要 |
| [02_tailscale](../02_tailscale/README.md) | `ansible-playbook -i inventory.ini playbook.yml` | 完了後は Tailscale 経由のみ |
| [03_docker](../03_docker/README.md) | `ansible-playbook -i inventory.ini playbook.yml` | |
| [04_services](../04_services/README.md) | `make up-core` | .env の設定が必要 |
| [05_relay](../05_relay/README.md) | `ansible-playbook -i inventory.ini playbook.yml` | |

### 3. 各 inventory.ini を作成する

各手順フォルダの README を参照して `inventory.ini` を作成します。
IP アドレスは Tailscale の管理画面（https://login.tailscale.com/admin/machines）で確認します。

### 4. .env を復元する

`04_services/.env` を手元のバックアップから復元します。

> ⚠️ `.env` は Git で管理されていないため、別途保管が必要です。
> パスワードマネージャー等への保存を推奨します。

---

## 各サービスを別サーバで動かす

> 🚧 将来対応。現バージョンでは未対応です。

サービスごとにcomposeファイルが独立しているため、新しいサーバで `01〜03` を実行してから対象サービスの `make up-<サービス名>` を実行することで移行できる見込みです。
手順の整備は今後対応予定です。

---

## バックアップからの復旧

> 🚧 将来対応。現バージョンでは未対応です。

バックアップ対象・保存先の確定後に手順を整備予定です。
現時点のバックアップ設計は [06_backup](../06_backup/README.md) を参照してください。

---

## 定期メンテナンス

| 作業 | タイミング | 手順 |
|---|---|---|
| OS アップデート | 適宜 | `sudo apt update && sudo apt upgrade` |
| Docker イメージ更新 | 適宜 | `docker compose -f compose/<サービス>.yml pull && make up-<サービス>` |
| Tailscale 更新 | 適宜 | `sudo apt update && sudo apt install tailscale` |
| SSL 証明書更新 | 自動（Certbot） | `sudo certbot renew --dry-run` で確認 |
