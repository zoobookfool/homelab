# Element（Matrix Synapse）

Matrix プロトコルのホームサーバ（Synapse）と Web クライアント（Element）です。

---

## このサービスだけ立てる場合の前提条件

| 項目 | 内容 |
|---|---|
| OS | Ubuntu Server 22.04 / 24.04 / 26.04 |
| CPU | 2コア以上 |
| RAM | 2GB 以上 |
| ポート | TCP 443（HTTPS） |
| ドメイン | **必須・後から変更不可**（Matrix ID に使用） |
| 外部 SMTP | 不要 |

> ⚠️ ドメインは一度決めたら変更できません。よく検討してから設定してください。

---

## 起動方法

> 💡 以下のように `compose/` 配下のファイルを直接指定するコマンドは `--env-file .env` を付けて
> `/opt/homelab` から実行してください（`-f` で指定したファイルのディレクトリがプロジェクトディレクトリと
> 認識され、`.env` が見つからず変数展開に失敗するため。`make` コマンドには同様の対策が組み込み済みです）。

### 1. 設定ファイルの生成

```bash
docker compose --env-file .env -f compose/element.yml run --rm synapse generate
```

生成された `element/synapse/homeserver.yaml`（`docker-compose.yml` の volumes 設定により `/opt/homelab/element/synapse/` 以下に生成されます）を確認・編集します。

> ⚠️ `server_name` はここで確定し、**後から変更できません**（federation の鍵やユーザー ID に紐づくため）。
> 公開 URL（`element.<ドメイン>` / `matrix.<ドメイン>`）と一致させる場合は `matrix.<ドメイン>` を、
> ルートドメインを使いたい場合は別途 `.well-known/matrix/server` の delegation 設定が必要です
> （本リポジトリの Nginx 設定には delegation 用の設定は含まれていません）。
>
> また `generate` が作る初期設定は **SQLite** です。`database:` セクションを
> [`homeserver.yaml.example`](./homeserver.yaml.example) の内容で置き換え、
> `password` を `.env` の `SYNAPSE_DB_PASSWORD` と同じ値にしてください（PostgreSQL コンテナに接続するため）。

### 2. Element Web の設定ファイルを作成

`services/element/config.json.example` をコピーして `config.json` を作成し、`m.homeserver` を実際のドメインに合わせて編集します。

```bash
cp services/element/config.json.example services/element/config.json
```

```json
"m.homeserver": {
    "base_url": "https://matrix.<ドメイン>",
    "server_name": "<手順1で設定した server_name と同じ値>"
}
```

> `config.json` は実際のドメイン名を含むため Git 管理対象外です（`.gitignore` 参照）。

### 3. 起動

```bash
make up-element
```

---

## 外部公開

[03_proxy](../../../../03_proxy/README.md) で Nginx リバースプロキシを設定してください。
Matrix フェデレーション（他のサーバと通信）には `matrix.<ドメイン名>` が必要です。

```
Element Web:        https://element.<ドメイン名>
Matrix サーバ:      https://matrix.<ドメイン名>
```

---

## ユーザー登録

デフォルトでは外部からの登録を無効化しています。
管理者が手動でアカウントを作成します。

```bash
docker exec -it synapse register_new_matrix_user \
  -u <ユーザー名> -p <パスワード> -a \
  -c /data/homeserver.yaml http://localhost:8008
```
