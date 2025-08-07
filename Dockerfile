FROM dunglas/frankenphp:latest

# System dependencies
RUN apt-get update && apt-get install -y \
    supervisor \
    cron \
    curl \
    git \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions (comprehensive list)
RUN install-php-extensions \
    pdo_mysql \
    mysqli \
    redis \
    pcntl \
    gd \
    zip \
    opcache \
    intl \
    exif \
    bcmath \
    calendar \
    ctype \
    curl \
    dom \
    fileinfo \
    filter \
    ftp \
    hash \
    iconv \
    json \
    libxml \
    mbstring \
    openssl \
    pcre \
    pdo \
    phar \
    posix \
    readline \
    reflection \
    session \
    simplexml \
    sockets \
    sodium \
    spl \
    tokenizer \
    xml \
    xmlreader \
    xmlwriter \
    xsl \
    imagick

# Node.js ve npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy package files first
COPY package.json package-lock.json ./
RUN npm ci

# Copy composer files
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-autoloader --prefer-dist

# Copy application files
COPY . .

# Build frontend assets
RUN npm run build && npm prune --omit=dev

# Finish composer installation
RUN composer dump-autoload --optimize --no-dev

# Install Laravel Octane with FrankenPHP
RUN composer require laravel/octane --no-scripts
RUN php artisan octane:install --server=frankenphp --no-interaction

# Copy deployment configuration files
COPY deployment/php.ini /usr/local/etc/php/php.ini
COPY deployment/Caddyfile /etc/caddy/Caddyfile
COPY deployment/supervisord.conf /app/supervisord.conf

# DON'T cache Laravel configs during build - do it at runtime!
# Laravel optimizations will be done in start.sh when DB is available

# Create log directories and set permissions
RUN mkdir -p /var/log/laravel /var/log/caddy /app/storage/logs \
    && chown -R www-data:www-data /app/storage /app/bootstrap/cache /var/log/laravel \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# Expose ports
EXPOSE 8080 2019

# Volume mount points
VOLUME ["/app/storage", "/var/log/laravel", "/var/log/caddy"]

# Start script
COPY deployment/start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
