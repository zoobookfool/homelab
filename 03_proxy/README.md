# 03 Proxy

Nginx リバースプロキシを設定します。

## パターン

| パターン | 対象 | SSL | inventory |
|---|---|---|---|
| A | アプリサーバ (`[app]`) | Let's Encrypt（Certbot 自動取得） | アプリサーバの Tailscale IP |
| B | 踏み台サーバ (`[relay]`) | Cloudflare Origin Certificate | 踏み台サーバの IP |

`ansible/playbook.yml` に記載された vars を設定してから実行します。

---

## Cloudflare Origin Certificate の準備（パターンB）

1. Cloudflare ダッシュボード → **SSL/TLS → Origin Server → Create Certificate** で証明書を生成
2. ローカルに保存

```bash
mkdir -p ~/.ssl
# 証明書を ~/.ssl/<ドメイン>.pem に保存
# 秘密鍵を ~/.ssl/<ドメイン>.key に保存
```

Ansible 実行時に自動でサーバへ配置されます。

---

セットアップ手順は [docs/setup.md](../docs/setup.md) を参照してください。
