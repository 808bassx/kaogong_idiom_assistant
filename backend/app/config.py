"""
应用配置文件
支持通过环境变量覆盖默认值
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # 应用基础配置
    APP_NAME: str = "考公成语随身助教"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # 服务器配置
    HOST: str = "127.0.0.1"
    PORT: int = 8000

    # 数据库配置
    DATABASE_URL: str = "sqlite+aiosqlite:///./data/kaogong.db"
    DATABASE_ECHO: bool = False

    # AI 引擎配置
    AI_ENGINE: str = "ollama"  # ollama 或 llamacpp
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "qwen2.5:7b"
    LLAMACPP_API_URL: str = "http://localhost:8080"
    LLAMACPP_MODEL: str = "qwen2.5-7b-q4.gguf"

    # 系统 Prompt
    SYSTEM_PROMPT: str = """你是一位专业的考公成语助教。你的职责是：
1. 解释成语的拼音、释义、出处、用法和例句
2. 提供近义词、反义词和易混词辨析
3. 给出记忆技巧帮助记忆
4. 用简洁清晰的中文回答
5. 适当举例说明成语在申论和行测中的用法

请始终保持专业、准确、有帮助。"""

    # 学习配置
    REVIEW_INTERVALS_DAY: list = [1, 2, 4, 7, 15, 30]  # 艾宾浩斯复习间隔
    WORDS_PER_PAGE: int = 20
    MAX_HISTORY_MESSAGES: int = 100

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
