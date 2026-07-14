# 考公成语随身助教 🎯

> 一款完全离线的本地 AI 成语学习软件，支持 Windows、Linux、macOS、Android。
> 基于 Flutter + FastAPI + SQLite + Ollama/llama.cpp 构建。

---

## 📋 项目概述

**考公成语随身助教** 是一款专为公务员考试备考者设计的成语学习助手。它利用本地大语言模型（通过 Ollama 或 llama.cpp）提供智能成语解释、个性化复习计划和全面的学习管理功能。

### ✨ 核心特性

| 特性 | 说明 |
|------|------|
| 🔒 **完全离线** | 不依赖任何外部 API，所有数据本地保存 |
| 🤖 **本地 AI** | 支持 Ollama 和 llama.cpp，可切换多种大模型 |
| 📱 **跨平台** | Windows / Linux / macOS / Android，一套代码 |
| 🎨 **Material Design 3** | 现代化 UI 设计，支持深色/浅色模式 |
| 🧠 **艾宾浩斯复习** | 基于遗忘曲线的智能复习提醒 |
| 📊 **数据统计** | 学习日历、折线图、柱状图、掌握率分析 |
| 💾 **数据安全** | 所有数据本地存储，支持备份和恢复 |

---

### 技术栈

- **前端**: Flutter 3.x + Dart, Provider 状态管理, Material Design 3
- **后端**: Python 3.10+, FastAPI, SQLAlchemy (async), aiosqlite
- **AI 引擎**: Ollama (默认), llama.cpp (备选)
- **数据库**: SQLite (本地文件存储)
- **支持模型**: Qwen3, Qwen2.5, DeepSeek, GLM, Llama, Gemma, Mistral 等

---

## 🚀 快速开始

### 1️⃣ 环境准备

#### 安装 Flutter SDK
```bash
# Windows: 从 https://flutter.dev 下载安装
# Linux/macOS:
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter precache
```

#### 安装 Python 3.10+
```bash
# 从 https://www.python.org/downloads/ 下载安装
python --version  # 确认 ≥ 3.10
```

#### 安装 Ollama（推荐）
```bash
# 从 https://ollama.com/download 下载安装
# 下载成语相关模型
ollama pull qwen2.5:7b
# 或使用其他模型
ollama pull deepseek-r1:7b
```

### 2️⃣ 启动后端

```bash
cd backend

# 安装依赖
pip install -r requirements.txt

# 启动服务（默认 127.0.0.1:8000）
python run.py
```

访问 http://127.0.0.1:8000/docs 查看 API 文档。

### 3️⃣ 启动前端

```bash
cd flutter_app

# 获取依赖
flutter pub get

# 运行（Windows/Linux/macOS）
flutter run -d windows
# 或
flutter run -d linux
# 或
flutter run -d macos

# 运行 Android
flutter run -d emulator-5554
```

---

## 📱 功能模块

### 🏠 首页
- 今日学习概览（学习数、新增数、累计数）
- 继续学习 / 随机抽查快捷入口
- 最近学习动态
- 快捷操作（搜索、抽查、复习、AI对话）

### 💬 AI 对话
- 成语智能解释（拼音、释义、出处、用法、例句等）
- 流式输出，实时显示
- Markdown 渲染和代码高亮
- 对话历史保存和管理

### 📖 词库管理
- 成语列表（分页、标签筛选）
- 搜索（关键词、拼音、模糊搜索）
- 收藏功能
- 学习状态追踪

### 🎯 抽查模式
- 随机出题（5/10/20 题可选）
- 用户输入答案
- 自动评分和正确率统计

### 📅 每日复习
- 基于艾宾浩斯遗忘曲线
- 自动推荐今日复习内容
- 复习进度追踪

### 📊 数据统计
- 学习概览（累计、今日、本周、本月）
- 掌握率分析
- 学习日历
- 统计图表

### ⚙️ 设置
- AI 模型切换（Ollama/llama.cpp）
- 模型地址和名称配置
- 主题切换（浅色/深色/跟随系统）
- 字体大小调整
- 语言切换（中文/English）
- 数据库备份和恢复
- System Prompt 管理



---

## 🤖 AI 模型配置

### 默认配置（Ollama）

```bash
# 启动 Ollama 并加载模型
ollama serve
ollama pull qwen2.5:7b

# 后端配置 (.env)
AI_ENGINE=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen2.5:7b
```

### llama.cpp 配置

```bash
# 启动 llama.cpp 服务
./server -m models/qwen2.5-7b-q4.gguf --host 127.0.0.1 --port 8080

# 后端配置 (.env)
AI_ENGINE=llamacpp
LLAMACPP_API_URL=http://localhost:8080
```

### 支持的模型

| 模型 | Ollama 名称 | 推荐 |
|------|------------|------|
| Qwen2.5 7B | `qwen2.5:7b` | ⭐ 推荐 |
| Qwen3 8B | `qwen3:8b` | ⭐ 推荐 |
| DeepSeek-R1 7B | `deepseek-r1:7b` | 推理能力强 |
| GLM4 9B | `glm4:9b` | 中文优秀 |
| Llama 3.1 8B | `llama3.1:8b` | 通用 |
| Gemma 2 9B | `gemma2:9b` | 轻量 |
| Mistral 7B | `mistral:7b` | 高效 |

---

## 🖥️ 打包部署

### 环境变量（中国大陆镜像加速）

```bash
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export ANDROID_HOME="C:/Users/<用户名>/Android"   # Android 打包需要
```

### Windows 打包

```bash
cd flutter_app
flutter build windows --release
```

产物: `flutter_app/build/windows/x64/runner/Release/`
已打包至: `dist/kaogong_idiom_win/`（含后端 + 启动脚本）

### Android 打包

```bash
cd flutter_app
flutter build apk --release       # APK
flutter build appbundle --release # AAB（上架 Google Play）
```

产物:
- APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `flutter_app/build/app/outputs/bundle/release/app-release.aab`

### Linux 打包

```bash
cd flutter_app
flutter build linux --release
```

产物: `flutter_app/build/linux/x64/release/bundle/`

---

## 🔧 开发指南

### 运行测试
```bash
# 后端
cd backend
pytest

# 前端
cd flutter_app
flutter test
```

### 代码风格
```bash
# Python
pip install black isort
black backend/
isort backend/

# Flutter
cd flutter_app
dart format .
```

### 数据库迁移
数据库自动创建和迁移，如需手动操作：
```bash
cd backend
python -c "from app.database import init_db; import asyncio; asyncio.run(init_db())"
```

---

## 📄 许可证

MIT License

## 👨‍💻 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系

项目主页: https://github.com/808bassx/kaogong_idiom_assistant

---
