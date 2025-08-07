#!/bin/bash
set -e

echo "🚀 Starting Laravel application..."

# Copy configuration files
cp /app/Caddyfile /etc/caddy/Caddyfile
cp /app/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create necessary directories
mkdir -p /app/storage/logs
mkdir -p /app/storage/framework/cache
mkdir -p /app/storage/framework/sessions
mkdir -p /app/storage/framework/views

# Set proper permissions
chown -R www-data:www-data /app/storage /app/bootstrap/cache
chmod -R 775 /app/storage /app/bootstrap/cache

echo "⏳ Waiting for external services..."

# Wait for database connection with timeout
echo "🔌 Checking database connection..."
timeout=60
counter=0
until php artisan migrate:status > /dev/null 2>&1 || [ $counter -eq $timeout ]; do
  echo "Database not ready, waiting... ($counter/$timeout)"
  sleep 2
  ((counter++))
done

if [ $counter -eq $timeout ]; then
    echo "❌ Database connection timeout after $timeout attempts"
    exit 1
fi

# Wait for Redis connection
echo "🔌 Checking Redis connection..."
timeout=30
counter=0
until php artisan tinker --execute="Redis::ping();" > /dev/null 2>&1 || [ $counter -eq $timeout ]; do
  echo "Redis not ready, waiting... ($counter/$timeout)"
  sleep 2
  ((counter++))
done

if [ $counter -eq $timeout ]; then
    echo "❌ Redis connection timeout after $timeout attempts"
    exit 1
fi

echo "✅ External services are ready"

# Run Laravel commands
echo "🔄 Running Laravel setup commands..."

# Generate app key if not exists
if [ -z "$APP_KEY" ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Run migrations
echo "📊 Running database migrations..."
php artisan migrate --force

# Clear and cache configurations for production
echo "🗂️ Optimizing for production..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link if not exists
if [ ! -L /app/public/storage ]; then
    echo "🔗 Creating storage link..."
    php artisan storage:link
fi

# Install Horizon assets
echo "🌅 Installing Horizon assets..."
php artisan horizon:publish --force

# Clear Horizon cache
php artisan horizon:clear

echo "✅ Laravel application setup completed!"
echo "🌟 Starting services..."

# Start supervisor
exec supervisord -c /etc/supervisor/supervisord.conf
