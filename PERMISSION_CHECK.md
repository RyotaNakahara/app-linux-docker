# Laravelパーミッションチェックガイド

Dockerコンテナ内のLaravelアプリケーションのパーミッションを確認・検証するためのコマンド集です。

## 目次

- [基本的なパーミッションチェック](#基本的なパーミッションチェック)
- [詳細なディレクトリチェック](#詳細なディレクトリチェック)
- [書き込み権限のテスト](#書き込み権限のテスト)
- [Laravel環境の確認](#laravel環境の確認)
- [トラブルシューティング](#トラブルシューティング)

---

## 基本的なパーミッションチェック

### 実行ユーザーの確認

現在のコンテナ内で実行しているユーザーとグループを確認：

```bash
docker compose exec app id
```

**期待される出力:**
```
uid=1000(laravel) gid=1000(laravel) groups=1000(laravel)
```

### 重要なディレクトリのパーミッション確認

storageディレクトリのパーミッションを確認：

```bash
docker compose exec app ls -la /var/www/html/storage
```

bootstrap/cacheディレクトリのパーミッションを確認：

```bash
docker compose exec app ls -la /var/www/html/bootstrap/cache
```

ルートディレクトリから重要なディレクトリを確認：

```bash
docker compose exec app ls -la /var/www/html | grep -E "storage|bootstrap"
```

**期待される出力:**
```
drwxrwxr-x    1 laravel  laravel       4096 Oct 14 07:07 storage
drwxrwxrwx    1 root     root          4096 Oct 14 07:07 bootstrap
```

---

## 詳細なディレクトリチェック

### storageディレクトリツリー全体を確認

```bash
docker compose exec app sh -c "find /var/www/html/storage -type d -exec ls -ld {} \;"
```

### 特定のサブディレクトリを確認

framework/cacheディレクトリ：

```bash
docker compose exec app ls -la /var/www/html/storage/framework/cache
```

framework/sessionsディレクトリ：

```bash
docker compose exec app ls -la /var/www/html/storage/framework/sessions
```

framework/viewsディレクトリ：

```bash
docker compose exec app ls -la /var/www/html/storage/framework/views
```

logsディレクトリ：

```bash
docker compose exec app ls -la /var/www/html/storage/logs
```

---

## 書き込み権限のテスト

### Shellレベルでの書き込みテスト

storage/logsディレクトリの書き込み権限をテスト：

```bash
docker compose exec app sh -c "test -w /var/www/html/storage/logs && echo 'writable' || echo 'NOT writable'"
```

bootstrap/cacheディレクトリの書き込み権限をテスト：

```bash
docker compose exec app sh -c "test -w /var/www/html/bootstrap/cache && echo 'writable' || echo 'NOT writable'"
```

### PHPレベルでの書き込みテスト

PHPから見た書き込み権限を確認：

```bash
docker compose exec app php -r "echo is_writable('/var/www/html/storage/logs') ? '✓ storage/logs: writable' : '✗ storage/logs: NOT writable'; echo PHP_EOL;"
```

bootstrap/cacheの書き込み権限を確認：

```bash
docker compose exec app php -r "echo is_writable('/var/www/html/bootstrap/cache') ? '✓ bootstrap/cache: writable' : '✗ bootstrap/cache: NOT writable'; echo PHP_EOL;"
```

### 実際にファイルを作成してテスト

テストファイルを作成：

```bash
docker compose exec app sh -c "echo 'test' > /var/www/html/storage/logs/permission-test.txt && echo 'File created successfully' || echo 'Failed to create file'"
```

テストファイルを削除：

```bash
docker compose exec app rm /var/www/html/storage/logs/permission-test.txt
```

---

## Laravel環境の確認

### Laravel設定の確認

```bash
docker compose exec app php artisan about
```

環境、キャッシュ、セッションの設定のみを表示：

```bash
docker compose exec app php artisan about | grep -E "Environment|Cache|Session"
```

### ログファイルの確認

最新のログファイルを確認：

```bash
docker compose exec app ls -lh /var/www/html/storage/logs/laravel.log
```

ログファイルの最後の50行を表示：

```bash
docker compose exec app tail -50 /var/www/html/storage/logs/laravel.log
```

### キャッシュディレクトリの状態確認

```bash
docker compose exec app ls -lh /var/www/html/bootstrap/cache/
```

---

## トラブルシューティング

### パーミッションエラーが発生した場合

#### 1. オーナーシップの修正

rootユーザーとして実行（コンテナ内）：

```bash
docker compose exec -u root app chown -R laravel:laravel /var/www/html/storage
docker compose exec -u root app chown -R laravel:laravel /var/www/html/bootstrap/cache
```

#### 2. パーミッションの修正

```bash
docker compose exec -u root app chmod -R 775 /var/www/html/storage
docker compose exec -u root app chmod -R 775 /var/www/html/bootstrap/cache
```

#### 3. 全て一括で修正

```bash
docker compose exec -u root app sh -c "chown -R laravel:laravel storage bootstrap/cache && chmod -R 775 storage bootstrap/cache"
```

### キャッシュのクリア

設定キャッシュをクリア：

```bash
docker compose exec app php artisan config:clear
```

全てのキャッシュをクリア：

```bash
docker compose exec app php artisan cache:clear
```

ビューキャッシュをクリア：

```bash
docker compose exec app php artisan view:clear
```

ルートキャッシュをクリア：

```bash
docker compose exec app php artisan route:clear
```

### コンテナの再起動

パーミッション修正後、コンテナを再起動：

```bash
docker compose restart app
```

---

## 一括チェックスクリプト

全てのパーミッションを一度にチェック：

```bash
#!/bin/bash
echo "=== User Information ==="
docker compose exec app id

echo -e "\n=== Storage Directory ==="
docker compose exec app ls -la /var/www/html/storage

echo -e "\n=== Bootstrap Cache Directory ==="
docker compose exec app ls -la /var/www/html/bootstrap/cache

echo -e "\n=== Write Permission Tests ==="
docker compose exec app sh -c "test -w /var/www/html/storage/logs && echo '✓ storage/logs: writable' || echo '✗ storage/logs: NOT writable'"
docker compose exec app sh -c "test -w /var/www/html/bootstrap/cache && echo '✓ bootstrap/cache: writable' || echo '✗ bootstrap/cache: NOT writable'"

echo -e "\n=== Laravel Environment ==="
docker compose exec app php artisan about | grep -E "Environment|Cache|Session"

echo -e "\n=== Log Files ==="
docker compose exec app ls -lh /var/www/html/storage/logs/
```

このスクリプトを`check-permissions.sh`として保存し、実行権限を与えて使用：

```bash
chmod +x check-permissions.sh
./check-permissions.sh
```

---

## 推奨パーミッション設定

### 開発環境

```
storage/          : 775 (drwxrwxr-x) - laravel:laravel
bootstrap/cache/  : 775 (drwxrwxr-x) - laravel:laravel
```

### 本番環境

```
storage/          : 755 (drwxr-xr-x) - laravel:laravel
bootstrap/cache/  : 755 (drwxr-xr-x) - laravel:laravel
```

### ファイル

```
.env              : 600 (-rw-------) - laravel:laravel
logs/*.log        : 644 (-rw-r--r--) - laravel:laravel
```

---

## CI/CD環境でのパーミッションチェック

GitHub Actionsなどで自動チェックを行う場合：

```yaml
- name: Check permissions
  run: |
    docker compose exec -T app id
    docker compose exec -T app ls -la /var/www/html/storage
    docker compose exec -T app sh -c "test -w /var/www/html/storage/logs && echo 'OK' || exit 1"
    docker compose exec -T app sh -c "test -w /var/www/html/bootstrap/cache && echo 'OK' || exit 1"
```

---

## 参考リンク

- [Laravel Documentation - Directory Structure](https://laravel.com/docs/11.x/structure)
- [Laravel Documentation - Deployment](https://laravel.com/docs/11.x/deployment)
- [Docker Documentation - User namespace remapping](https://docs.docker.com/engine/security/userns-remap/)

---

## 更新履歴

- 2025-10-16: 初版作成

