# ローカル AI 踏み台

自宅 PC で動かしている Ollama（ローカル LLM）を外出先から使えるようにする Nginx プロキシです。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 1コア以上 |
| RAM | 512MB 以上 |
| ポート | 外部公開する場合は TCP 443（踏み台経由） |
| ドメイン | 任意（Tailscale 経由でも使用可） |
| 自宅 PC | Ollama が起動していること・Tailscale に参加していること |

---

## 起動方法

### 1. 自宅 PC の準備

[Ollama](https://ollama.com) をインストールして起動します。

```bash
ollama serve
```

Tailscale 経由でアクセスできるよう、Ollama のリッスンアドレスを設定します。

```bash
# ~/.bashrc や /etc/systemd/system/ollama.service に追加
export OLLAMA_HOST=0.0.0.0
```

> ⚠️ `0.0.0.0` は Tailscale だけでなく PC の全ネットワークインターフェース（LAN・場合によっては WAN）で
> Ollama の API（認証なし）を待ち受ける設定です。自宅ルーターのポート開放・UPnP 等で
> 11434 番ポートが外部に転送されていないこと、また LAN 内の他端末からのアクセスを許容してよいかを確認してください。
> より厳密に絞りたい場合は `0.0.0.0` の代わりに PC の Tailscale IP（`100.x.x.x`）を指定すると、
> Tailscale 経由のアクセスのみに制限できます。

### 2. 環境変数を設定

`/opt/homelab/.env` に Ollama が動いている PC の Tailscale IP とポート番号を設定します。

```
LOCAL_PC_TAILSCALE_IP=<自宅PCのTailscale IP>
OLLAMA_PORT=11434
```

### 3. 起動

```bash
make up-ai-proxy
```

---

## 使い方

### Tailscale 経由（ドメインなし）

```bash
curl http://<自宅サーバのTailscale IP>:11435/api/generate \
  -d '{"model": "llama3", "prompt": "Hello"}'
```

### 外部公開（ドメインあり）

[05_relay](../../../../05_relay/README.md) で Nginx リバースプロキシを設定してください。

```
https://ai.<ドメイン名>/api/generate
```

> ⚠️ 外部公開する場合は認証を追加することを強く推奨します。
> `services/ai_proxy/nginx.conf.example` を参考に Basic 認証等を設定してください。
