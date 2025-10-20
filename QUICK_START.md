# 🚀 クイックスタートガイド

Laravel Docker 環境を素早くセットアップする方法です。

## 前提条件

- Docker Desktop がインストールされている
- Git がインストールされている

## Windows の場合

### 方法1: PowerShell スクリプトを使用（推奨）

```powershell
# PowerShellを管理者として実行
.\setup.ps1
```

### 方法2: 手動セットアップ

```powershell
# 1. .env ファイルを作成
copy .env.template .env

# 2. コンテナをビルド・起動
docker compose build
docker compose up -d

# 3. 10秒待機（データベース準備）
timeout /t 10

# 4. Composer依存関係をインストール
docker compose exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader

# 5. アプリケーションキーを生成
docker compose exec -T app php artisan key:generate --force

# 6. データベースマイグレーション
docker compose exec -T app php artisan migrate --seed --force

# 7. パーミッション設定
docker compose exec -T -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -T -u root app chown -R laravel:laravel storage bootstrap/cache
```

## Linux/Mac の場合

### 方法1: Bash スクリプトを使用（推奨）

```bash
# 実行権限を付与
chmod +x setup.sh

# スクリプト実行
./setup.sh
```

### 方法2: Make を使用

```bash
make init
```

### 方法3: 手動セットアップ

```bash
# 1. .env ファイルを作成
cp .env.template .env

# 2. コンテナをビルド・起動
docker compose build
docker compose up -d

# 3. 10秒待機（データベース準備）
sleep 10

# 4. Composer依存関係をインストール
docker compose exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader

# 5. アプリケーションキーを生成
docker compose exec -T app php artisan key:generate --force

# 6. データベースマイグレーション
docker compose exec -T app php artisan migrate --seed --force

# 7. パーミッション設定
docker compose exec -T -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -T -u root app chown -R laravel:laravel storage bootstrap/cache
```

## 🎉 セットアップ完了後

ブラウザで以下のURLにアクセスしてください：

- **アプリケーション**: http://localhost
- **Mailhog（メール確認）**: http://localhost:8025
- **ヘルスチェック**: http://localhost/health

## 📝 よく使うコマンド

```bash
# コンテナを起動
make up
# または
docker compose up -d

# コンテナを停止
make down
# または
docker compose down

# ログを表示
make logs
# または
docker compose logs -f

# コンテナにログイン
make shell
# または
docker compose exec app bash

# Artisan コマンド実行
make artisan CMD="migrate"
# または
docker compose exec app php artisan migrate

# テスト実行
make test
# または
docker compose exec app php artisan test
```

## 🔧 トラブルシューティング

### エラー: "Docker がインストールされていません"

Docker Desktop をインストールしてください：
- Windows: https://docs.docker.com/desktop/install/windows-install/
- Mac: https://docs.docker.com/desktop/install/mac-install/
- Linux: https://docs.docker.com/engine/install/

### エラー: "データベースに接続できません"

```bash
# コンテナの状態を確認
docker compose ps

# PostgreSQLが起動していない場合
docker compose restart postgres

# 再度マイグレーション実行
docker compose exec app php artisan migrate --seed --force
```

### エラー: "permission denied"

```bash
# パーミッションを修正
docker compose exec -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -u root app chown -R laravel:laravel storage bootstrap/cache
```

### ポート 80 が使用中

`.env` ファイルで別のポートを指定：

```env
APP_PORT=8080
```

その後、コンテナを再起動：

```bash
docker compose down
docker compose up -d
```

アプリケーションは http://localhost:8080 でアクセスできます。

## 📚 詳細情報

- **詳細なセットアップ**: [INSTALL.md](INSTALL.md)
- **プロジェクト概要**: [README.md](README.md)
- **パーミッション管理**: [PERMISSION_CHECK.md](PERMISSION_CHECK.md)
- **Windows環境**: [docs/WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md)

