#!/bin/bash
set -e

echo "🚀 Starting Laravel Octane + FrankenPHP application..."

# Copy supervisor config
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

# Debug environment
echo "🔍 Database config:"
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_DATABASE: $DB_DATABASE"
echo "DB_USERNAME: $DB_USERNAME"

# Wait for database connection
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
    echo "❌ Database connection timeout"
    exit 1
fi

echo "✅ Database connection established"

# Skip Redis check for debugging
echo "⚠️ Skipping Redis check for debugging"

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

# Clear and optimize for production
echo "🗂️ Optimizing for production..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link
if [ ! -L /app/public/storage ]; then
    echo "🔗 Creating storage link..."
    php artisan storage:link
fi

echo "✅ Laravel Octane application setup completed!"
echo "🐘 Starting Octane with FrankenPHP server..."

# Start supervisor
exec supervisord -c /etc/supervisor/supervisord.conf
