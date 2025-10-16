# =============================================
# Laravel Application Dockerfile
# Non-root user, multi-stage build for security
# =============================================

# Build stage
FROM php:8.3-fpm-alpine AS builder

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev \
    zip \
    unzip

# Install PHP extensions
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

# Install Redis extension
RUN apk add --no-cache pcre-dev ${PHPIZE_DEPS} \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS}

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first (for better layer caching)
COPY composer.json composer.lock* ./

# Install PHP dependencies
# Create vendor directory even if composer install is skipped
RUN mkdir -p vendor && \
    if [ -f composer.lock ]; then \
        composer install --no-dev --no-scripts --no-autoloader --prefer-dist; \
    fi

# =============================================
# Production stage
FROM php:8.3-fpm-alpine

# Install runtime dependencies only
RUN apk add --no-cache \
    libpng \
    libzip \
    postgresql-libs \
    bash \
    fcgi \
    netcat-openbsd

# Install PHP extensions (same as builder)
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

# Install Redis extension
RUN apk add --no-cache pcre-dev ${PHPIZE_DEPS} \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del pcre-dev ${PHPIZE_DEPS}

# Copy Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Create non-root user (UID 1000, GID 1000)
RUN addgroup -g 1000 laravel && \
    adduser -D -u 1000 -G laravel laravel

# Set working directory
WORKDIR /var/www/html

# Copy application files first
COPY --chown=laravel:laravel . .

# Copy vendor from builder (if exists)
COPY --from=builder --chown=laravel:laravel /var/www/html/vendor ./vendor

# Create necessary directories with proper permissions
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R laravel:laravel storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/laravel.ini
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Copy health check script and make it executable
COPY docker/php/php-fpm-healthcheck /usr/local/bin/php-fpm-healthcheck
RUN chmod +x /usr/local/bin/php-fpm-healthcheck

# Switch to non-root user
USER laravel

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD php-fpm-healthcheck || exit 1

# Start PHP-FPM
CMD ["php-fpm"]
