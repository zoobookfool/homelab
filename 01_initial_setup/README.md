# 01 Initial Setup

アプリサーバの Ubuntu Server 26.04 LTS インストール直後に行う初期設定です。
この手順完了後、Ansible で自動設定できる状態になります。

---

## 前提条件

- アプリサーバに Ubuntu Server 26.04 LTS がインストール済みであること
- 操作端末に以下がインストール済みであること
  - Git（GitHub 管理用）
  - WSL2 + Ubuntu（Ansible 実行用）
  - Windows Terminal（WSL2 の操作用）

---

## 1. アプリサーバへの初期接続

サーバの種別によって初期接続方法が異なります。

### アプリサーバの場合（物理操作）

> ⚠️ アプリサーバへの **物理アクセスが必要な最初で最後の手順** です。
> 02_tailscale 完了後はすべての操作をリモートから行います。

モニター・キーボードをサーバに接続し、インストール時に作成したユーザーでログインします。

```
login: <インストール時に設定したユーザー名>
password: <インストール時に設定したパスワード>
```

IP アドレスを確認してメモします。

```bash
ip a
# inet 192.168.x.x のような行を探す
```

SSH サーバが起動していることを確認します。

```bash
sudo systemctl status ssh
```

`active (running)` と表示されていれば OK です。
表示されない場合はインストールします。

```bash
sudo apt update && sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

### VPS / AWS の場合（コンソール操作）

プロバイダの管理画面からウェブコンソール（またはシリアルコンソール）を開き、公開鍵を登録します。

```bash
mkdir -p ~/.ssh
echo "<id_ed25519_homelab.pub の内容>" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

> 💡 公開鍵は後述の手順 3 で作成します。先にキーを作成してから公開鍵を登録してください。
> サーバの IP アドレスはプロバイダの管理画面で確認できます。

---

## 2. Ansible のインストール（自宅 PC）

自宅 PC（Windows 11）の場合、WSL2 上に Ansible をインストールします。
以降の操作は **Windows Terminal で WSL2（Ubuntu）を開いて** 実行します。

> 💡 Windows Terminal は Windows 11 に標準搭載されています。
> スタートメニューから「Windows Terminal」または「Ubuntu」で起動できます。

### 2-1. WSL2 のインストール（未インストールの場合）

PowerShell を管理者権限で開いて実行します：

```powershell
wsl --install
```

再起動後、スタートメニューから「Ubuntu」を起動してユーザー名・パスワードを設定します。

### 2-2. Ansible のインストール（WSL2 の Ubuntu 上で）

```bash
sudo apt update
sudo apt install -y ansible
ansible --version
```

---

## 3. サーバ接続用 SSH キーの作成（自宅 PC）

GitHub 用のキーとは別に、サーバ接続専用のキーを作成します。
WSL2 の Ubuntu 上で実行します。

```bash
ssh-keygen -t ed25519 -C "homelab-server" -f ~/.ssh/id_ed25519_homelab
```

パスフレーズは任意です（Ansible の自動実行を考えると空でもよいです）。

### 3-1. 公開鍵をアプリサーバに登録

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub <ユーザー名>@<アプリサーバのIPアドレス>
```

### 3-2. 接続確認

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<アプリサーバのIPアドレス>
```

パスワードなしで接続できれば OK です。

> 💡 手動でサーバに繋いで作業したい場合は TeraTerm などの SSH クライアントも使えます。
> Ansible の実行には WSL2 が必要です。

---

## 4. Ansible の実行

### 4-1. リポジトリのクローン（WSL2 上で）

```bash
cd ~
git clone git@github.com:zoobookfool/homelab.git
cd homelab
```

### 4-2. inventory ファイルの作成

`01_initial_setup/ansible/` に `inventory.ini` を作成します。
このファイルは秘匿情報を含むため **Git にはコミットしません**（`.gitignore` で除外済み）。

```bash
cat > 01_initial_setup/ansible/inventory.ini << 'EOF'
[app]
<アプリサーバのIPアドレス> ansible_user=<ユーザー名> ansible_ssh_private_key_file=~/.ssh/id_ed25519_homelab
EOF
```

### 4-3. NOPASSWD 設定（Ubuntu 26.04 必須）

Ubuntu 26.04 は sudo に TTY を要求するため、Ansible から sudo を実行するには事前に NOPASSWD 設定が必要です。
SSH でサーバに接続して設定します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<アプリサーバのIPアドレス>
echo "<ユーザー名> ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/<ユーザー名>
exit
```

### 4-4. Playbook の実行

```bash
cd 01_initial_setup/ansible
ansible-playbook -i inventory.ini playbook.yml
```

---

## 5. Ansible が設定する内容

| 設定項目 | 内容 |
|---|---|
| タイムゾーン | Asia/Tokyo |
| パッケージ更新 | `apt update && apt upgrade` |
| 不要パッケージ削除 | `apt autoremove` |
| UFW 設定 | SSH（22番ポート）のみ許可、それ以外を拒否 |
| UFW 有効化 | 自動起動設定 |

---

## 完了確認

Playbook が正常終了したら、改めて SSH 接続できることを確認します。

```bash
ssh -i ~/.ssh/id_ed25519_homelab <ユーザー名>@<アプリサーバのIPアドレス>
```

接続できれば `02_tailscale` に進みます。

---

## 次の手順

→ [02_tailscale](../02_tailscale/README.md)
