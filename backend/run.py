"""
启动脚本 - 运行 FastAPI 服务器
"""
import os
import sys

# 尝试设置 UTF-8 编码以支持 emoji 显示
if sys.stdout.encoding and sys.stdout.encoding.lower() in ('gbk', 'gb2312', 'gb18030'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

import uvicorn
from app.config import settings


if __name__ == "__main__":
    print(f"{settings.APP_NAME} v{settings.APP_VERSION}")
    print(f"API doc: http://{settings.HOST}:{settings.PORT}/docs")
    print(f"AI Engine: {settings.AI_ENGINE}")
    print(f"Ollama URL: {settings.OLLAMA_BASE_URL}")
    print(f"Model: {settings.OLLAMA_MODEL}")
    print("-" * 50)

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info",
    )
