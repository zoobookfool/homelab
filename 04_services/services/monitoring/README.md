# 監視ダッシュボード

Prometheus + Grafana + Node Exporter によるサーバ監視ダッシュボードです。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 1コア以上 |
| RAM | 1GB 以上 |
| ポート | 外部公開する場合は TCP 3000（Grafana） |
| ドメイン | 任意（Tailscale 経由でもアクセス可） |

---

## 起動方法

```bash
cd /opt/homelab
make up-monitoring
```

### ドメインなしで使う場合

Tailscale 経由でアクセスできます。

```
http://<自宅サーバのTailscale IP>:3000
```

初期ユーザー：`admin` / 初期パスワード：デプロイ時に設定した `GRAFANA_ADMIN_PASSWORD`

### ドメインありで外部公開する場合

[05_relay](../../../../05_relay/README.md) で `domain` を設定してください。

```
https://monitoring.<ドメイン名>
```

---

## 監視対象の追加

`services/monitoring/prometheus.yml` の `scrape_configs` にターゲットを追加します。

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
          - 'localhost:9100'        # アプリサーバ
          - '100.x.x.x:9100'       # 追加サーバ（Tailscale IP）
```

設定変更後はコンテナを再起動します。

```bash
make down-monitoring
make up-monitoring
```
