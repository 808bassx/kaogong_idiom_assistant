"""
应用设置 API 路由
"""
import json
import os
import shutil
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import AppSetting
from app.schemas import AIConfig, AIConfigUpdate
from app.config import settings as app_settings
from app.services.ai_service import ai_service

router = APIRouter(prefix="/api/settings", tags=["应用设置"])


@router.get("")
async def get_all_settings(db: AsyncSession = Depends(get_db)):
    """获取所有设置"""
    result = await db.execute(select(AppSetting))
    settings_list = result.scalars().all()

    settings_dict = {}
    for s in settings_list:
        settings_dict[s.key] = s.value

    # 确保有默认值
    defaults = {
        "theme": "light",
        "language": "zh",
        "font_size": "16",
        "ai_engine": app_settings.AI_ENGINE,
        "ai_base_url": app_settings.OLLAMA_BASE_URL,
        "ai_model": app_settings.OLLAMA_MODEL,
    }

    for key, default_value in defaults.items():
        if key not in settings_dict:
            settings_dict[key] = default_value

    return settings_dict


@router.get("/{key}")
async def get_setting(key: str, db: AsyncSession = Depends(get_db)):
    """获取单个设置"""
    result = await db.execute(
        select(AppSetting).where(AppSetting.key == key)
    )
    setting = result.scalar_one_or_none()
    if not setting:
        raise HTTPException(status_code=404, detail="设置不存在")
    return {"key": setting.key, "value": setting.value}


@router.put("/{key}")
async def update_setting(key: str, value: str = Query(...), db: AsyncSession = Depends(get_db)):
    """更新设置"""
    result = await db.execute(
        select(AppSetting).where(AppSetting.key == key)
    )
    setting = result.scalar_one_or_none()

    if setting:
        setting.value = value
    else:
        setting = AppSetting(key=key, value=value)
        db.add(setting)

    await db.flush()
    return {"key": key, "value": value}


@router.put("")
async def update_settings(
    settings: dict,
    db: AsyncSession = Depends(get_db),
):
    """批量更新设置"""
    updated = []
    for key, value in settings.items():
        result = await db.execute(
            select(AppSetting).where(AppSetting.key == key)
        )
        setting = result.scalar_one_or_none()
        if setting:
            setting.value = str(value)
        else:
            setting = AppSetting(key=key, value=str(value))
            db.add(setting)
        updated.append(key)

    await db.flush()
    return {"updated": updated}


@router.get("/ai/config", response_model=AIConfig)
async def get_ai_config(db: AsyncSession = Depends(get_db)):
    """获取 AI 配置"""
    config = {}
    for key in ["ai_engine", "ai_base_url", "ai_model"]:
        result = await db.execute(
            select(AppSetting).where(AppSetting.key == key)
        )
        setting = result.scalar_one_or_none()
        config[key.replace("ai_", "")] = setting.value if setting else ""

    return AIConfig(
        engine=config.get("engine", app_settings.AI_ENGINE),
        base_url=config.get("base_url", app_settings.OLLAMA_BASE_URL),
        model=config.get("model", app_settings.OLLAMA_MODEL),
    )


@router.put("/ai/config")
async def update_ai_config(
    data: AIConfigUpdate,
    db: AsyncSession = Depends(get_db),
):
    """更新 AI 配置"""
    updates = {}
    if data.engine:
        updates["ai_engine"] = data.engine
    if data.base_url:
        updates["ai_base_url"] = data.base_url
    if data.model:
        updates["ai_model"] = data.model

    for key, value in updates.items():
        result = await db.execute(
            select(AppSetting).where(AppSetting.key == key)
        )
        setting = result.scalar_one_or_none()
        if setting:
            setting.value = value
        else:
            db.add(AppSetting(key=key, value=value))

    await db.flush()

    # 重置 AI 客户端
    ai_service._ollama_client = None
    ai_service._llamacpp_client = None

    return {"message": "AI 配置已更新", **updates}


@router.get("/ai/health")
async def check_ai_health():
    """检查 AI 服务健康状态"""
    health = await ai_service.check_health()
    return health


@router.get("/ai/models")
async def list_ai_models(
    engine: str = Query("ollama", description="AI引擎类型"),
):
    """获取可用模型列表"""
    models = await ai_service.list_available_models(engine)
    return {"engine": engine, "models": models}


@router.post("/backup")
async def backup_database(db: AsyncSession = Depends(get_db)):
    """备份数据库"""
    backup_dir = os.path.join(os.path.dirname(app_settings.DATABASE_URL.replace("sqlite+aiosqlite:///", "")), "backups")
    os.makedirs(backup_dir, exist_ok=True)

    db_path = app_settings.DATABASE_URL.replace("sqlite+aiosqlite:///", "")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(backup_dir, f"kaogong_backup_{timestamp}.db")

    if os.path.exists(db_path):
        shutil.copy2(db_path, backup_path)
        return {
            "message": "数据库备份成功",
            "backup_path": backup_path,
            "backup_time": timestamp,
        }
    raise HTTPException(status_code=404, detail="数据库文件不存在")


@router.post("/restore")
async def restore_database(
    backup_file: str = Query(..., description="备份文件名"),
):
    """恢复数据库"""
    backup_dir = os.path.join(os.path.dirname(app_settings.DATABASE_URL.replace("sqlite+aiosqlite:///", "")), "backups")
    backup_path = os.path.join(backup_dir, backup_file)

    if not os.path.exists(backup_path):
        raise HTTPException(status_code=404, detail="备份文件不存在")

    db_path = app_settings.DATABASE_URL.replace("sqlite+aiosqlite:///", "")

    # 关闭当前连接后恢复
    await app_settings.__class__  # 确保配置加载
    from app.database import close_db
    await close_db()

    shutil.copy2(backup_path, db_path)

    # 重新初始化
    from app.database import init_db
    await init_db()

    return {"message": "数据库恢复成功"}


@router.get("/backups")
async def list_backups():
    """列出所有备份"""
    backup_dir = os.path.join(os.path.dirname(app_settings.DATABASE_URL.replace("sqlite+aiosqlite:///", "")), "backups")
    if not os.path.exists(backup_dir):
        return {"backups": []}

    backups = []
    for f in sorted(os.listdir(backup_dir), reverse=True):
        if f.endswith(".db"):
            fpath = os.path.join(backup_dir, f)
            backups.append({
                "filename": f,
                "size": os.path.getsize(fpath),
                "created_at": datetime.fromtimestamp(os.path.getmtime(fpath)).isoformat(),
            })

    return {"backups": backups}
