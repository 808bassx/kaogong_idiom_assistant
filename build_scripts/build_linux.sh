#!/bin/bash
# 考公成语随身助教 - Linux 构建脚本

echo "====================================="
echo " 考公成语随身助教 - Linux 构建脚本"
echo "====================================="
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ 未找到 Flutter SDK"
    echo "   请从 https://flutter.dev 安装"
    exit 1
fi

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到 Python3"
    exit 1
fi

echo "✅ 环境检查通过"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# 后端依赖
echo "[1/4] 安装后端依赖..."
cd backend
pip3 install -r requirements.txt -q
cd ..
echo "✅ 后端依赖安装完成"

# Flutter 依赖
echo "[2/4] 获取 Flutter 依赖..."
cd flutter_app
flutter pub get
echo "✅ Flutter 依赖获取完成"

# 构建 Linux
echo "[3/4] 构建 Linux 桌面应用..."
flutter build linux --release
if [ $? -ne 0 ]; then
    echo "❌ Linux 构建失败"
    exit 1
fi
echo "✅ Linux 构建成功"

# 创建发布包
echo "[4/4] 创建发布包..."
RELEASE_DIR="build/linux/x64/release/bundle"
OUTPUT_DIR="../dist/kaogong_idiom_linux"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "$RELEASE_DIR" "$OUTPUT_DIR/app"
cp -r ../backend "$OUTPUT_DIR/backend"

cat > "$OUTPUT_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "启动考公成语随身助教..."
cd "$(dirname "$0")"
gnome-terminal -- bash -c "cd backend && python3 run.py" &
sleep 2
./app/kaogong_idiom_assistant &
EOF
chmod +x "$OUTPUT_DIR/start.sh"

echo ""
echo "====================================="
echo "  构建完成！"
echo ""
echo "  📦 发布包: dist/kaogong_idiom_linux"
echo "  🚀 运行: ./start.sh"
echo "====================================="
