<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

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




// Resim indirme ve gösterme route'u
Route::get('/download-image', function () {
    try {
        // URL parametresini al
        $imageUrl = request('url');

        if (!$imageUrl) {
            return response()->json([
                'error' => 'URL parametresi gerekli',
                'usage' => '/download-image?url=https://example.com/image.jpg'
            ], 400);
        }

        // URL'nin geçerli olup olmadığını kontrol et
        if (!filter_var($imageUrl, FILTER_VALIDATE_URL)) {
            return response()->json(['error' => 'Geçersiz URL'], 400);
        }

        // Dosya adı oluştur
        $fileName = 'downloaded_images/' . Str::random(10) . '_' . basename(parse_url($imageUrl, PHP_URL_PATH));

        // Eğer dosya uzantısı yoksa .jpg ekle
        if (!pathinfo($fileName, PATHINFO_EXTENSION)) {
            $fileName .= '.jpg';
        }

        // Dosya zaten var mı kontrol et
        if (Storage::disk('public')->exists($fileName)) {
            return response()->json([
                'message' => 'Resim zaten mevcut',
                'image_url' => Storage::disk('public')->url($fileName),
                'local_path' => $fileName
            ]);
        }

        // HTTP isteği ile resmi indir
        $response = Http::timeout(30)->get($imageUrl);

        if (!$response->successful()) {
            return response()->json([
                'error' => 'Resim indirilemedi',
                'status' => $response->status()
            ], 400);
        }

        // Content-Type kontrolü
        $contentType = $response->header('Content-Type');
        if (!str_starts_with($contentType, 'image/')) {
            return response()->json([
                'error' => 'URL bir resim dosyası değil',
                'content_type' => $contentType
            ], 400);
        }

        // Resmi storage'a kaydet
        Storage::disk('public')->put($fileName, $response->body());

        // Başarılı response döndür
        return response()->json([
            'message' => 'Resim başarıyla indirildi',
            'image_url' => Storage::disk('public')->url($fileName),
            'local_path' => $fileName,
            'original_url' => $imageUrl,
            'file_size' => Storage::disk('public')->size($fileName),
            'content_type' => $contentType
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'error' => 'Bir hata oluştu',
            'message' => $e->getMessage()
        ], 500);
    }
});

// Resmi direkt göstermek için route (opsiyonel)
Route::get('/show-image/{filename}', function ($filename) {
    $path = 'downloaded_images/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json(['error' => 'Resim bulunamadı'], 404);
    }

    $file = Storage::disk('public')->get($path);
    $mimeType = Storage::disk('public')->mimeType($path);

    return response($file, 200)->header('Content-Type', $mimeType);
});

// Tüm indirilen resimleri listele (opsiyonel)
Route::get('/list-images', function () {
    $images = Storage::disk('public')->files('downloaded_images');

    $imageList = collect($images)->map(function ($image) {
        return [
            'filename' => basename($image),
            'url' => Storage::disk('public')->url($image),
            'size' => Storage::disk('public')->size($image),
            'last_modified' => Storage::disk('public')->lastModified($image)
        ];
    });

    return response()->json([
        'images' => $imageList,
        'total' => $imageList->count()
    ]);
});

// Resim sil (opsiyonel)
Route::delete('/delete-image/{filename}', function ($filename) {
    $path = 'downloaded_images/' . $filename;

    if (!Storage::disk('public')->exists($path)) {
        return response()->json(['error' => 'Resim bulunamadı'], 404);
    }

    Storage::disk('public')->delete($path);

    return response()->json(['message' => 'Resim silindi']);
});
