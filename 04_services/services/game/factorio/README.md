# Factorio サーバ

Factorio 1.1（DLC なし）の専用サーバです。
DLC（Space Age）を持たない全プレイヤーが参加できます。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 2コア以上 |
| RAM | 2GB 以上 |
| ポート | UDP 34197（外部に公開する場合） |
| ドメイン | 不要 |
| Steam アカウント | 不要（公式 Docker イメージを使用） |

---

## 起動方法

### 1. Docker・Docker Compose のインストール

```bash
curl -fsSL https://get.docker.com | sh
```

### 2. ファイルの配置

```bash
mkdir -p /opt/homelab/{compose,services/game/factorio}
# compose/game_factorio.yml と .env をサーバに配置
```

### 3. 起動

```bash
cd /opt/homelab
docker compose --env-file .env -f compose/game_factorio.yml up -d
```

起動後、`/opt/homelab/game/factorio/` にサーバ設定ファイルが自動生成されます。

---

## 接続方法

### 直接接続

```
Factorio → マルチプレイヤー → 直接接続 → <サーバのIP>:34197
```

### サーバリスト公開（任意）

`/opt/homelab/game/factorio/config/server-settings.json` を編集：

```json
{
  "name": "サーバ名",
  "description": "説明",
  "visibility": {
    "public": true,
    "steam": true,
    "lan": false
  },
  "game_password": ""
}
```

公開する場合は [Factorio サービスアカウント](https://www.factorio.com/profile) でトークンを取得し、
`username` と `token` を設定してください。

---

## ポート開放

VPS / クラウドを使う場合はファイアウォールで UDP 34197 を開放します。

```bash
sudo ufw allow 34197/udp
```

自宅サーバの場合はルータのポートフォワーディングも必要です。

**自宅 IP を隠したい場合：** VPS を踏み台にして UDP リレーを設定してください（→ [05_relay](../../../../05_relay/README.md)）。

---

## バージョンについて

| タグ | バージョン | 備考 |
|---|---|---|
| `1.1` | Factorio 1.1.x | DLC 不要・全員参加可 |
| `stable` | Factorio 2.0.x | Space Age DLC 必須 |

DLC を持つプレイヤー同士のサーバには `stable` タグを使用してください。
