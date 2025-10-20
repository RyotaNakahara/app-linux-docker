#Requires -RunAsAdministrator

<#
.SYNOPSIS
    hostsファイルにlaravel-app.testドメインを追加するスクリプト

.DESCRIPTION
    このスクリプトは管理者権限で実行され、Windowsのhostsファイルに
    laravel-app.testドメインを追加します。

.EXAMPLE
    .\setup-hosts.ps1
#>

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$domain = "laravel-app.test"
$ip = "127.0.0.1"
$entry = "$ip`t$domain"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Laravel Hosts Setup Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 管理者権限チェック
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "エラー: このスクリプトは管理者権限で実行する必要があります" -ForegroundColor Red
    Write-Host "PowerShellを右クリックして「管理者として実行」を選択してください" -ForegroundColor Yellow
    exit 1
}

# hostsファイルの存在確認
if (-not (Test-Path $hostsPath)) {
    Write-Host "エラー: hostsファイルが見つかりません: $hostsPath" -ForegroundColor Red
    exit 1
}

# 既存のエントリをチェック
$hostsContent = Get-Content $hostsPath -Raw
if ($hostsContent -match [regex]::Escape($domain)) {
    Write-Host "✓ ドメイン '$domain' は既にhostsファイルに存在します" -ForegroundColor Green
    Write-Host ""
    Write-Host "現在のhostsファイルの内容 (最後の10行):" -ForegroundColor Yellow
    Get-Content $hostsPath | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" }
} else {
    # バックアップを作成
    $backupPath = "$hostsPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    try {
        Copy-Item $hostsPath $backupPath -ErrorAction Stop
        Write-Host "✓ バックアップを作成しました: $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "警告: バックアップの作成に失敗しました" -ForegroundColor Yellow
    }

    # エントリを追加
    try {
        Add-Content -Path $hostsPath -Value "`n# Laravel Docker Development`n$entry" -ErrorAction Stop
        Write-Host "✓ hostsファイルにエントリを追加しました: $entry" -ForegroundColor Green
    } catch {
        Write-Host "エラー: hostsファイルへの書き込みに失敗しました" -ForegroundColor Red
        Write-Host "詳細: $_" -ForegroundColor Red
        exit 1
    }
}

# DNSキャッシュをクリア
Write-Host ""
Write-Host "DNSキャッシュをクリアしています..." -ForegroundColor Yellow
try {
    ipconfig /flushdns | Out-Null
    Write-Host "✓ DNSキャッシュをクリアしました" -ForegroundColor Green
} catch {
    Write-Host "警告: DNSキャッシュのクリアに失敗しました" -ForegroundColor Yellow
}

# 完了メッセージ
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "セットアップが完了しました！" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "次のステップ:" -ForegroundColor Yellow
Write-Host "1. Dockerコンテナが起動しているか確認:" -ForegroundColor White
Write-Host "   docker compose ps" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. ブラウザで以下にアクセス:" -ForegroundColor White
Write-Host "   http://laravel-app.test/" -ForegroundColor Cyan
Write-Host ""

