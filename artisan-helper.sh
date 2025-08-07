#!/bin/bash

# Laravel Artisan Helper for Docker/Dokploy
# Bu script container içinde çalıştırılacak

CONTAINER_NAME="your-app-container-name"

# Functions
run_in_container() {
    docker exec -it $CONTAINER_NAME "$@"
}

# Migrate commands
migrate() {
    echo "🔄 Running migrations..."
    run_in_container php artisan migrate --force
}

migrate_fresh() {
    echo "🆕 Fresh migrations..."
    run_in_container php artisan migrate:fresh --force --seed
}

# Cache commands
cache_clear() {
    echo "🧹 Clearing all caches..."
    run_in_container php artisan cache:clear
    run_in_container php artisan config:clear
    run_in_container php artisan route:clear
    run_in_container php artisan view:clear
}

cache_optimize() {
    echo "⚡ Optimizing caches..."
    run_in_container php artisan config:cache
    run_in_container php artisan route:cache
    run_in_container php artisan view:cache
}

# Queue/Horizon commands
horizon_restart() {
    echo "🌅 Restarting Horizon..."
    run_in_container php artisan horizon:terminate
    sleep 2
    echo "Horizon restarted!"
}

queue_work() {
    echo "⚙️  Starting queue worker..."
    run_in_container php artisan queue:work --verbose --tries=3 --timeout=90
}

# Maintenance
maintenance_on() {
    echo "🔧 Enabling maintenance mode..."
    run_in_container php artisan down --render="errors::503" --secret="dokploy-maintenance"
}

maintenance_off() {
    echo "✅ Disabling maintenance mode..."
    run_in_container php artisan up
}

# Logs
logs() {
    echo "📝 Showing Laravel logs..."
    run_in_container tail -f storage/logs/laravel.log
}

horizon_logs() {
    echo "📝 Showing Horizon logs..."
    docker logs -f $CONTAINER_NAME --tail=100 | grep horizon
}

# Health check
health() {
    echo "🏥 Health check..."
    curl -s http://localhost:8080/health | jq .
}

# Usage
case "$1" in
    migrate)
        migrate
        ;;
    migrate:fresh)
        migrate_fresh
        ;;
    cache:clear)
        cache_clear
        ;;
    cache:optimize)
        cache_optimize
        ;;
    horizon:restart)
        horizon_restart
        ;;
    queue:work)
        queue_work
        ;;
    down)
        maintenance_on
        ;;
    up)
        maintenance_off
        ;;
    logs)
        logs
        ;;
    horizon:logs)
        horizon_logs
        ;;
    health)
        health
        ;;
    *)
        echo "Laravel Artisan Helper"
        echo "Usage: $0 {migrate|migrate:fresh|cache:clear|cache:optimize|horizon:restart|queue:work|down|up|logs|horizon:logs|health}"
        echo ""
        echo "Examples:"
        echo "  $0 migrate          - Run database migrations"
        echo "  $0 cache:clear      - Clear all caches"
        echo "  $0 horizon:restart  - Restart Horizon"
        echo "  $0 health          - Check application health"
        exit 1
        ;;
esac
