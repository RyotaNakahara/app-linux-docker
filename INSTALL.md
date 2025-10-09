# インストールガイド

このドキュメントでは、Laravel Docker環境の詳細なセットアップ手順を説明します。

## 📋 前提条件

### ハードウェア要件
- CPU: 2コア以上推奨
- メモリ: 最低2GB、推奨4GB以上
- ストレージ: 最低10GB以上の空き容量

### ソフトウェア要件
- OS: Ubuntu 20.04 LTS / 22.04 LTS / 24.04 LTS
- Docker: 24.0以降
- Docker Compose: V2
- Git
- Make

## 🚀 クイックスタート（開発環境）

### 1. リポジトリのクローン

```bash
git clone <repository-url> app-linux-docker
cd app-linux-docker
```

### 2. Laravelプロジェクトの配置

#### 新規プロジェクトの場合

```bash
# Composerがホストにインストールされている場合
composer create-project laravel/laravel temp-laravel
mv temp-laravel/* temp-laravel/.* . 2>/dev/null || true
rm -rf temp-laravel

# またはDockerを使用
docker run --rm -v $(pwd):/app composer create-project laravel/laravel .
```

#### 既存プロジェクトの場合

```bash
# プロジェクトファイルをこのディレクトリにコピー
# または既存のLaravelプロジェクトリポジトリにこのDocker環境をマージ
```

### 3. 環境変数の設定

```bash
cp .env.sample .env
```

`.env` ファイルを編集：

```env
APP_NAME=MyApp
APP_ENV=local
APP_DEBUG=true

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=your_secure_password_here

REDIS_HOST=redis
REDIS_PORT=6379
```

### 4. 起動

```bash
# 初回セットアップ
make init

# これにより以下が自動実行されます：
# - .env ファイルの作成（存在しない場合）
# - コンテナの起動
# - Composerパッケージのインストール
# - アプリケーションキーの生成
# - データベースマイグレーション
# - シーダーの実行
```

### 5. アクセス確認

ブラウザで以下のURLにアクセス：

- アプリケーション: http://localhost
- Mailhog: http://localhost:8025

## 🏭 本番環境セットアップ

### ステップ1: サーバーの準備

```bash
# Ubuntu サーバーにSSH接続
ssh user@your-server-ip

# システムアップデート
sudo apt update && sudo apt upgrade -y
```

### ステップ2: Dockerのインストール

```bash
# プロジェクトのクローン
git clone <repository-url> /var/www/app
cd /var/www/app

# Dockerインストールスクリプトの実行
sudo bash scripts/setup-docker.sh
```

スクリプトの指示に従い、ユーザー名を入力してください。

### ステップ3: セキュリティ設定

```bash
# セキュリティハードニングスクリプトの実行
sudo bash scripts/setup-host-security.sh
```

このスクリプトは以下を行います：

1. **SSH鍵認証の設定**
   - SSH公開鍵の登録
   - パスワード認証の無効化
   - root ログインの禁止

2. **ファイアウォール（UFW）の設定**
   - デフォルトで全ての受信接続を拒否
   - SSH、HTTP、HTTPSのみ許可
   - オプションでデータベースポートの開放

3. **Fail2ban の設定**
   - SSH、Nginxへのブルートフォース攻撃対策
   - 自動的に攻撃元IPをブロック

4. **自動セキュリティアップデート**

⚠️ **重要な注意事項**:
- スクリプト実行前に、SSH公開鍵を用意してください
- スクリプト実行後は、現在のSSHセッションを維持したまま、**必ず別のターミナルで接続テストを行ってください**
- パスワード認証が無効になるため、鍵認証が機能しない場合ログインできなくなります

```bash
# 別のターミナルで接続テスト
ssh user@your-server-ip

# 接続成功を確認してから、元のセッションを閉じる
```

### ステップ4: アプリケーションのデプロイ

```bash
# グループ変更を反映させるため、再ログイン
exit
ssh user@your-server-ip
cd /var/www/app

# 環境変数の設定
cp .env.sample .env
nano .env
```

本番環境用の `.env` 設定例：

```env
APP_NAME=MyApp
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=your_very_strong_password_here

REDIS_HOST=redis
REDIS_PASSWORD=redis_password_here

# メール設定（実際のSMTPサーバーを使用）
MAIL_MAILER=smtp
MAIL_HOST=smtp.your-provider.com
MAIL_PORT=587
MAIL_USERNAME=your_email@example.com
MAIL_PASSWORD=your_email_password
MAIL_ENCRYPTION=tls
```

### ステップ5: アプリケーションの起動

