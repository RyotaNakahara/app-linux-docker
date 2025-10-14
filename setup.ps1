# =============================================
# Laravel Docker Environment Setup Script (Windows)
# =============================================

$ErrorActionPreference = "Stop"

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "Laravel Docker 環境セットアップ" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
try {
    docker --version | Out-Null
    Write-Host "✓ Docker が見つかりました" -ForegroundColor Green
} catch {
    Write-Host "エラー: Docker がインストールされていません" -ForegroundColor Red
    Write-Host "Docker Desktop をインストールしてから再度実行してください。"
    exit 1
}

try {
    docker compose version | Out-Null
    Write-Host "✓ Docker Compose が見つかりました" -ForegroundColor Green
} catch {
    Write-Host "エラー: Docker Compose がインストールされていません" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 1: Create .env file
Write-Host "[1/7] 環境変数ファイルの作成..." -ForegroundColor Cyan
if (-not (Test-Path .env)) {
    if (Test-Path .env.example) {
        Copy-Item .env.example .env
        Write-Host "✓ .env ファイルを作成しました" -ForegroundColor Green
    } else {
        Write-Host "⚠ .env.example が見つかりません" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ .env ファイルは既に存在します" -ForegroundColor Yellow
}
Write-Host ""

# Step 2: Build containers
Write-Host "[2/7] Docker イメージのビルド..." -ForegroundColor Cyan
docker compose build
Write-Host "✓ ビルド完了" -ForegroundColor Green
Write-Host ""

# Step 3: Start containers
Write-Host "[3/7] コンテナの起動..." -ForegroundColor Cyan
docker compose up -d
Write-Host "✓ コンテナ起動完了" -ForegroundColor Green
Write-Host ""

# Step 4: Wait for database
Write-Host "[4/7] データベースの準備待機..." -ForegroundColor Cyan
Start-Sleep -Seconds 10
Write-Host "✓ データベース準備完了" -ForegroundColor Green
Write-Host ""

# Step 5: Install Composer dependencies
Write-Host "[5/7] Composer 依存関係のインストール..." -ForegroundColor Cyan
docker compose exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader
Write-Host "✓ Composer インストール完了" -ForegroundColor Green
Write-Host ""

# Step 6: Generate application key
Write-Host "[6/7] アプリケーションキーの生成..." -ForegroundColor Cyan
docker compose exec -T app php artisan key:generate --force
Write-Host "✓ アプリケーションキー生成完了" -ForegroundColor Green
Write-Host ""

# Step 7: Run migrations and seeders
Write-Host "[7/7] データベースマイグレーションとシーディング..." -ForegroundColor Cyan
docker compose exec -T app php artisan migrate --seed --force
Write-Host "✓ マイグレーション完了" -ForegroundColor Green
Write-Host ""

# Fix permissions
Write-Host "パーミッションの設定..." -ForegroundColor Cyan
docker compose exec -T -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -T -u root app chown -R laravel:laravel storage bootstrap/cache
Write-Host "✓ パーミッション設定完了" -ForegroundColor Green
Write-Host ""

# Display status
Write-Host "===================================" -ForegroundColor Green
Write-Host "セットアップ完了！" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""
Write-Host "アプリケーションにアクセス:" -ForegroundColor Yellow
Write-Host "  → アプリ: " -NoNewline
Write-Host "http://localhost" -ForegroundColor Green
Write-Host "  → Mailhog: " -NoNewline
Write-Host "http://localhost:8025" -ForegroundColor Green
Write-Host "  → ヘルスチェック: " -NoNewline
Write-Host "http://localhost/health" -ForegroundColor Green
Write-Host ""
Write-Host "便利なコマンド:" -ForegroundColor Yellow
Write-Host "  make logs        - ログを表示"
Write-Host "  make shell       - コンテナにログイン"
Write-Host "  make test        - テストを実行"
Write-Host "  make down        - コンテナを停止"
Write-Host ""
Write-Host "セットアップが完了しました！" -ForegroundColor Green

