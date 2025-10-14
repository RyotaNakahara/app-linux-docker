# 📖 完全セットアップ手順書

このドキュメントでは、text.txt の要件を満たす環境構築の全手順を説明します。

## ✅ 要件の確認

以下の要件を満たす環境を構築します：

1. ✅ `make up`（または `docker compose up -d`）で Laravel アプリ + Postgres + Redis + Mailhog + Nginx が起動すること
2. ✅ `php artisan migrate --seed` が実行でき、メール送信は Mailhog で確認できること
3. ✅ ホスト（Ubuntu想定）に最低限のハードニング（SSH鍵認証・ufw・fail2ban）がされていること
4. ✅ Docker イメージは非 root ユーザーで動く・CI 用にスキャン可能であること

## 🖥️ 環境別セットアップ

### Windows で開発する場合

#### 方法1: PowerShell スクリプト（最も簡単）

```powershell
# PowerShell を管理者として実行
.\setup.ps1
```

#### 方法2: 手動セットアップ

```powershell
# 1. 環境変数ファイルを作成
Copy-Item .env.template .env

# 2. Docker コンテナをビルド・起動
docker compose build
docker compose up -d

# 3. データベースの準備を待つ（10秒）
timeout /t 10

# 4. Composer の依存関係をインストール
docker compose exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader

# 5. アプリケーションキーを生成
docker compose exec -T app php artisan key:generate --force

# 6. データベースマイグレーションとシーディング
docker compose exec -T app php artisan migrate --seed --force

# 7. パーミッション設定
docker compose exec -T -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -T -u root app chown -R laravel:laravel storage bootstrap/cache
```

### Linux/Mac で開発する場合

#### 方法1: Bash スクリプト（最も簡単）

```bash
# スクリプトに実行権限を付与
chmod +x setup.sh

# セットアップを実行
./setup.sh
```

#### 方法2: Make コマンド

```bash
make init
```

#### 方法3: 手動セットアップ

```bash
# 1. 環境変数ファイルを作成
cp .env.template .env

# 2. Docker コンテナをビルド・起動
docker compose build
docker compose up -d

# 3. データベースの準備を待つ（10秒）
sleep 10

# 4. Composer の依存関係をインストール
docker compose exec -T app composer install --no-interaction --prefer-dist --optimize-autoloader

# 5. アプリケーションキーを生成
docker compose exec -T app php artisan key:generate --force

# 6. データベースマイグレーションとシーディング
docker compose exec -T app php artisan migrate --seed --force

# 7. パーミッション設定
docker compose exec -T -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -T -u root app chown -R laravel:laravel storage bootstrap/cache
```

## 🎯 要件1: アプリケーションの起動確認

セットアップが完了したら、以下のコマンドで起動できることを確認します：

```bash
# コンテナを起動
make up

# または
docker compose up -d

# 起動状態を確認
docker compose ps
```

**期待される出力:**
```
NAME                 IMAGE                  STATUS              PORTS
laravel_app          app-linux-docker-app   Up (healthy)        9000/tcp
laravel_nginx        nginx:1.25-alpine      Up (healthy)        0.0.0.0:80->80/tcp
laravel_postgres     postgres:16-alpine     Up (healthy)        0.0.0.0:5432->5432/tcp
laravel_redis        redis:7-alpine         Up (healthy)        0.0.0.0:6379->6379/tcp
laravel_mailhog      mailhog/mailhog        Up                  0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
```

**ブラウザでアクセス:**
- アプリケーション: http://localhost
- Mailhog: http://localhost:8025
- ヘルスチェック: http://localhost/health

## 🎯 要件2: データベースとメール機能の確認

### マイグレーションとシーディング

```bash
# コンテナ内でマイグレーションを実行
docker compose exec app php artisan migrate --seed

# または Make コマンドを使用
make migrate-seed
```

**期待される出力:**
```
Migration table created successfully.
Migrating: 0001_01_01_000000_create_users_table
Migrated:  0001_01_01_000000_create_users_table (XX.XXms)
...
Seeding: Database\Seeders\DatabaseSeeder
Seeded:  Database\Seeders\DatabaseSeeder (XX.XXms)
```

### メール送信のテスト

```bash
# ブラウザで http://localhost にアクセスし、「テストメール送信」ボタンをクリック

# または curl で直接実行
curl http://localhost/send-test-email
```

**Mailhog での確認:**
1. ブラウザで http://localhost:8025 を開く
2. 受信トレイに「Laravel Docker 環境テストメール」が表示される
3. メールの内容を確認

## 🎯 要件3: ホストのセキュリティハードニング（Ubuntu）

本番環境のUbuntuホストでは、以下のセキュリティ設定を行います：

### 前提条件

- Ubuntu 20.04 LTS 以降
- sudo 権限を持つユーザー
- SSH公開鍵の準備

### セットアップ手順

