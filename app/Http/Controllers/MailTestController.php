<?php

namespace App\Http\Controllers;

use App\Mail\TestMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

/**
 * メールテストコントローラー
 *
 * Mailhog を使用したメール送信のテストを行うコントローラー。
 * 開発環境でメール送信機能が正しく動作することを確認するために使用します。
 */
class MailTestController extends Controller
{
    /**
     * テストメールを送信する
     *
     * このメソッドは以下の処理を行います：
     * 1. テスト用の宛先メールアドレスを設定
     * 2. TestMail クラスを使用してメールを作成
     * 3. Laravel の Mail ファサードを通じてメールを送信
     * 4. docker-compose.yml で設定された mailhog:1025 に SMTP 経由で送信
     * 5. Mailhog がメールをキャッチし、Web UI (http://localhost:8025) で確認可能になる
     *
     * @return \Illuminate\Http\JsonResponse メール送信結果のJSON レスポンス
     */
    public function send()
    {
        // テスト用のメール送信先アドレス
        // 実際には送信されず、Mailhog でキャプチャされる
        $recipient = 'test@example.com';

        // Mail ファサードを使用してメールを送信
        // TestMail クラスで定義された内容（件名、本文、テンプレート）でメールが作成される
        // config/mail.php の設定に基づいて mailhog コンテナの SMTP サーバー（ポート1025）に送信される
        Mail::to($recipient)->send(new TestMail());

        // 送信完了のレスポンスを JSON 形式で返す
        // フロントエンドで結果を表示したり、Mailhog の URL を案内するために使用
        return response()->json([
            'message' => 'テストメールが送信されました',
            'recipient' => $recipient,
            'mailhog_url' => 'http://localhost:8025', // Mailhog の Web UI へのリンク
        ]);
    }
}

