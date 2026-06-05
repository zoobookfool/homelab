# 06 Backup

各サービスのデータをバックアップします。

> ⚠️ バックアップ対象・保存先は要検討です。
> 現時点では方針と手動実行スクリプトのみ記載しています。

---

## データの保存場所

すべてのサービスデータは自宅サーバの `/opt/homelab/` 以下に Bind Mount で保存されています。

```
/opt/homelab/
├── mastodon/
│   ├── postgres/      # データベース
│   └── public/        # メディアファイル
├── monitoring/
│   ├── prometheus/    # メトリクスデータ
│   └── grafana/       # ダッシュボード設定
├── element/
│   ├── postgres/      # データベース
│   └── synapse/       # Matrix サーバ設定・データ
├── discord_bot/       # Bot データ
└── game/
    ├── factorio/      # セーブデータ・設定
    └── windrose/      # セーブデータ・設定
```

---

## バックアップ対象（TODO: 優先度を整理する）

| 対象 | 重要度 | 理由 |
|---|---|---|
| `mastodon/postgres` | 高 | 投稿・フォロワーデータ。消えると復旧不可 |
| `mastodon/public` | 中 | メディアファイル。容量が大きくなる可能性あり |
| `element/postgres` | 高 | チャット履歴。消えると復旧不可 |
| `element/synapse` | 高 | Matrix サーバの鍵情報。消えるとフェデレーション不可 |
| `grafana` | 低 | ダッシュボード設定。再構築可能 |
| `factorio` | 中 | セーブデータ |
| `windrose` | 中 | セーブデータ |
| `prometheus` | 低 | メトリクス履歴。消えても運用に支障なし |
| `discord_bot` | 低 | 再構築可能 |

---

## バックアップ先（TODO: 決定する）

候補：

- 自宅 PC（Tailscale 経由で転送）
- 外付け HDD（自宅サーバに直接接続）
- オブジェクトストレージ（Cloudflare R2・S3 等）

---

## 手動バックアップ（現時点の手順）

`scripts/backup.sh` を使って `/opt/homelab/` を tar で固めます。

```bash
# 自宅サーバ上で実行
sudo bash ~/homelab/06_backup/scripts/backup.sh
```

バックアップファイルは `/opt/backup/` に作成されます。

```
/opt/backup/
└── homelab_20260101_120000.tar.gz
```

### バックアップを自宅 PC に転送する（暫定）

```bash
# 自宅 PC の WSL2 上で実行
scp -i ~/.ssh/id_ed25519_homelab \
  <ユーザー名>@<自宅サーバのTailscale IP>:/opt/backup/homelab_*.tar.gz \
  ~/backup/
```

---

## リストア手順

```bash
# 自宅サーバ上で実行
# 1. サービスを停止
cd ~/homelab/04_services
make down

# 2. バックアップを展開
sudo tar -xzf /opt/backup/homelab_<日時>.tar.gz -C /

# 3. サービスを再起動
make up-core
```

---

## TODO

- [ ] バックアップ先を決定する
- [ ] バックアップ対象の優先度を整理する
- [ ] cron による自動バックアップを設定する
- [ ] バックアップの世代管理を決める（何日分残すか）
- [ ] リストア手順を実際に検証する
