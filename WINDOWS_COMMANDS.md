# Windows用コマンド一覧

Windowsでは`make`コマンドが使えないため、以下の`docker compose`コマンドを直接使用してください。

## 🚀 基本コマンド

### コンテナを起動
```powershell
docker compose up -d
```

### コンテナを停止
```powershell
docker compose down
```

### コンテナを再起動
```powershell
docker compose restart
```

### コンテナの状態確認
```powershell
docker compose ps
```

### ログを表示
```powershell
# 全サービスのログ
docker compose logs -f

# 特定のサービスのログ
docker compose logs -f app
docker compose logs -f nginx
```

## 📦 Artisan コマンド

### マイグレーション
```powershell
docker compose exec app php artisan migrate
```

### マイグレーション + シーディング
```powershell
docker compose exec app php artisan migrate --seed --force
```

### シーダーのみ実行
```powershell
docker compose exec app php artisan db:seed --force
```

### キャッシュクリア
```powershell
docker compose exec app php artisan cache:clear
docker compose exec app php artisan config:clear
docker compose exec app php artisan route:clear
docker compose exec app php artisan view:clear
```

### キャッシュ最適化
```powershell
docker compose exec app php artisan config:cache
docker compose exec app php artisan route:cache
docker compose exec app php artisan view:cache
```

## 🛠️ Composer

### 依存関係のインストール
```powershell
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader
```

### 依存関係の更新
```powershell
docker compose exec app composer update --no-interaction
```

### パッケージの追加
```powershell
docker compose exec app composer require パッケージ名
```

## 🧪 テスト

### テスト実行
```powershell
docker compose exec app php artisan test
```

### カバレッジ付きテスト
```powershell
docker compose exec app php artisan test --coverage
```

## 🔍 デバッグ

### コンテナにログイン
```powershell
# 非rootユーザーでログイン
docker compose exec app bash

# rootユーザーでログイン
docker compose exec -u root app bash
```

### Tinker起動
```powershell
docker compose exec app php artisan tinker
```

## 🔄 コンテナの管理

### コンテナを再ビルド
```powershell
docker compose build
```

### コンテナを再ビルドして起動
```powershell
docker compose down
docker compose build --no-cache
docker compose up -d
```

### コンテナとボリュームを削除
```powershell
docker compose down -v
```

### 全て削除（イメージも含む）
```powershell
docker compose down -v --rmi all
```

## 📊 データベース

### PostgreSQLに接続
```powershell
docker compose exec postgres psql -U laravel -d laravel
```

### データベースのバックアップ
```powershell
docker compose exec postgres pg_dump -U laravel laravel > backup.sql
```

### データベースのリストア
```powershell
Get-Content backup.sql | docker compose exec -T postgres psql -U laravel -d laravel
```

## 🎯 便利なエイリアス設定（PowerShell）

PowerShellプロファイルに以下を追加すると便利です：

```powershell
# プロファイルを開く
notepad $PROFILE

# 以下を追加
function dc-up { docker compose up -d }
function dc-down { docker compose down }
function dc-restart { docker compose restart }
function dc-ps { docker compose ps }
function dc-logs { docker compose logs -f @args }
function dc-exec { docker compose exec app @args }
function art { docker compose exec app php artisan @args }
```

保存後、PowerShellを再起動すると以下のように使えます：
```powershell
dc-up           # docker compose up -d
dc-down         # docker compose down
dc-ps           # docker compose ps
dc-logs app     # docker compose logs -f app
art migrate     # docker compose exec app php artisan migrate
```

## 🔗 クイックリファレンス

| やりたいこと | コマンド |
|------------|---------|
| コンテナ起動 | `docker compose up -d` |
| コンテナ停止 | `docker compose down` |
| ログ確認 | `docker compose logs -f` |
| コンテナ内に入る | `docker compose exec app bash` |
| マイグレーション | `docker compose exec app php artisan migrate` |
| キャッシュクリア | `docker compose exec app php artisan cache:clear` |
| テスト実行 | `docker compose exec app php artisan test` |

## 📝 初回セットアップ（まとめ）

```powershell
# 1. .envファイル作成（初回のみ）
Copy-Item .env.example .env

# 2. ビルド
docker compose build

# 3. 起動
docker compose up -d

# 4. 依存関係インストール
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

# 5. アプリケーションキー生成
docker compose exec app php artisan key:generate --force

# 6. マイグレーション + シーディング
docker compose exec app php artisan migrate --seed --force

# 7. パーミッション設定
docker compose exec -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -u root app chown -R laravel:laravel storage bootstrap/cache
```

## 🌐 アクセスURL

- アプリケーション: http://localhost
- Mailhog: http://localhost:8025
- ヘルスチェック: http://localhost/health

