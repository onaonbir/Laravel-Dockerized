<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/php-info', function () {
    phpinfo();
    exit; // Önemli: Laravel'in response handling'ini bypass et
});

Route::get('/test-route', function () {
    return response()->json([
        'message' => 'Laravel is working!',
        'app_url' => config('app.url'),
        'request' => [
            'url' => request()->url(),
            'host' => request()->getHost(),
            'path' => request()->path(),
            'fullUrl' => request()->fullUrl(),
        ],
        'headers' => request()->headers->all()
    ]);
});

Route::fallback(function () {
    return response()->json([
        'error' => '404 - Route not found',
        'requested_path' => request()->path(),
        'available_routes' => collect(Route::getRoutes())->map(function($route) {
            return $route->uri();
        })->toArray()
    ], 404);
});
