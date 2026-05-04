@echo off
cd /d "%~dp0"
echo ===================================================
echo GlucoSense - Flutter APK Build Script
echo ===================================================

echo Checking if Flutter is installed...
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter is not installed or not added to your PATH yet!
    echo Please finish extracting the Flutter zip and add the 'bin' folder to your System PATH variables.
    echo Then restart this window and try again.
    pause
    exit /b 1
)

echo [1] Checking Flutter environment and accepting Android licenses...
call flutter doctor --android-licenses

echo [2] Fetching Flutter dependencies...
call flutter pub get

echo [3] Building the release APK... (This might take a few minutes)
call flutter build apk --release

if %ERRORLEVEL% eq 0 (
    echo ===================================================
    echo SUCCESS! Your APK has been built completely.
    echo You can find your installation file here:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo ===================================================
) else (
    echo ===================================================
    echo [ERROR] Failed to build the APK. Please check the logs above.
    echo Do you have Android Studio installed properly?
    echo ===================================================
)
pause
