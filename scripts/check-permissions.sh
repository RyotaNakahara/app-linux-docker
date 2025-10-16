#!/bin/bash

# =============================================
# パーミッションチェックスクリプト
# Laravel Docker環境のパーミッションを検証
# =============================================

set -e

echo "=== Permission Check ==="
echo ""

# 実行ユーザーの確認
echo "1. Checking user and group..."
user_info=$(docker compose exec -T app id)
echo "$user_info"
if echo "$user_info" | grep -q "uid=1000(laravel) gid=1000(laravel)"; then
  echo "✓ User and group correct"
else
  echo "✗ User or group incorrect"
  exit 1
fi

# storageディレクトリのパーミッション確認
echo ""
echo "2. Checking storage directory..."
storage_perms=$(docker compose exec -T app ls -ld /var/www/html/storage | awk '{print $1, $3, $4}')
echo "$storage_perms"
if echo "$storage_perms" | grep -q "laravel laravel"; then
  echo "✓ Storage directory ownership correct"
else
  echo "✗ Storage directory ownership incorrect"
  exit 1
fi

# bootstrap/cacheディレクトリのパーミッション確認
echo ""
echo "3. Checking bootstrap/cache directory..."
cache_perms=$(docker compose exec -T app ls -ld /var/www/html/bootstrap/cache | awk '{print $1, $3, $4}')
echo "$cache_perms"
if echo "$cache_perms" | grep -q "laravel laravel"; then
  echo "✓ Bootstrap cache directory ownership correct"
else
  echo "✗ Bootstrap cache directory ownership incorrect"
  exit 1
fi

# 書き込み権限テスト - storage/logs
echo ""
echo "4. Testing write permission - storage/logs..."
if docker compose exec -T app sh -c "test -w /var/www/html/storage/logs && echo 'writable'" | grep -q "writable"; then
  echo "✓ storage/logs is writable"
else
  echo "✗ storage/logs is NOT writable"
  exit 1
fi

# 書き込み権限テスト - bootstrap/cache
echo ""
echo "5. Testing write permission - bootstrap/cache..."
if docker compose exec -T app sh -c "test -w /var/www/html/bootstrap/cache && echo 'writable'" | grep -q "writable"; then
  echo "✓ bootstrap/cache is writable"
else
  echo "✗ bootstrap/cache is NOT writable"
  exit 1
fi

# PHPから見た書き込み権限テスト
echo ""
echo "6. Testing write permission from PHP..."
php_test=$(docker compose exec -T app php -r "echo is_writable('/var/www/html/storage/logs') ? 'writable' : 'not_writable';")
if [ "$php_test" = "writable" ]; then
  echo "✓ storage/logs is writable from PHP"
else
  echo "✗ storage/logs is NOT writable from PHP"
  exit 1
fi

# 実際にファイルを作成してテスト
echo ""
echo "7. Testing actual file creation..."
if docker compose exec -T app sh -c "echo 'test' > /var/www/html/storage/logs/permission-test.txt && rm /var/www/html/storage/logs/permission-test.txt && echo 'success'" | grep -q "success"; then
  echo "✓ File creation and deletion successful"
else
  echo "✗ File creation or deletion failed"
  exit 1
fi

# ログファイルの存在確認
echo ""
echo "8. Checking Laravel log file..."
if docker compose exec -T app test -f /var/www/html/storage/logs/laravel.log; then
  log_info=$(docker compose exec -T app ls -lh /var/www/html/storage/logs/laravel.log | awk '{print $1, $3, $4, $5}')
  echo "✓ Laravel log file exists: $log_info"
else
  echo "⚠ Laravel log file does not exist yet (this is OK for fresh install)"
fi

# 詳細情報の表示
echo ""
echo "=== Detailed Information ==="
echo ""
echo "Storage directory structure:"
docker compose exec -T app find /var/www/html/storage -type d -maxdepth 2 -exec ls -ld {} \; 2>/dev/null | head -10

echo ""
echo "Bootstrap cache contents:"
docker compose exec -T app ls -lh /var/www/html/bootstrap/cache/ 2>/dev/null | head -5

echo ""
echo "✓ All permission checks passed!"

