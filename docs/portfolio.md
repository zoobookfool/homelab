# ポートフォリオ

## このプロジェクトについて

Ansible・Docker Compose を使った自宅サーバの構成管理リポジトリです。
以下をポートフォリオとして公開しています。

- **Ansible による環境構築の自動化**：OS 設定・Docker 導入・サービス起動まで Playbook で管理
- **監視ダッシュボード**：Prometheus + Grafana でサーバ・サービスのメトリクスを可視化
- **手順書**：手順通りに実行すれば同じ環境を再現できる設計

---

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| 構成管理 | Ansible |
| コンテナ | Docker・Docker Compose |
| ネットワーク | Tailscale |
| 監視 | Prometheus・Grafana・Node Exporter |
| リバースプロキシ | Nginx |
| SSL | Let's Encrypt（Certbot） |
| OS | Ubuntu Server 26.04 LTS |
| バージョン管理 | Git・GitHub |

---

## 構成図

```mermaid
graph TD
    User([ユーザー])
    DNS[DNS\nexample.com → VPS IP]
    CF[Cloudflare\n将来: セキュリティ・CDN]
    VPS[VPS ConoHa\nNginx リバースプロキシ\nUDP リレー]
    TS{Tailscale\nプライベートネットワーク}
    HomeServer[自宅サーバ Ubuntu 26.04 LTS\nDocker Compose 各サービス]
    HomePC[自宅 PC\nローカル AI / Ansible 実行元]

    User -->|HTTPS| DNS
    User -->|UDP ゲームサーバ| DNS
    DNS --> VPS
    DNS -.->|将来| CF
    CF -.->|将来| VPS
    VPS <-->|Tailscale| HomeServer
    HomeServer <-->|Tailscale| HomePC
```

> 現在は DNS が VPS の IP を直接返します。
> 将来 Cloudflare のプロキシを有効にすると DNS が Cloudflare の IP を返すようになり、VPS の IP がユーザーに見えなくなります。

---

## 技術選定の理由

### Tailscale

VPN として WireGuard や SSH リバーストンネルも検討しましたが、以下の理由で Tailscale を選択しました。

- セットアップが簡単（認証キー1つでノードが参加できる）
- ノード間の Tailscale IP が固定されるため、inventory.ini の管理が楽
- タブレット・スマートフォンにも対応しており、外出先からの操作が容易
- WireGuard ベースのため通信は暗号化済み

### Docker Compose（サービスごとにファイルを分割）

全サービスを1ファイルにまとめる方法もありますが、以下の理由でサービスごとに分割しています。

- 使いたいサービスだけを選んで起動できる
- サービスごとに独立しているため、1つの設定変更が他に影響しない
- 将来サービスを追加・削除しやすい
- 別サーバへの切り離しが容易（将来対応）

### Ansible

- エージェントレス（対象サーバに特別なソフトが不要、SSH が通れば動く）
- YAML で設定を記述するため、何をしているかが読みやすい
- 冪等性があるため、復旧時に安心して何度でも実行できる
- 実行元を自宅 PC に統一することで、サーバ側の依存を最小化

### VPS をリバースプロキシ専用にした理由

- 自宅の IP アドレスを直接公開しないため、セキュリティリスクを軽減できる
- Nginx 設定をサービス側に寄せてあるため、将来 Cloudflare Tunnel に移行しやすい
- UDP ゲームサーバはどの方式でも VPS が必要なため、役割を一元化

### UFW ロックダウン設計

`02_tailscale` 完了後は SSH を含む全ポートを Tailscale 経由のみに制限しています。
Tailscale の認証を突破しない限りサーバに触れない状態になります。
個人用途のため、運用のシンプルさとセキュリティのバランスとしてこの設計が適切と判断しました。

---

## 今後の予定

### Cloudflare 導入

- Cloudflare のプロキシを有効化し、VPS の IP を隠蔽してセキュリティを強化
- HTTP/HTTPS サービスを Cloudflare Tunnel に移行し、VPS を経由しない構成も検討

### 複数 DNS プロバイダ

優先順位：冗長化 → ホップ数・遅延削減（学習目的） → サービス分離

- プライマリ／セカンダリに異なる DNS プロバイダを設定し、障害時の可用性を確保
- プロバイダごとの遅延・ルーティングの違いを検証

### 複数 VPS（踏み台）

優先順位：冗長化 → ホップ数・遅延削減（学習目的） → サービス分離

- 踏み台 VPS を複数リージョンに配置し、1台が落ちても継続稼働できる構成
- リージョンごとの遅延差を検証
- 将来的にサービスごとに VPS を分離する構成も視野に

### サービスの追加予定

| サービス | 用途 |
|---|---|
| Bluesky PDS | 分散型 SNS（AT Protocol） |
| PeerTube | 動画配信 |
| River | フィードリーダー |
| Bluecast | （用途検討中） |

### 将来対応

- サービスの別サーバへの切り離し手順
- バックアップからの自動復旧手順
