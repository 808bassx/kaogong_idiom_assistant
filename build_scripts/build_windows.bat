@echo off
chcp 65001 >nul
echo =====================================
echo  考公成语随身助教 - Windows 构建脚本
echo =====================================
echo.

REM 检查 Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ 未找到 Flutter SDK，请先安装 Flutter
    echo   下载地址: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

REM 检查 Python
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ 未找到 Python，请先安装 Python 3.10+
    echo   下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ 环境检查通过
echo.

REM ===== 构建后端 =====
echo [1/4] 安装后端依赖...
cd /d "%~dp0..\backend"
pip install -r requirements.txt -q
echo ✅ 后端依赖安装完成
echo.

REM ===== 构建 Flutter =====
echo [2/4] 获取 Flutter 依赖...
cd /d "%~dp0..\flutter_app"
flutter pub get
echo ✅ Flutter 依赖获取完成
echo.

echo [3/4] 构建 Windows 桌面应用...
REM 清理旧构建
if exist "build\windows" (
    rmdir /s /q "build\windows"
)
flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Windows 构建失败
    pause
    exit /b 1
)
echo ✅ Windows 构建成功
echo.

echo [4/4] 创建发布包...
set RELEASE_DIR=build\windows\runner\Release
set OUTPUT_DIR=..\dist\kaogong_idiom_win

if exist "%OUTPUT_DIR%" (
    rmdir /s /q "%OUTPUT_DIR%"
)
mkdir "%OUTPUT_DIR%"

REM 复制 Flutter 构建产物
xcopy /E /I /Y "%RELEASE_DIR%\*" "%OUTPUT_DIR%\app\"

REM 创建启动脚本
echo @echo off > "%OUTPUT_DIR%\start_backend.bat"
echo chcp 65001 ^>nul >> "%OUTPUT_DIR%\start_backend.bat"
echo echo 启动后端服务... >> "%OUTPUT_DIR%\start_backend.bat"
echo cd /d "%%~dp0backend" >> "%OUTPUT_DIR%\start_backend.bat"
echo python run.py >> "%OUTPUT_DIR%\start_backend.bat"
echo pause >> "%OUTPUT_DIR%\start_backend.bat"

echo @echo off > "%OUTPUT_DIR%\start_app.bat"
echo chcp 65001 ^>nul >> "%OUTPUT_DIR%\start_app.bat"
echo echo 启动考公成语随身助教... >> "%OUTPUT_DIR%\start_app.bat"
echo start "" "%%~dp0app\kaogong_idiom_assistant.exe" >> "%OUTPUT_DIR%\start_app.bat"

REM 复制后端
xcopy /E /I /Y "..\backend" "%OUTPUT_DIR%\backend\" ^
    /EXCLUDE:..\.gitignore

REM 创建 README
echo 考公成语随身助教 - Windows 版 > "%OUTPUT_DIR%\README.txt"
echo. >> "%OUTPUT_DIR%\README.txt"
echo 使用说明： >> "%OUTPUT_DIR%\README.txt"
echo 1. 先双击 start_backend.bat 启动后端服务 >> "%OUTPUT_DIR%\README.txt"
echo 2. 再双击 start_app.bat 启动应用 >> "%OUTPUT_DIR%\README.txt"
echo 3. 确保已安装 Ollama 并运行本地模型 >> "%OUTPUT_DIR%\README.txt"

echo.
echo ✅ 发布包已创建: %OUTPUT_DIR%
echo.
echo =====================================
echo  构建完成！
echo.
echo  📦 发布包位置: dist\kaogong_idiom_win
echo  🚀 先运行: start_backend.bat
echo  🖥️  再运行: start_app.bat
echo =====================================
pause
