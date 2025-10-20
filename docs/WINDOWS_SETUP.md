# Windows での開発環境セットアップ

このドキュメントでは、Windows環境でこのプロジェクトを開発する際の注意点と設定方法を説明します。

## 🔧 改行コードの問題について

### なぜ改行コードが重要か？

Windowsは改行コードに `CRLF` (`\r\n`) を使用しますが、Linux/Macでは `LF` (`\n`) を使用します。

```
Windows: CRLF (\r\n)
Linux:   LF   (\n)
```

このプロジェクトはLinux (Ubuntu) での動作を想定しているため、以下のファイルは必ず `LF` である必要があります：

- シェルスクリプト (`.sh`)
- Dockerfile
- PHP-FPM ヘルスチェックスクリプト
- Makefile

### 解決方法

このプロジェクトには改行コードの問題を自動的に解決する設定が含まれています：

#### 1. `.gitattributes` ファイル

Gitがファイルをチェックアウト/コミットする際に、自動的に正しい改行コードに変換します。

```gitattributes
# シェルスクリプトは必ずLF
*.sh text eol=lf

# Dockerファイルは必ずLF
Dockerfile text eol=lf

# PHP、YAML、JSONも必ずLF
*.php text eol=lf
*.yml text eol=lf
*.json text eol=lf
```

#### 2. `.editorconfig` ファイル

VS Codeなどのエディタが、ファイルを保存する際に正しい改行コードを使用します。

```editorconfig
[*]
end_of_line = lf
```

#### 3. `.vscode/settings.json`

VS Code固有の設定で、改行コードを強制的に `LF` にします。

```json
{
  "files.eol": "\n"
}
```

## 📋 初回セットアップ手順

### 1. Git の設定確認

```powershell
# 現在の設定を確認
git config --global core.autocrlf

# true の場合は input に変更（推奨）
git config --global core.autocrlf input
```

設定値の意味：
- `true`: チェックアウト時にCRLF、コミット時にLFに変換（Windows向け）
- `input`: チェックアウト時は変換なし、コミット時にLFに変換（推奨）
- `false`: 変換しない（非推奨）

### 2. リポジトリのクローン

```powershell
git clone <repository-url> app-linux-docker
cd app-linux-docker
```

### 3. 既存ファイルの改行コードを正規化

既にクローン済みの場合、既存のファイルを正規化します：

```powershell
# ステージング済みのファイルをクリア
git rm --cached -r .

# .gitattributes の設定に基づいて再追加
git add --renormalize .

# 変更を確認
git status
```

警告 `warning: in the working copy of 'xxx', LF will be replaced by CRLF` が出ても問題ありません。これは次回ファイルをチェックアウトする際に正しい改行コードに変換されることを意味します。

### 4. VS Code の再読み込み

設定を反映させるために VS Code を再読み込みします：

1. `Ctrl + Shift + P` を押す
2. "Reload Window" と入力して実行

## 🛠️ 開発方法

### 方法1: WSL2 を使用（推奨）

WSL2（Windows Subsystem for Linux 2）を使用すると、Windows上で本物のLinux環境が動作します。

#### WSL2 のインストール

```powershell
# PowerShell（管理者権限）で実行
wsl --install

# Ubuntu をインストール
wsl --install -d Ubuntu-22.04
```

#### WSL2 での開発

```bash
# WSL2 のシェルを起動
wsl

# プロジェクトディレクトリに移動
cd /mnt/c/path/to/app-linux-docker

# または WSL内にクローン（推奨）
cd ~
git clone <repository-url> app-linux-docker
cd app-linux-docker

# Docker のインストール（WSL2内）
# 方法1: Docker Desktop for Windows を使用
# 方法2: WSL2内に直接Dockerをインストール

# アプリケーションの起動
make up
```

#### VS Code で WSL2 を使用

1. 拡張機能 `Remote - WSL` をインストール
2. 左下の緑のアイコンをクリック
3. "WSL で再度開く" を選択

### 方法2: Git Bash を使用

Git Bash は Windows 上で Unix風のシェルを提供します。

```bash
# Git Bash を起動
cd /c/path/to/app-linux-docker

# Makefile のコマンドが使用可能
make help
```

### 方法3: PowerShell を使用

PowerShell から直接 Docker を操作することも可能です。

```powershell
# プロジェクトディレクトリに移動
cd C:\path\to\app-linux-docker

# Docker Compose を使用
docker compose up -d

# Make コマンドの代わりに Docker Compose を直接使用
docker compose exec app php artisan migrate
```

## ⚠️ よくある問題と解決方法

### 問題1: シェルスクリプトが実行できない

```bash
# エラー例
bash: ./scripts/setup-docker.sh: /bin/bash^M: bad interpreter
```

原因: 改行コードが `CRLF` になっている

解決方法:
```bash
# dos2unix を使用して変換（WSL2/Git Bash）
dos2unix scripts/setup-docker.sh

# または sed を使用
sed -i 's/\r$//' scripts/setup-docker.sh
```

### 問題2: Makefile が動作しない

```
Makefile:10: *** missing separator. Stop.
```

原因: Makefile のインデントがタブではなくスペースになっている

解決方法:
- `.editorconfig` が正しく設定されていることを確認
- VS Code の設定で Makefile がタブを使用するように設定

### 問題3: Git の警告が消えない

```
warning: in the working copy of 'xxx', LF will be replaced by CRLF
```