```bash
# コンテナのビルドと起動
make build
make up

# Laravelのセットアップ
make composer-install
make artisan CMD="key:generate"
make migrate-seed
make optimize
```

### ステップ6: HTTPS化（Let's Encrypt）

```bash
# Certbot のインストール
sudo apt install -y certbot python3-certbot-nginx

# Nginx の一時停止（80番ポートを開放）
make down

# SSL証明書の取得
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Nginx SSL設定の追加
sudo nano docker/nginx/default.conf
```

SSL対応のNginx設定例：

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    root /var/www/html/public;
    index index.php index.html;
    
    # ... 残りの設定は既存のdefault.confから
}
```

docker-compose.yml に証明書のマウントを追加：

```yaml
  nginx:
    # ... 既存の設定
    volumes:
      - ./:/var/www/html:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro  # 追加
```

再起動：

```bash
make up
```

### ステップ7: 証明書の自動更新設定

```bash
# Cron ジョブの設定
sudo crontab -e

# 以下を追加（毎日深夜2時に証明書をチェック）
0 2 * * * certbot renew --quiet --post-hook "cd /var/www/app && docker compose restart nginx"
```

## 🔧 追加設定

### ログローテーション

```bash
sudo nano /etc/logrotate.d/laravel
```

```
/var/www/app/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        docker compose -f /var/www/app/docker-compose.yml exec app php artisan cache:clear > /dev/null 2>&1 || true
    endscript
}
```

### バックアップスクリプト

```bash
sudo nano /usr/local/bin/backup-laravel.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/laravel"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# データベースバックアップ
docker compose -f /var/www/app/docker-compose.yml exec -T postgres \
    pg_dump -U laravel laravel | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# アプリケーションファイルのバックアップ
tar -czf "$BACKUP_DIR/files_$DATE.tar.gz" -C /var/www app/storage app/.env

# 古いバックアップの削除（30日以上前）
find "$BACKUP_DIR" -name "*.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

実行権限の付与とCron設定：

```bash
sudo chmod +x /usr/local/bin/backup-laravel.sh
sudo crontab -e

# 毎日午前3時にバックアップ
0 3 * * * /usr/local/bin/backup-laravel.sh >> /var/log/laravel-backup.log 2>&1
```

## 📊 監視設定

### Fail2ban ステータス確認

```bash
# 全体のステータス
sudo fail2ban-client status

# SSH の詳細
sudo fail2ban-client status sshd

# バンされたIPの確認
sudo fail2ban-client status sshd | grep "Banned IP"
```

### UFW ステータス確認

```bash
# ファイアウォールのステータス
sudo ufw status verbose

# ログの確認
sudo tail -f /var/log/ufw.log
```

### Docker リソース監視

```bash
# コンテナのリソース使用状況
docker stats

# ディスク使用量
docker system df
```

## 🐛 トラブルシューティング

### 問題: SSH接続できない

```bash
# 別の方法でサーバーにアクセス（コンソール等）
sudo systemctl status sshd
sudo tail -f /var/log/auth.log

# SSH設定の確認
sudo nano /etc/ssh/sshd_config

# 一時的にパスワード認証を有効化（緊急時のみ）
# PasswordAuthentication yes
sudo systemctl restart sshd
```

### 問題: データベース接続エラー

```bash
# PostgreSQLの状態確認
make logs SERVICE=postgres

# コンテナの再起動
make restart

# データベースへの直接接続テスト
docker compose exec postgres psql -U laravel -d laravel
```

### 問題: パーミッションエラー

```bash
# コンテナ内でパーミッション修正
make shell-root
chown -R laravel:laravel storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
exit

# ホスト側でのパーミッション修正
sudo chown -R $USER:$USER .
```

## 📝 チェックリスト

本番環境デプロイ前に確認：

- [ ] `.env` ファイルの本番設定完了
- [ ] `APP_ENV=production`
- [ ] `APP_DEBUG=false`
- [ ] 強力なデータベースパスワード設定
- [ ] SSH鍵認証の動作確認
- [ ] UFWファイアウォールの設定確認
- [ ] Fail2banの動作確認
- [ ] SSL証明書の取得と設定
- [ ] バックアップスクリプトの設定
- [ ] ログローテーションの設定
- [ ] アプリケーションの動作確認
- [ ] メール送信テスト
- [ ] データベースマイグレーション完了

## 🔄 更新手順

```bash
# 最新のコードを取得
git pull origin main

# コンテナの再ビルドと再起動
make rebuild

# マイグレーションの実行
make migrate

# キャッシュのクリアと最適化
make cache-clear
make optimize
```

## 📞 サポート

問題が発生した場合は、GitHub Issuesで報告してください。


