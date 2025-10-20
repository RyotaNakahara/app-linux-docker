<?php

/*
|--------------------------------------------------------------------------
| メール設定
|--------------------------------------------------------------------------
|
| このファイルは Laravel のメール送信機能の設定を定義します。
|
| 【Mailhog を使用した開発環境の設定】
| docker-compose.yml で以下の環境変数が設定されています：
|   MAIL_MAILER=smtp
|   MAIL_HOST=mailhog          # Mailhog コンテナのホスト名
|   MAIL_PORT=1025             # Mailhog の SMTP ポート
|   MAIL_ENCRYPTION=null       # 暗号化なし（開発環境用）
|
| この設定により、メールは実際には送信されず、Mailhog でキャプチャされます。
| Mailhog Web UI (http://localhost:8025) で送信されたメールを確認できます。
|
*/

return [

    /*
    |--------------------------------------------------------------------------
    | デフォルトメーラー
    |--------------------------------------------------------------------------
    |
    | 使用するメール送信方法を指定します。
    | 'smtp' を指定すると、下記の 'smtp' 設定が使用されます。
    | 開発環境では Mailhog コンテナに接続されます。
    |
    */
    'default' => env('MAIL_MAILER', 'log'),

    'mailers' => [

        /*
        |--------------------------------------------------------------------------
        | SMTP メーラー（Mailhog 用）
        |--------------------------------------------------------------------------
        |
        | SMTP プロトコルを使用してメールを送信します。
        | 開発環境では、これらの設定により Mailhog コンテナに接続されます：
        |
        | - host: mailhog (Docker Compose のサービス名)
        | - port: 1025 (Mailhog の SMTP ポート)
        | - encryption: null (暗号化なし)
        | - username/password: null (認証なし)
        |
        | Mailhog がメールをキャッチし、http://localhost:8025 で確認可能になります。
        |
        */
        'smtp' => [
            'transport' => 'smtp',
            'url' => env('MAIL_URL'),
            'host' => env('MAIL_HOST', '127.0.0.1'),        // Mailhog の場合: 'mailhog'
            'port' => env('MAIL_PORT', 2525),               // Mailhog の場合: 1025
            'encryption' => env('MAIL_ENCRYPTION', 'tls'),  // Mailhog の場合: null
            'username' => env('MAIL_USERNAME'),             // Mailhog の場合: null
            'password' => env('MAIL_PASSWORD'),             // Mailhog の場合: null
            'timeout' => null,
            'local_domain' => env('MAIL_EHLO_DOMAIN', parse_url(env('APP_URL', 'http://localhost'), PHP_URL_HOST)),
        ],

        'ses' => [
            'transport' => 'ses',
        ],

        'postmark' => [
            'transport' => 'postmark',
        ],

        'resend' => [
            'transport' => 'resend',
        ],

        'sendmail' => [
            'transport' => 'sendmail',
            'path' => env('MAIL_SENDMAIL_PATH', '/usr/sbin/sendmail -bs -i'),
        ],

        'log' => [
            'transport' => 'log',
            'channel' => env('MAIL_LOG_CHANNEL'),
        ],

        'array' => [
            'transport' => 'array',
        ],

        'failover' => [
            'transport' => 'failover',
            'mailers' => [
                'smtp',
                'log',
            ],
        ],

        'roundrobin' => [
            'transport' => 'roundrobin',
            'mailers' => [
                'ses',
                'postmark',
            ],
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | グローバル送信元アドレス
    |--------------------------------------------------------------------------
    |
    | すべてのメールで使用されるデフォルトの送信元アドレスと名前を設定します。
    | 各メールクラスで個別に上書きすることもできます。
    |
    | Mailhog を使用する場合、この設定は Mailhog の受信トレイに表示されます。
    |
    */
    'from' => [
        'address' => env('MAIL_FROM_ADDRESS', 'hello@example.com'),
        'name' => env('MAIL_FROM_NAME', 'Example'),
    ],

];