これは警告であり、エラーではありません。次のいずれかで解決します：

```powershell
# 方法1: グローバル設定を変更
git config --global core.autocrlf input

# 方法2: このリポジトリのみ設定
git config core.autocrlf input

# 方法3: 警告を無効化（非推奨）
git config --global core.safecrlf false
```

## 📚 推奨ツール

### 必須
- [Git for Windows](https://gitforwindows.org/)
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- [Visual Studio Code](https://code.visualstudio.com/)

### 推奨
- [WSL2](https://docs.microsoft.com/ja-jp/windows/wsl/install)
- [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701)

### VS Code 拡張機能
- Remote - WSL
- Docker
- EditorConfig for VS Code
- PHP Intelephense
- Laravel Blade Snippets

## 🔍 改行コードの確認方法

### VS Code で確認

1. ファイルを開く
2. 右下のステータスバーを確認
3. `LF` または `CRLF` が表示される
4. クリックして変更可能

### PowerShell で確認

```powershell
# ファイルの改行コードを確認
Get-Content -Raw .\scripts\setup-docker.sh | ForEach-Object { 
    if ($_ -match "`r`n") { "CRLF" } 
    elseif ($_ -match "`n") { "LF" } 
    else { "Unknown" }
}
```

### Git Bash で確認

```bash
# CRLF を含む行を検索
grep -r $'\r' scripts/
```

## 🚀 推奨ワークフロー

### WSL2 を使用する場合（推奨）

```bash
# 1. WSL2 内にプロジェクトをクローン
cd ~
git clone <repository-url> app-linux-docker

# 2. VS Code で WSL 内のフォルダを開く
code app-linux-docker

# 3. 全ての操作を WSL2 内で実行
make init
make migrate-seed
```

このワークフローでは、改行コードの問題が発生しません。

### Windows ネイティブで開発する場合

```bash
# 1. Git の設定
git config --global core.autocrlf input

# 2. クローン
git clone <repository-url>

# 3. VS Code で開く
code app-linux-docker

# 4. .gitattributes と .editorconfig が自動的に処理
# ファイルを編集・保存すると自動的にLFになる
```

## 🌐 カスタムドメインの設定

`http://laravel-app.test/` でアクセスできるようにする方法です。

### 方法1: スクリプトを使用（推奨）

```powershell
# PowerShellを管理者権限で開く
cd "プロジェクトのパス"
.\setup-hosts.ps1
```

### 方法2: 手動設定

```powershell
# 管理者権限のPowerShellで実行
notepad C:\Windows\System32\drivers\etc\hosts
```

ファイルの最後に以下を追加：
```
127.0.0.1    laravel-app.test
```

DNSキャッシュをクリア：
```powershell
ipconfig /flushdns
```

### 他のドメイン名を使用する場合

`docker/nginx/default.conf` の3行目を編集：
```nginx
server_name your-domain.test localhost;
```

hostsファイルに追加：
```
127.0.0.1    your-domain.test
```

コンテナを再起動：
```powershell
docker compose restart nginx
```

## 💻 Windows用コマンド一覧

Makeが使えない場合、以下のDocker Composeコマンドを直接使用してください。

### 基本コマンド

```powershell
# コンテナを起動
docker compose up -d

# コンテナを停止
docker compose down

# コンテナを再起動
docker compose restart

# コンテナの状態確認
docker compose ps

# ログを表示
docker compose logs -f
docker compose logs -f app  # 特定のサービス
```

### Artisan コマンド

```powershell
# マイグレーション
docker compose exec app php artisan migrate

# マイグレーション + シーディング
docker compose exec app php artisan migrate --seed --force

# キャッシュクリア
docker compose exec app php artisan cache:clear
docker compose exec app php artisan config:clear
docker compose exec app php artisan route:clear
docker compose exec app php artisan view:clear
```

### Composer

```powershell
# 依存関係のインストール
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

# 依存関係の更新
docker compose exec app composer update --no-interaction

# パッケージの追加
docker compose exec app composer require パッケージ名
```

### コンテナへのアクセス

```powershell
# 非rootユーザーでログイン
docker compose exec app bash

# rootユーザーでログイン
docker compose exec -u root app bash
```

### PowerShell エイリアス設定（オプション）

```powershell
# PowerShellプロファイルを開く
notepad $PROFILE

# 以下を追加
function dc-up { docker compose up -d }
function dc-down { docker compose down }
function dc-restart { docker compose restart }
function dc-ps { docker compose ps }
function dc-logs { docker compose logs -f @args }
function art { docker compose exec app php artisan @args }
```

保存後、以下のように使用可能：
```powershell
dc-up           # docker compose up -d
art migrate     # docker compose exec app php artisan migrate
```

## 📞 サポート

問題が解決しない場合は、以下の情報を含めてIssueを作成してください：

- Windows のバージョン
- Git のバージョン (`git --version`)
- 使用している開発環境（WSL2/Git Bash/PowerShell）
- エラーメッセージ全文

## 参考リンク

- [Git - gitattributes Documentation](https://git-scm.com/docs/gitattributes)
- [EditorConfig](https://editorconfig.org/)
- [WSL2 Installation Guide](https://docs.microsoft.com/ja-jp/windows/wsl/install)
- [Mind the End of Your Line](https://adaptivepatchwork.com/2012/03/01/mind-the-end-of-your-line/)


