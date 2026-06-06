# Windrose サーバ

Windrose（UE5 製ゲーム）の専用サーバです。
Wine を使用して Windows 向けバイナリを Linux コンテナ上で動作させます。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 4コア以上（UE5 のため重い） |
| RAM | 8GB 以上 |
| ストレージ | 15GB 以上（Steam バイナリ約 10GB） |
| ポート | デフォルト設定ではポート開放不要 |
| Steam アカウント | **必要**（バイナリのダウンロードに使用） |

> Steam アカウントが必要なのはビルド時のみです。実行時は不要です。

---

## 起動方法

### 1. Docker・Docker Compose のインストール

```bash
curl -fsSL https://get.docker.com | sh
```

### 2. イメージのビルドと起動

Steam アカウントが必要です。

```bash
docker compose -f compose/game_windrose.yml build \
  --build-arg STEAM_USER=<Steamユーザー名> \
  --build-arg STEAM_PASS=<Steamパスワード>

docker compose -f compose/game_windrose.yml up -d
```

> Steam Guard（2段階認証）を使用している場合は、ビルド中に認証コードの入力を求められます。

### 3. 起動確認

起動には 1〜2 分かかります。以下のコマンドで招待コードを確認します。

```bash
docker exec windrose cat /server/R5/ServerDescription.json
```

`InviteCode` の値（例: `9192a58a`）が表示されれば起動完了です。

---

## 接続方法

1. 友人が Windrose を起動
2. **Play → Connect to Server** で招待コードを入力

招待コードはサーバを再起動するたびに変わります。

---

## 接続モードについて

### P2P モード（デフォルト）

`UseDirectConnection: false`（デフォルト）では Windrose のリレーサーバ経由で P2P 接続します。
**ポート開放不要**ですが、ICE ネゴシエーション時に自宅サーバの IP が相手に見える場合があります。

### 直接接続モード（IP 隠蔽）

VPS を踏み台にして自宅 IP を隠したい場合は `ServerDescription.json` を変更します。

```json
{
  "UseDirectConnection": true,
  "DirectConnectionServerAddress": "<VPSのIP>",
  "DirectConnectionServerPort": 7777
}
```

VPS 側の設定は [05_relay](../../../../05_relay/README.md) を参照してください。

---

## 技術メモ

Windrose は公式に Linux サーババイナリを提供していないため、Wine を使用して Windows 向けバイナリを動作させています。

- ランチャー（`WindroseServer.exe`）ではなく、実際のゲームバイナリ（`R5/Binaries/Win64/WindroseServer-Win64-Shipping.exe`）を直接実行
- Xvfb（仮想ディスプレイ）を用意して Wine の GUI 要求に対応
- `WINEDLLOVERRIDES="mscoree,mshtml="` で Mono・Gecko の初期化をスキップして起動を高速化
