# homelab

自宅サーバの環境構築・運用管理リポジトリです。
Ansible・Docker Compose を使ってサービスを自動構築します。

---

## 構成概要

```
インターネット
    ↓
VPS（ConoHa）- Nginx リバースプロキシ・UDP リレー
    ↓ Tailscale
自宅サーバ（Ubuntu 26.04 LTS）- 各サービスを Docker で稼働
    ↓ Tailscale
自宅 PC - ローカル AI（Ollama 等）・Ansible 実行元
```

---

## 稼働サービス

| サービス | 用途 |
|---|---|
| 監視ダッシュボード | Prometheus + Grafana |
| Mastodon | 分散型 SNS |
| Element | Matrix 対応チャット |
| Discord Bot | サービス死活通知 |
| ローカル AI 踏み台 | 自宅 PC の AI への中継 |
| Factorio サーバ | ゲームサーバ |
| Windrose（UE5） | ゲームサーバ |

---

## 前提条件

- 自宅サーバ：第 8 世代 Intel CPU・RAM 16GB 以上
- OS：Ubuntu Server 26.04 LTS
- VPS：ConoHa 1 コア・RAM 1GB 以上
- ネットワーク：Tailscale（自宅サーバ・自宅 PC・VPS・タブレットを接続）
- 操作端末：Windows 11（WSL2 + Ansible・Git）
- ドメイン取得済みであること

---

## 手順

手順は番号順に実行します。
**復旧時も 01 から順番に実行することで同じ環境を再現できます。**

| 手順 | 内容 |
|---|---|
| [01_initial_setup](./01_initial_setup/README.md) | OS 初期設定・SSH・UFW 基本設定 |
| [02_tailscale](./02_tailscale/README.md) | Tailscale 導入・UFW 強化（Tailscale 以外を遮断） |
| [03_docker](./03_docker/README.md) | Docker・Docker Compose インストール |
| [04_services](./04_services/README.md) | 各サービスの起動 |
| [05_vps](./05_vps/README.md) | VPS の Nginx・UDP リレー設定 |
| [06_backup](./06_backup/README.md) | バックアップ設定 |

---

## サービスの起動方法

`04_services/` に移動して `make` コマンドで起動します。

```bash
cd 04_services

# サービスを個別に起動
make up-mastodon
make up-monitoring
make up-element
make up-game-factorio

# 常時起動サービスをまとめて起動
make up-core

# すべて停止
make down
```

詳細は [04_services/README.md](./04_services/README.md) を参照してください。

---

## 秘匿情報の管理

以下のファイルは `.gitignore` で除外しています。各手順の README を参照して作成してください。

- `*/ansible/inventory.ini`（サーバの IP アドレス・ユーザー名）
- `04_services/.env`（ドメイン名・パスワード等）
- SSH 秘密鍵（`~/.ssh/id_ed25519_homelab`）
- Tailscale Auth Key

---

## ライセンス

MIT
