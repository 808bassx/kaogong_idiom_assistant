"""
考公成语随身助教 - FastAPI 主应用
"""
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import init_db, close_db

# 注册路由
from app.routers import (
    words, chat, study, review, quiz,
    favorites, export, import_api, settings as settings_router,
    prompt, stats,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时：初始化数据库
    await init_db()
    yield
    # 关闭时：清理资源
    await close_db()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="考公成语随身助教 - 本地 AI 学习软件后端 API",
    lifespan=lifespan,
)

# CORS 中间件 - 允许 Flutter 客户端跨域访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(words.router)
app.include_router(chat.router)
app.include_router(study.router)
app.include_router(review.router)
app.include_router(quiz.router)
app.include_router(favorites.router)
app.include_router(export.router)
app.include_router(import_api.router)
app.include_router(settings_router.router)
app.include_router(prompt.router)
app.include_router(stats.router)


@app.get("/")
async def root():
    """根路径 - API 信息"""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "status": "running",
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "ok", "service": "backend"}
