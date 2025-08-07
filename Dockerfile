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

# Node.js ve npm kurulumu (frontend assets için)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./

# Install npm dependencies (handle missing package-lock.json)
RUN if [ -f "package-lock.json" ]; then \
        npm ci --omit=dev; \
    else \
        npm install --omit=dev; \
    fi

# Dependency files first (for better caching)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

# Copy application
COPY . .

# Frontend build (only if package.json exists and has build script)
RUN if [ -f "package.json" ] && npm run | grep -q "build"; then \
        npm run build; \
    else \
        echo "No build script found, creating empty manifest"; \
        mkdir -p public/build && echo '{}' > public/build/manifest.json; \
    fi

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
