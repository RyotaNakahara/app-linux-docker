<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>テストメール</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #667eea;
        }
        .info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #999;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>✅ メール送信テスト成功</h1>
        <p>こんにちは！</p>
        <p>Laravel Docker 環境からのテストメールです。このメールが表示されているということは、メール送信機能が正常に動作しています。</p>

        <div class="info">
            <strong>環境情報:</strong>
            <ul>
                <li>Laravel バージョン: {{ app()->version() }}</li>
                <li>PHP バージョン: {{ phpversion() }}</li>
                <li>送信日時: {{ now()->format('Y-m-d H:i:s') }}</li>
            </ul>
        </div>

        <p>このメールは Mailhog で確認できます: <a href="http://localhost:8025">http://localhost:8025</a></p>

        <div class="footer">
            Laravel Docker Environment | Mailhog Test
        </div>
    </div>
</body>
</html>

