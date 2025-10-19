# Pasabay - Quick Test Script
# This script helps you quickly run both apps for testing

Write-Host "🚀 Pasabay Quick Test Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
if ($flutterVersion) {
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
} else {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Choose what you want to run:" -ForegroundColor Cyan
Write-Host "1. Main User App (Travelers & Requesters) - Port 5000" -ForegroundColor White
Write-Host "2. Verifier Dashboard - Port 8080" -ForegroundColor White
Write-Host "3. Both Apps (Simultaneous Testing)" -ForegroundColor White
Write-Host "4. Build Production APK (Main User App)" -ForegroundColor White
Write-Host "5. Build Production Web (Verifier)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🏃 Running Main User App (Travelers & Requesters) on Chrome..." -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
        Write-Host ""
        flutter run -t lib/main.dart -d chrome --web-port=5000
    }
    "2" {
        Write-Host ""
        Write-Host "🖥️ Running Verifier Dashboard on Chrome..." -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
        Write-Host ""
        flutter run -t lib/verifier.dart -d chrome --web-port=8080
    }
    "3" {
        Write-Host ""
        Write-Host "🎯 Starting both apps..." -ForegroundColor Green
        Write-Host ""
        Write-Host "Main User App will run on: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "Verifier Dashboard will run on: http://localhost:8080" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Opening two PowerShell windows..." -ForegroundColor Yellow
        
        # Start main user app in new window
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '🏃 Main User App' -ForegroundColor Green; flutter run -t lib/main.dart -d chrome --web-port=5000"
        
        Start-Sleep -Seconds 2
        
        # Start verifier dashboard in new window
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '🖥️ Verifier Dashboard' -ForegroundColor Blue; flutter run -t lib/verifier.dart -d chrome --web-port=8080"
        
        Write-Host ""
        Write-Host "✅ Both apps are starting in separate windows!" -ForegroundColor Green
        Write-Host "Close the PowerShell windows to stop the apps" -ForegroundColor Yellow
    }
    "4" {
        Write-Host ""
        Write-Host "📦 Building Main User App APK..." -ForegroundColor Green
        flutter build apk -t lib/main.dart --release
        Write-Host ""
        Write-Host "✅ APK built successfully!" -ForegroundColor Green
        Write-Host "Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
    }
    "5" {
        Write-Host ""
        Write-Host "🌐 Building Verifier Dashboard (Web)..." -ForegroundColor Green
        flutter build web -t lib/verifier.dart --release
        Write-Host ""
        Write-Host "✅ Web build completed successfully!" -ForegroundColor Green
        Write-Host "Location: build\web\" -ForegroundColor Cyan
        Write-Host "Deploy this folder to your web hosting service" -ForegroundColor Yellow
    }
    default {
        Write-Host ""
        Write-Host "❌ Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
