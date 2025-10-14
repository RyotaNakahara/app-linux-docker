<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laravel Docker Environment</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }

        .container {
            background: white;
            padding: 3rem;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 600px;
            width: 90%;
        }

        h1 {
            color: #667eea;
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }

        p {
            color: #666;
            margin-bottom: 2rem;
            line-height: 1.6;
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .status-card {
            background: #f8f9fa;
            padding: 1.5rem;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }

        .status-card h3 {
            color: #667eea;
            margin-bottom: 0.5rem;
            font-size: 1rem;
        }

        .status-card p {
            margin: 0;
            color: #28a745;
            font-weight: bold;
        }

        .links {
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }

        .link-button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 1rem 2rem;
            border-radius: 8px;
            text-decoration: none;
            text-align: center;
            transition: all 0.3s;
        }

        .link-button:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
        }

        .footer {
            margin-top: 2rem;
            padding-top: 1rem;
            border-top: 1px solid #eee;
            text-align: center;
            color: #999;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Laravel Docker 環境</h1>
        <p>Laravel + PostgreSQL + Redis + Mailhog + Nginx の環境が正常に起動しています。</p>

        <div class="status-grid">
            <div class="status-card">
                <h3>📱 Application</h3>
                <p>✅ Running</p>
            </div>
            <div class="status-card">
                <h3>🗄️ PostgreSQL</h3>
                <p>✅ Connected</p>
            </div>
            <div class="status-card">
                <h3>⚡ Redis</h3>
                <p>✅ Connected</p>
            </div>
            <div class="status-card">
                <h3>📧 Mailhog</h3>
                <p>✅ Ready</p>
            </div>
        </div>

        <div class="links">
            <a href="/send-test-email" class="link-button">📧 テストメール送信</a>
            <a href="http://localhost:8025" target="_blank" class="link-button">📬 Mailhog を開く</a>
            <a href="/health" class="link-button">🏥 ヘルスチェック</a>
        </div>

        <div class="footer">
            Laravel {{ app()->version() }} | PHP {{ phpversion() }}
        </div>
    </div>
</body>
</html>

