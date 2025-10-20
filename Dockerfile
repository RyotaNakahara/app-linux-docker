# =============================================
# Laravel アプリケーション Dockerfile
# セキュリティ強化のため非rootユーザー、マルチステージビルドを使用
# =============================================

# ビルドステージ
FROM php:8.3-fpm-alpine AS builder

# システム依存パッケージのインストール
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    zip \
    unzip

# PHP拡張機能のインストール
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    pgsql \
    mbstring \
    zip \
    exif \
    pcntl \
    bcmath \
    gd

# Redis拡張機能のインストール
RUN apk add --no-cache pcre-dev ${PHPIZE_DEPS} \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS}

# Composerのインストール
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 作業ディレクトリの設定
WORKDIR /var/www/html

# Composerファイルを先にコピー（レイヤーキャッシュの最適化のため）
COPY composer.json composer.lock* ./

# PHP依存パッケージのインストール
# composer installがスキップされた場合でもvendorディレクトリを作成
RUN mkdir -p vendor && \
    if [ -f composer.lock ]; then \
        composer install --no-dev --no-scripts --no-autoloader --prefer-dist; \
    fi

# =============================================
# 本番ステージ
FROM php:8.3-fpm-alpine

# 実行時の依存パッケージのみをインストール
RUN apk add --no-cache \
    libpng \
    libzip \
    postgresql-libs \
    bash \
    fcgi \
    netcat-openbsd

# PHP拡張機能のインストール（ビルダーステージと同じ）
RUN apk add --no-cache postgresql-dev libpng-dev libzip-dev oniguruma-dev \
    && docker-php-ext-install \
        pdo \
        pdo_pgsql \
        pgsql \
        mbstring \
        zip \
        exif \
        pcntl \
        bcmath \
        gd \
    && apk del postgresql-dev libpng-dev libzip-dev oniguruma-dev

# Redis拡張機能のインストール
RUN apk add --no-cache pcre-dev ${PHPIZE_DEPS} \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS}

# 公式イメージからComposerをコピー
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 非rootユーザーの作成（UID 1000, GID 1000）
RUN addgroup -g 1000 laravel && \
    adduser -D -u 1000 -G laravel laravel

# 作業ディレクトリの設定
WORKDIR /var/www/html

# アプリケーションファイルを先にコピー（rootとしてコピー）
COPY . .

# ビルダーからvendorをコピー（存在する場合）
COPY --from=builder /var/www/html/vendor ./vendor

# 必要なディレクトリを作成し、適切な権限を設定
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R laravel:laravel . \
    && chmod -R 775 storage bootstrap/cache

# PHP設定ファイルのコピー
COPY docker/php/php.ini /usr/local/etc/php/conf.d/laravel.ini
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# ヘルスチェックスクリプトをコピーし、実行権限を付与
COPY docker/php/php-fpm-healthcheck /usr/local/bin/php-fpm-healthcheck
RUN chmod +x /usr/local/bin/php-fpm-healthcheck

# 非rootユーザーに切り替え
USER laravel

# PHP-FPM用のポート9000を公開
EXPOSE 9000

# ヘルスチェックの設定
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD php-fpm-healthcheck || exit 1

# PHP-FPMを起動
CMD ["php-fpm"]
