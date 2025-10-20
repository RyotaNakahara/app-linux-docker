#!/bin/bash

# =============================================
# Laravel Docker Environment Setup Script
# =============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==================================="
echo -e "Laravel Docker 環境セットアップ"
echo -e "===================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}エラー: Docker がインストールされていません${NC}"
    echo "Docker をインストールしてから再度実行してください。"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}エラー: Docker Compose がインストールされていません${NC}"
    echo "Docker Compose をインストールしてから再度実行してください。"
    exit 1
fi

echo -e "${GREEN}✓ Docker と Docker Compose が見つかりました${NC}"
echo ""

# Step 1: Create .env file
echo -e "${BLUE}[1/7] 環境変数ファイルの作成...${NC}"
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ .env ファイルを作成しました${NC}"
    else
        echo -e "${YELLOW}⚠ .env.example が見つかりません${NC}"
    fi
else
    echo -e "${YELLOW}⚠ .env ファイルは既に存在します${NC}"
fi
echo ""

# Step 2: Build containers
echo -e "${BLUE}[2/7] Docker イメージのビルド...${NC}"
docker compose build
echo -e "${GREEN}✓ ビルド完了${NC}"
echo ""

# Step 3: Start containers
echo -e "${BLUE}[3/7] コンテナの起動...${NC}"
docker compose up -d
echo -e "${GREEN}✓ コンテナ起動完了${NC}"
echo ""

# Step 4: Wait for database
echo -e "${BLUE}[4/7] データベースの準備待機...${NC}"
sleep 10
echo -e "${GREEN}✓ データベース準備完了${NC}"
echo ""

# Step 5: Install Composer dependencies
echo -e "${BLUE}[5/7] Composer 依存関係のインストール...${NC}"
docker compose exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader
echo -e "${GREEN}✓ Composer インストール完了${NC}"
echo ""

# Step 6: Generate application key
echo -e "${BLUE}[6/7] アプリケーションキーの生成...${NC}"
docker compose exec -T app php artisan key:generate --force
echo -e "${GREEN}✓ アプリケーションキー生成完了${NC}"
echo ""

# Step 7: Run migrations and seeders
echo -e "${BLUE}[7/7] データベースマイグレーションとシーディング...${NC}"
docker compose exec -T app php artisan migrate --seed --force
echo -e "${GREEN}✓ マイグレーション完了${NC}"
echo ""

# Fix permissions
echo -e "${BLUE}パーミッションの設定...${NC}"
docker compose exec -T -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -T -u root app chown -R laravel:laravel storage bootstrap/cache
echo -e "${GREEN}✓ パーミッション設定完了${NC}"
echo ""

# Display status
echo -e "${GREEN}==================================="
echo -e "セットアップ完了！"
echo -e "===================================${NC}"
echo ""
echo -e "${YELLOW}アプリケーションにアクセス:${NC}"
echo -e "  ${BLUE}→${NC} アプリ: ${GREEN}http://localhost${NC}"
echo -e "  ${BLUE}→${NC} Mailhog: ${GREEN}http://localhost:8025${NC}"
echo -e "  ${BLUE}→${NC} ヘルスチェック: ${GREEN}http://localhost/health${NC}"
echo ""
echo -e "${YELLOW}便利なコマンド:${NC}"
echo -e "  ${BLUE}make logs${NC}        - ログを表示"
echo -e "  ${BLUE}make shell${NC}       - コンテナにログイン"
echo -e "  ${BLUE}make test${NC}        - テストを実行"
echo -e "  ${BLUE}make down${NC}        - コンテナを停止"
echo ""
echo -e "${GREEN}セットアップが完了しました！${NC}"

