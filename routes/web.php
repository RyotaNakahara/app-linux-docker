<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MailTestController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String(),
        'services' => [
            'database' => 'connected',
            'redis' => 'connected',
        ]
    ]);
});

// メールテスト用エンドポイント
Route::get('/send-test-email', [MailTestController::class, 'send']);

