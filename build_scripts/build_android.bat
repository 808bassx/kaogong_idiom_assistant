@echo off
chcp 65001 >nul
echo =====================================
echo  考公成语随身助教 - Android 构建脚本
echo =====================================
echo.

REM 检查 Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ 未找到 Flutter SDK，请先安装 Flutter
    pause
    exit /b 1
)

REM 检查 Android SDK
if "%ANDROID_HOME%"=="" (
    if "%ANDROID_SDK_ROOT%"=="" (
        echo ❌ 未设置 ANDROID_HOME 环境变量
        echo   请安装 Android Studio 并配置 Android SDK
        pause
        exit /b 1
    )
)

echo ✅ 环境检查通过
echo.

cd /d "%~dp0..\flutter_app"

REM 获取依赖
echo [1/4] 获取 Flutter 依赖...
flutter pub get
echo ✅ Flutter 依赖获取完成
echo.

REM 清理
echo [2/4] 清理旧构建...
flutter clean
echo ✅ 清理完成
echo.

REM 构建 APK
echo [3/4] 构建 Android APK...
flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo ❌ APK 构建失败
    pause
    exit /b 1
)
echo ✅ APK 构建成功
echo.

REM 构建 App Bundle（可选）
echo [4/4] 构建 Android App Bundle...
flutter build appbundle --release
if %ERRORLEVEL% neq 0 (
    echo ⚠️  App Bundle 构建失败（可忽略）
) else (
    echo ✅ App Bundle 构建成功
)

echo.
echo =====================================
echo  构建完成！
echo.
echo  📱 APK 位置:
echo     build\app\outputs\flutter-apk\app-release.apk
echo.
echo  📦 App Bundle 位置:
echo     build\app\outputs\bundle\release\app-release.aab
echo.
echo  安装说明:
echo   1. 将 APK 传输到 Android 设备
echo   2. 在设置中允许"安装未知来源应用"
echo   3. 安装 APK
echo.
echo  注意: Android 版需要后端服务支持
echo  建议在局域网内运行后端服务
echo =====================================
pause
