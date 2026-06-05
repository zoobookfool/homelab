# ポートフォリオ

## このプロジェクトについて

Ansible・Docker Compose を使った自宅サーバの構成管理リポジトリです。
以下をポートフォリオとして公開しています。

- **Ansible による環境構築の自動化**：OS 設定・Docker 導入・サービス起動まで Playbook で管理
- **監視ダッシュボード**：Prometheus + Grafana でサーバ・サービスのメトリクスを可視化
- **手順書**：PC 操作ができるレベルの人が手順通りに実行すれば同じ環境を再現できる設計

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

## アーキテクチャ

```
インターネット（ユーザー）
    ↓ HTTPS / UDP
VPS（ConoHa）
    Nginx：HTTP/HTTPS のリバースプロキシ
    iptables / Nginx stream：UDP ゲームサーバのリレー
    ↓ Tailscale（プライベートネットワーク）
自宅サーバ（Ubuntu 26.04 LTS）
    Docker Compose：各サービスをコンテナで管理
    ↓ Tailscale
自宅 PC
    ローカル AI（Ollama 等）
    Ansible 実行元
```

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

### Cloudflare Tunnel への移行

HTTP/HTTPS サービスを将来 Cloudflare Tunnel に移行予定です。
UDP ゲームサーバは引き続き VPS 経由とします。

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
