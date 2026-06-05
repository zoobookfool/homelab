# トラブルシューティング

よくあるトラブルと対処方法をまとめています。

---

## Tailscale

### サーバに接続できない

```bash
# Tailscale の状態を確認
sudo tailscale status

# 再接続を試みる
sudo tailscale up
```

Tailscale の管理画面（https://login.tailscale.com/admin/machines）でノードの状態を確認します。
「Expired」になっている場合は再認証が必要です。

```bash
sudo tailscale up --authkey=<新しいAuth Key>
```

---

## Ansible

### `UNREACHABLE` エラーが出る

```
fatal: [xxx.xxx.xxx.xxx]: UNREACHABLE!
```

SSH 接続を確認します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<対象サーバのTailscale IP>
```

接続できない場合は Tailscale の接続状態を確認します（→ Tailscale のトラブルシューティングを参照）。

### `sudo` パスワードエラーが出る

`--ask-become-pass` を付けて実行しているか確認します。

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

---

## Docker

### コンテナが起動しない

```bash
# ログを確認
docker compose -f compose/<サービス名>.yml logs

# または Makefile 経由で
make logs-<サービス名>
```

### `.env` が読み込まれない

`04_services/` ディレクトリにいることを確認します。

```bash
cd ~/homelab/04_services
make up-mastodon
```

### ポートが競合している

使用中のポートを確認します。

```bash
sudo ss -tlnp | grep <ポート番号>
```

---

## Mastodon

### データベースのセットアップが終わっていない

初回のみ必要な手順が完了しているか確認します。

```bash
docker compose -f compose/mastodon.yml run --rm web bundle exec rails db:setup
```

### メールが届かない

`.env` の SMTP 設定を確認します。
SendGrid 等の外部 SMTP サービスの API キーが正しく設定されているか確認します。

---

## Element（Matrix Synapse）

### 設定ファイルが見つからない

初回のみ設定ファイルの生成が必要です。

```bash
docker compose -f compose/element.yml run --rm synapse generate
```

### フェデレーションができない

`matrix.example.com` の DNS レコードと Nginx 設定を確認します。
Matrix のフェデレーションテスト：https://federationtester.matrix.org/

---

## Nginx / SSL

### 証明書の取得に失敗する

DNS レコードが VPS の IP アドレスに向いているか確認します。

```bash
dig A mastodon.example.com
```

正しい IP アドレスが返ってくることを確認してから Certbot を再実行します。

### 証明書の有効期限が切れた

Certbot の自動更新が動いているか確認します。

```bash
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

---

## ゲームサーバ

### Factorio に接続できない

VPS の UFW で UDP 34197 が開いているか確認します。

```bash
sudo ufw status
```

ゲーム内のサーバブラウザではなく、直接 IP とポートで接続を試みます。

---

## 復旧手順（サーバが完全に死んだ場合）

1. 新しいサーバに Ubuntu Server 26.04 LTS をインストール
2. `git clone git@github.com:zoobookfool/homelab.git`
3. `01_initial_setup` から順番に Ansible を実行
4. バックアップデータを `/opt/homelab/` に展開
5. `make up-core` でサービスを起動
