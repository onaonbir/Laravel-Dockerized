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

# Debug - Print environment variables
echo "🔍 Database config:"
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_DATABASE: $DB_DATABASE"
echo "DB_USERNAME: $DB_USERNAME"

# Test network connectivity first
echo "🌐 Testing network connectivity..."
if ping -c 1 "$DB_HOST" > /dev/null 2>&1; then
    echo "✅ Can ping database host: $DB_HOST"
else
    echo "❌ Cannot ping database host: $DB_HOST"
    echo "🔍 Trying to resolve hostname..."
    nslookup "$DB_HOST" || echo "❌ DNS resolution failed"
fi

# Wait for database connection with better error handling
echo "🔌 Checking database connection..."
timeout=60
counter=0
until php -r "
try {
    \$pdo = new PDO('mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_DATABASE', '$DB_USERNAME', '$DB_PASSWORD');
    echo 'Database connection successful';
    exit(0);
} catch (Exception \$e) {
    echo 'Database error: ' . \$e->getMessage();
    exit(1);
}
" || [ $counter -eq $timeout ]; do
  echo "Database not ready, waiting... ($counter/$timeout)"
  sleep 2
  ((counter++))
done

if [ $counter -eq $timeout ]; then
    echo "❌ Database connection timeout after $timeout attempts"
    echo "🔍 Final connection attempt with detailed error..."
    php -r "
    try {
        \$pdo = new PDO('mysql:host=$DB_HOST;port=$DB_PORT;dbname=$DB_DATABASE', '$DB_USERNAME', '$DB_PASSWORD');
        echo 'Connection successful!';
    } catch (Exception \$e) {
        echo 'Final error: ' . \$e->getMessage();
    }
    "
    exit 1
fi

echo "✅ Database connection established"

# Skip Redis check for now, continue without it
echo "⚠️ Skipping Redis check for debugging"

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


echo "✅ Laravel application setup completed!"
echo "🌟 Starting services..."

# Start supervisor
exec supervisord -c /etc/supervisor/supervisord.conf
