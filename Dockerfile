# Stage 1: Base PHP with extensions
FROM php:8.4-fpm-alpine AS base

# Enable Opcache for performance
ENV PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_ENABLE_CLI=0 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_OPCACHE_REVALIDATE_FREQ=0

# Set working directory
WORKDIR /var/www

# Install system packages, PHP extensions, and Supervisor
RUN apk add --no-cache \
    unzip \
    libpq \
    libpq-dev \
    libcurl \
    curl-dev \
    nginx \
    oniguruma-dev \
    bash \
    supervisor \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    bcmath \
    curl \
    opcache \
    mbstring \
    && apk del libpq-dev curl-dev oniguruma-dev \
    && rm -rf /var/cache/apk/*

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy default PHP config (optional)
COPY ./docker/php.ini /usr/local/etc/php/conf.d/99-custom.ini

# Copy Supervisor config
COPY ./docker/supervisord.conf /etc/supervisord.conf

# Optional: Supervisor programs (queue, scheduler, etc.)
COPY ./docker/supervisor.d/ /etc/supervisor.d/

# Set correct permissions (Laravel-friendly)
RUN addgroup -g 1000 www \
    && adduser -u 1000 -G www -s /bin/sh -D www \
    && chown -R www:www /var/www

USER www

# Entrypoint: start Supervisor (managing php-fpm, queue, scheduler etc.)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
