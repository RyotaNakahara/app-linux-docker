<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * テストメールクラス
 *
 * Mailhog でメール送信機能をテストするための Mailable クラス。
 * このクラスは Laravel のメール機能が正しく設定されているかを確認するために使用されます。
 *
 * 処理の流れ：
 * 1. MailTestController から Mail::to()->send(new TestMail()) で呼び出される
 * 2. envelope() メソッドでメールの件名を設定
 * 3. content() メソッドでメールの本文テンプレートを指定
 * 4. Laravel が SMTP 経由で mailhog:1025 に送信
 * 5. Mailhog がメールをキャッチし、http://localhost:8025 で確認可能になる
 */
class TestMail extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * 新しいメッセージインスタンスを作成
     *
     * このコンストラクタでメールに渡すデータを設定できます。
     * 現在はテスト用なので特にデータは設定していません。
     */
    public function __construct()
    {
        // テストメールなので特にデータは設定しない
        // 実際の業務メールでは、ユーザー情報や注文情報などをここで受け取る
    }

    /**
     * メールのエンベロープ（封筒）情報を取得
     *
     * メールの件名、送信元、返信先などのメタ情報を定義します。
     * ここで設定した件名が Mailhog の受信トレイに表示されます。
     *
     * @return \Illuminate\Mail\Mailables\Envelope メールのエンベロープ情報
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Laravel Docker 環境テストメール', // メールの件名
        );
    }

    /**
     * メールのコンテンツ（本文）定義を取得
     *
     * メールの本文として使用する Blade テンプレートを指定します。
     * resources/views/emails/test.blade.php が使用され、
     * 環境情報（Laravel バージョン、PHP バージョン、送信日時）を含む
     * HTML メールとして Mailhog に送信されます。
     *
     * @return \Illuminate\Mail\Mailables\Content メールのコンテンツ定義
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.test', // resources/views/emails/test.blade.php を使用
        );
    }

    /**
     * メールに添付するファイルを取得
     *
     * メールに PDF や画像などのファイルを添付する場合はここで指定します。
     * テストメールなので添付ファイルはありません。
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment> 添付ファイルの配列
     */
    public function attachments(): array
    {
        return []; // テストメールなので添付ファイルなし
    }
}

