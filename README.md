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

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────┐
│                  Flutter 前端                    │
│          Material Design 3 / Provider            │
│     Windows │ Linux │ macOS │ Android            │
└──────────────────────┬──────────────────────────┘
                       │ HTTP REST API
                       ▼
┌─────────────────────────────────────────────────┐
│                Python 后端 (FastAPI)              │
│            SQLAlchemy + SQLite + AI Service       │
└──────────┬──────────────────────────┬────────────┘
           │                          │
           ▼                          ▼
┌──────────────────┐    ┌──────────────────────────┐
│   Ollama 服务     │    │   llama.cpp HTTP Server  │
│  (Qwen/DeepSeek/  │    │   (GGUF 模型文件)         │
│   Llama/GLM...)   │    │                          │
└──────────────────┘    └──────────────────────────┘
```

### 技术栈

- **前端**: Flutter 3.x + Dart, Provider 状态管理, Material Design 3
- **后端**: Python 3.10+, FastAPI, SQLAlchemy (async), aiosqlite
- **AI 引擎**: Ollama (默认), llama.cpp (备选)
- **数据库**: SQLite (本地文件存储)
- **支持模型**: Qwen3, Qwen2.5, DeepSeek, GLM, Llama, Gemma, Mistral 等

---

## 📦 项目结构

```
kaogong_idiom_assistant/
├── backend/                          # Python 后端
│   ├── app/
│   │   ├── main.py                   # FastAPI 主应用
│   │   ├── config.py                 # 配置文件
│   │   ├── database.py               # 数据库连接
│   │   ├── models.py                 # ORM 模型
│   │   ├── schemas.py                # Pydantic 验证
│   │   ├── ai/
│   │   │   ├── ollama_client.py      # Ollama 客户端
│   │   │   └── __init__.py
│   │   ├── services/
│   │   │   ├── ai_service.py         # AI 服务层
│   │   │   ├── review_service.py     # 复习服务
│   │   │   └── stats_service.py      # 统计服务
│   │   └── routers/
│   │       ├── words.py              # 词库管理
│   │       ├── chat.py               # AI 对话
│   │       ├── study.py              # 学习记录
│   │       ├── review.py             # 复习管理
│   │       ├── quiz.py               # 抽查模式
│   │       ├── favorites.py          # 收藏管理
│   │       ├── stats.py              # 数据统计
│   │       ├── export.py             # 数据导出
│   │       ├── import_api.py          # 数据导入
│   │       ├── settings.py           # 应用设置
│   │       └── prompt.py             # Prompt 管理
│   ├── requirements.txt
│   ├── run.py                        # 启动脚本
│   └── .env                          # 环境配置
│
├── flutter_app/                      # Flutter 前端
│   ├── lib/
│   │   ├── main.dart                 # 入口文件
│   │   ├── app.dart                  # 主导航
│   │   ├── config/
│   │   │   ├── theme.dart            # 主题配置
│   │   │   └── constants.dart        # 常量定义
│   │   ├── models/
│   │   │   ├── word.dart             # 词语模型
│   │   │   └── chat_message.dart     # 消息模型
│   │   ├── services/
│   │   │   └── api_service.dart      # API 服务
│   │   ├── providers/
│   │   │   ├── theme_provider.dart   # 主题管理
│   │   │   ├── word_provider.dart    # 词库管理
│   │   │   ├── chat_provider.dart    # 对话管理
│   │   │   └── settings_provider.dart # 设置管理
│   │   ├── screens/
│   │   │   ├── home_screen.dart      # 首页
│   │   │   ├── chat_screen.dart      # AI 对话
│   │   │   ├── word_list_screen.dart # 词库列表
│   │   │   ├── word_detail_screen.dart # 词语详情
│   │   │   ├── search_screen.dart    # 搜索
│   │   │   ├── quiz_screen.dart      # 抽查模式
│   │   │   ├── review_screen.dart    # 每日复习
│   │   │   ├── stats_screen.dart     # 数据统计
│   │   │   ├── settings_screen.dart  # 设置
│   │   │   └── prompt_screen.dart    # Prompt 管理
│   │   └── widgets/
│   │       ├── word_card.dart        # 词语卡片
│   │       ├── loading_indicator.dart # 加载动画
│   │       └── empty_widget.dart     # 空状态
│   └── pubspec.yaml
│
├── build_scripts/
│   ├── build_windows.bat             # Windows 构建
│   ├── build_android.bat             # Android 构建
│   └── build_linux.sh                # Linux 构建
│
├── README.md
└── .gitignore
```

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

## 🗄️ 数据库设计

### words（词库表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| word | VARCHAR(50) | 成语词语 |
| pinyin | VARCHAR(200) | 拼音 |
| meaning | TEXT | 释义 |
| source | VARCHAR(500) | 出处 |
| usage | TEXT | 用法 |
| example | TEXT | 例句 |
| synonym | VARCHAR(500) | 近义词 |
| antonym | VARCHAR(500) | 反义词 |
| confusable | VARCHAR(500) | 易混词 |
| memory_tip | TEXT | 记忆技巧 |
| tags | VARCHAR(200) | 标签 |
| is_mastered | BOOLEAN | 是否掌握 |
| review_count | INTEGER | 复习次数 |
| error_count | INTEGER | 错误次数 |
| is_favorite | BOOLEAN | 是否收藏 |
| notes | TEXT | 备注 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |
| last_reviewed_at | DATETIME | 最后复习时间 |

### study_history（学习历史）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| word_id | INTEGER | 词语ID |
| word | VARCHAR(50) | 词语 |
| action | VARCHAR(20) | 操作类型 |
| score | INTEGER | 得分 |
| created_at | DATETIME | 学习时间 |

### review_records（复习记录）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| word_id | INTEGER | 词语ID |
| stage | INTEGER | 复习阶段 |
| next_review_date | DATE | 下次复习日期 |
| is_completed | BOOLEAN | 是否完成 |
| correct_count | INTEGER | 正确次数 |
| wrong_count | INTEGER | 错误次数 |

更多表结构请查看 [models.py](backend/app/models.py)。

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

### Windows 打包

```bash
cd build_scripts
./build_windows.bat
```

产物: `dist/kaogong_idiom_win/`

### Android 打包

```bash
cd build_scripts
./build_android.bat
```

产物:
- APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `flutter_app/build/app/outputs/bundle/release/app-release.aab`

### Linux 打包

```bash
cd build_scripts
chmod +x build_linux.sh
./build_linux.sh
```

产物: `dist/kaogong_idiom_linux/`

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

项目主页: https://github.com/yourname/kaogong_idiom_assistant

---

**祝您考公顺利，成语功力大增！** 🎉