```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd app-linux-docker

# 2. Docker をインストール
sudo bash scripts/setup-docker.sh

# 3. セキュリティハードニングを実行
sudo bash scripts/setup-host-security.sh
```

**setup-host-security.sh が行うこと:**

1. **SSH鍵認証の設定**
   - 公開鍵の登録
   - パスワード認証の無効化
   - rootログインの無効化
   - SSH設定の最適化

2. **UFW ファイアウォール**
   - デフォルトポリシー（受信拒否、送信許可）
   - SSH（22番ポート）の許可
   - HTTP（80番ポート）の許可
   - HTTPS（443番ポート）の許可

3. **Fail2ban の設定**
   - SSH攻撃の検知と防御
   - Nginx攻撃の検知
   - 自動BANの設定

4. **システム更新とセキュリティツール**
   - 自動セキュリティアップデート
   - logwatch、aide のインストール

### 確認コマンド

```bash
# UFW の状態確認
sudo ufw status verbose

# Fail2ban の状態確認
sudo fail2ban-client status

# SSH設定の確認
sudo sshd -T | grep -E "passwordauthentication|pubkeyauthentication|permitrootlogin"
```

## 🎯 要件4: Dockerイメージのセキュリティ

### 非rootユーザーでの実行

Dockerfile では非rootユーザー（laravel:1000）で実行するように設定されています：

```dockerfile
# Create non-root user (UID 1000, GID 1000)
RUN addgroup -g 1000 laravel && \
    adduser -D -u 1000 -G laravel laravel

# Switch to non-root user
USER laravel
```

**確認方法:**

```bash
# コンテナ内で実行ユーザーを確認
docker compose exec app whoami
# 出力: laravel

docker compose exec app id
# 出力: uid=1000(laravel) gid=1000(laravel) groups=1000(laravel)
```

### CI用の脆弱性スキャン

GitHub Actions による自動スキャンが設定されています：

**.github/workflows/docker-security-scan.yml の機能:**

1. **Trivy Security Scan**
   - Dockerイメージの脆弱性スキャン
   - CRITICAL、HIGH レベルの脆弱性を検出
   - SARIF形式でGitHub Security タブに出力

2. **Dockerfile Lint**
   - Hadolint によるDockerfileの品質チェック
   - ベストプラクティスの確認

3. **Docker Build Test**
   - ビルドの成功確認
   - ヘルスチェックの動作確認

### ローカルでの脆弱性スキャン

```bash
# Trivy のインストール（Ubuntu/Debian）
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# スキャン実行
make scan

# または直接実行
trivy image --severity HIGH,CRITICAL $(docker compose images -q app)
```

## 📊 全要件の確認チェックリスト

### ✅ 要件1: アプリケーションの起動

- [ ] `make up` でコンテナが起動する
- [ ] `docker compose ps` で全コンテナが "Up (healthy)" になる
- [ ] http://localhost でアプリケーションが表示される
- [ ] http://localhost:8025 で Mailhog が開く

### ✅ 要件2: データベースとメール

- [ ] `docker compose exec app php artisan migrate --seed` が成功する
- [ ] http://localhost/send-test-email でメールが送信される
- [ ] Mailhog でテストメールが受信される

### ✅ 要件3: ホストのセキュリティ

- [ ] SSH鍵認証が有効（`sudo sshd -T | grep passwordauthentication` で確認）
- [ ] UFW が有効（`sudo ufw status` で確認）
- [ ] Fail2ban が実行中（`sudo systemctl status fail2ban` で確認）

### ✅ 要件4: Dockerセキュリティ

- [ ] 非rootユーザーで実行（`docker compose exec app whoami` で確認）
- [ ] Trivy スキャンが実行可能（`make scan` で確認）
- [ ] GitHub Actions が設定されている

## 🔧 トラブルシューティング

### ポート 80 が使用中

```bash
# .env ファイルで別のポートを指定
echo "APP_PORT=8080" >> .env

# コンテナを再起動
docker compose down
docker compose up -d
```

### データベース接続エラー

```bash
# PostgreSQL のログを確認
docker compose logs postgres

# ヘルスチェックを確認
docker compose ps

# データベースを再起動
docker compose restart postgres
sleep 5
docker compose exec app php artisan migrate --seed --force
```

### パーミッションエラー

```bash
# パーミッションを修正
docker compose exec -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -u root app chown -R laravel:laravel storage bootstrap/cache
```

### Composer エラー

```bash
# Composer キャッシュをクリア
docker compose exec app composer clear-cache

# 再インストール
docker compose exec app composer install --no-cache
```

## 📚 参考ドキュメント

- [QUICK_START.md](QUICK_START.md) - クイックスタートガイド
- [README_SETUP.md](README_SETUP.md) - 詳細セットアップガイド
- [README.md](README.md) - プロジェクト概要
- [docs/WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md) - Windows環境のセットアップ

## 🎉 完了

全ての要件を満たす環境が構築されました！

開発を楽しんでください！ 🚀

