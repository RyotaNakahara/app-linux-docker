<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MailTestController;

// ========================================
// ウェルカムページ
// ========================================
// アプリケーションのトップページを表示
// Laravel Docker 環境の状態とリンクを表示する
Route::get('/', function () {
    return view('welcome');
});

// ========================================
// ヘルスチェックエンドポイント
// ========================================
// アプリケーションとサービスの稼働状態を JSON で返す
// Nginx のヘルスチェックやモニタリングツールから利用される
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

// ========================================
// Mailhog テストエンドポイント
// ========================================
// Mailhog を使用したメール送信のテスト用エンドポイント
//
// 【処理の流れ】
// 1. このルートにアクセスすると MailTestController::send() が実行される
// 2. TestMail クラスで定義されたメールが作成される
// 3. config/mail.php の設定に基づいて SMTP 経由で送信される
// 4. docker-compose.yml で定義された mailhog コンテナ（ポート1025）にメールが送信される
// 5. Mailhog がメールをキャッチし、実際には外部に送信されない
// 6. http://localhost:8025 の Mailhog Web UI でメールを確認できる
//
// 【用途】
// - メール送信機能が正しく動作することを確認
// - メールのレイアウトやデザインをプレビュー
// - 本番環境に影響を与えずにメール機能をテスト
Route::get('/send-test-email', [MailTestController::class, 'send']);

