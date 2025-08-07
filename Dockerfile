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

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Dependency files first (for better caching)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Copy application
COPY . .

# Create empty build manifest (Laravel Vite için gerekli)
RUN mkdir -p public/build && echo '{}' > public/build/manifest.FROM dunglas/frankenphp:latest

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

# Node.js ve npm kurulumu (en son LTS version)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy package files first (for better caching)
COPY package.json package-lock.json ./

# Install npm dependencies (including dev dependencies for build)
RUN npm ci

# Copy composer files
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Copy application files
COPY . .

# Build frontend assets
RUN npm run build

# Remove dev dependencies after build
RUN npm prune --omit=dev

# Finish composer installation
RUN composer dump-autoload --optimize --no-dev

# Copy configuration files
COPY php.ini /usr/local/etc/php/php.ini
COPY Caddyfile /app/Caddyfile
COPY supervisord.conf /app/supervisord.conf

# Laravel optimizations
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Set permissions
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache
RUN chmod -R 775 /app/storage /app/bootstrap/cache

# Expose port
EXPOSE 8080

# Start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]

# Finish composer installation
RUN composer dump-autoload --optimize --no-dev

# Copy configuration files
COPY php.ini /usr/local/etc/php/php.ini
COPY Caddyfile /app/Caddyfile
COPY supervisord.conf /app/supervisord.conf

# Laravel optimizations
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Set permissions
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache
RUN chmod -R 775 /app/storage /app/bootstrap/cache

# Expose port
EXPOSE 8080

# Start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
