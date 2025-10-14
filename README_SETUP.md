# Laravel Docker 環境構築ガイド

このドキュメントでは、Laravel + PostgreSQL + Redis + Mailhog + Nginx の Docker 環境のセットアップ手順を説明します。

## 📋 要件

- Docker Engine 20.10+
- Docker Compose v2.0+
- Git
- (オプション) Make

## 🚀 クイックスタート

### 1. 環境変数の設定

.env ファイルを作成します（既に存在する場合はスキップ）:

```bash
# Windowsの場合
copy .env.example .env

# Linux/Macの場合
cp .env.example .env
```

### 2. アプリケーションキーの生成

まず、コンテナを起動してからアプリケーションキーを生成します:

```bash
# コンテナを起動
make up
# または
docker compose up -d

# アプリケーションキーを生成
docker compose exec app php artisan key:generate
```

### 3. Composer の依存関係をインストール

```bash
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader
```

### 4. データベースのマイグレーションとシーディング

```bash
make migrate-seed
# または
docker compose exec app php artisan migrate --seed --force
```

### 5. ストレージディレクトリのパーミッション設定

```bash
docker compose exec -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -u root app chown -R laravel:laravel storage bootstrap/cache
```

### 6. 動作確認

ブラウザで以下の URL にアクセスします:

- **アプリケーション**: http://localhost
- **Mailhog (メール確認)**: http://localhost:8025
- **ヘルスチェック**: http://localhost/health

## 📝 利用可能なコマンド

### Make コマンド

```bash
make help          # 利用可能なコマンド一覧を表示
make up            # コンテナを起動
make down          # コンテナを停止
make restart       # コンテナを再起動
make build         # コンテナをビルド
make rebuild       # コンテナを再ビルドして起動
make logs          # ログを表示
make shell         # appコンテナにログイン
make artisan CMD="..." # Artisanコマンドを実行
make migrate       # マイグレーションを実行
make seed          # シーダーを実行
make migrate-seed  # マイグレーション + シーディング
make test          # テストを実行
make clean         # 全てのコンテナ・ボリュームを削除
make scan          # 脆弱性スキャン (Trivy必要)
```

### Docker Compose コマンド

```bash
docker compose up -d              # コンテナを起動
docker compose down               # コンテナを停止
docker compose ps                 # 起動中のコンテナを表示
docker compose logs -f            # ログを表示
docker compose exec app bash      # appコンテナにログイン
docker compose exec app php artisan migrate  # マイグレーション実行
```

## 🔧 開発

### メール送信のテスト

1. ブラウザで http://localhost にアクセス
2. 「テストメール送信」ボタンをクリック
3. http://localhost:8025 で Mailhog を開く
4. 送信されたメールを確認

または、コマンドラインから:

```bash
curl http://localhost/send-test-email
```

### データベースへの接続

以下の設定でデータベースクライアント（DBeaver、TablePlus等）から接続できます:

- **Host**: localhost
- **Port**: 5432
- **Database**: laravel
- **Username**: laravel
- **Password**: secret

### Redis への接続

- **Host**: localhost
- **Port**: 6379
- **Password**: (なし)

## 🔒 セキュリティ

### 非rootユーザーでの実行

Dockerイメージは非rootユーザー（laravel:1000）で動作するように設計されています。

### ホストのセキュリティハードニング（Ubuntu）

本番環境では、ホストサーバーのセキュリティハードニングを実施してください:

```bash
# Dockerのインストール
sudo bash scripts/setup-docker.sh

# セキュリティハードニング（SSH鍵認証、UFW、Fail2ban）
sudo bash scripts/setup-host-security.sh
```

**注意**: `setup-host-security.sh` を実行する前に、必ずSSH公開鍵を準備してください。

### 脆弱性スキャン

Trivyを使用してDockerイメージの脆弱性をスキャンできます:

```bash
# Trivyのインストール（Ubuntu/Debian）
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# スキャン実行
make scan
```

## 🐛 トラブルシューティング

### コンテナが起動しない

```bash
# ログを確認
docker compose logs

# コンテナを完全に削除して再起動
docker compose down -v
make rebuild
```

### データベース接続エラー

```bash
# PostgreSQLのヘルスチェック確認
docker compose ps

# データベースコンテナのログを確認
docker compose logs postgres

# データベースの再起動
docker compose restart postgres
```

### パーミッションエラー

```bash
# storage と bootstrap/cache のパーミッション修正
docker compose exec -u root app chmod -R 775 storage bootstrap/cache
docker compose exec -u root app chown -R laravel:laravel storage bootstrap/cache
```

### Composer の依存関係エラー

```bash
# Composerのキャッシュをクリア
docker compose exec app composer clear-cache
docker compose exec app composer install --no-cache
```

## 📚 参考資料

- [Laravel 11 ドキュメント](https://laravel.com/docs/11.x)
- [Docker ドキュメント](https://docs.docker.com/)
- [PostgreSQL ドキュメント](https://www.postgresql.org/docs/)
- [Mailhog](https://github.com/mailhog/MailHog)

## 🤝 CI/CD

このプロジェクトには GitHub Actions による CI/CD が設定されています:

- **Trivy Security Scan**: Dockerイメージの脆弱性スキャン
- **Dockerfile Lint**: Dockerfileの品質チェック
- **Docker Build Test**: ビルドとヘルスチェック

詳細は `.github/workflows/docker-security-scan.yml` を参照してください。

## ⚖️ ライセンス

MIT License

