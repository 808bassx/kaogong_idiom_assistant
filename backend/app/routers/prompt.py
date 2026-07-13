"""
System Prompt 管理 API 路由
"""
import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import PromptTemplate
from app.schemas import PromptCreate, PromptUpdate, PromptResponse
from app.config import settings

router = APIRouter(prefix="/api/prompts", tags=["Prompt管理"])


@router.get("", response_model=list[PromptResponse])
async def list_prompts(db: AsyncSession = Depends(get_db)):
    """获取所有 Prompt 模板"""
    result = await db.execute(
        select(PromptTemplate).order_by(PromptTemplate.created_at.desc())
    )
    prompts = result.scalars().all()
    return [
        PromptResponse(
            id=p.id,
            name=p.name,
            content=p.content,
            is_default=p.is_default,
            is_active=p.is_active,
            created_at=p.created_at.isoformat() if p.created_at else None,
            updated_at=p.updated_at.isoformat() if p.updated_at else None,
        )
        for p in prompts
    ]


@router.get("/active", response_model=PromptResponse)
async def get_active_prompt(db: AsyncSession = Depends(get_db)):
    """获取当前激活的 Prompt"""
    result = await db.execute(
        select(PromptTemplate).where(PromptTemplate.is_active == True)
    )
    prompt = result.scalar_one_or_none()

    if prompt:
        return PromptResponse(
            id=prompt.id,
            name=prompt.name,
            content=prompt.content,
            is_default=prompt.is_default,
            is_active=prompt.is_active,
            created_at=prompt.created_at.isoformat() if prompt.created_at else None,
            updated_at=prompt.updated_at.isoformat() if prompt.updated_at else None,
        )

    # 如果没有激活的，返回默认 Prompt
    return PromptResponse(
        id=0,
        name="默认系统提示词",
        content=settings.SYSTEM_PROMPT,
        is_default=True,
        is_active=True,
        created_at=None,
        updated_at=None,
    )


@router.post("", response_model=PromptResponse)
async def create_prompt(data: PromptCreate, db: AsyncSession = Depends(get_db)):
    """创建 Prompt 模板"""
    # 如果是第一个模板，设为默认和激活
    count_result = await db.execute(select(PromptTemplate))
    existing = count_result.scalars().all()

    prompt = PromptTemplate(
        name=data.name,
        content=data.content,
        is_default=len(existing) == 0,
        is_active=len(existing) == 0,
    )
    db.add(prompt)
    await db.flush()

    return PromptResponse(
        id=prompt.id,
        name=prompt.name,
        content=prompt.content,
        is_default=prompt.is_default,
        is_active=prompt.is_active,
        created_at=prompt.created_at.isoformat() if prompt.created_at else None,
        updated_at=prompt.updated_at.isoformat() if prompt.updated_at else None,
    )


@router.put("/{prompt_id}", response_model=PromptResponse)
async def update_prompt(
    prompt_id: int,
    data: PromptUpdate,
    db: AsyncSession = Depends(get_db),
):
    """更新 Prompt 模板"""
    result = await db.execute(
        select(PromptTemplate).where(PromptTemplate.id == prompt_id)
    )
    prompt = result.scalar_one_or_none()
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt 不存在")

    if data.name is not None:
        prompt.name = data.name
    if data.content is not None:
        prompt.content = data.content
    if data.is_active is not None:
        # 取消其他模板的激活状态
        if data.is_active:
            other_result = await db.execute(
                select(PromptTemplate).where(PromptTemplate.is_active == True)
            )
            for other in other_result.scalars().all():
                other.is_active = False
        prompt.is_active = data.is_active

    await db.flush()

    return PromptResponse(
        id=prompt.id,
        name=prompt.name,
        content=prompt.content,
        is_default=prompt.is_default,
        is_active=prompt.is_active,
        created_at=prompt.created_at.isoformat() if prompt.created_at else None,
        updated_at=prompt.updated_at.isoformat() if prompt.updated_at else None,
    )


@router.delete("/{prompt_id}")
async def delete_prompt(prompt_id: int, db: AsyncSession = Depends(get_db)):
    """删除 Prompt 模板"""
    result = await db.execute(
        select(PromptTemplate).where(PromptTemplate.id == prompt_id)
    )
    prompt = result.scalar_one_or_none()
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt 不存在")
    if prompt.is_default:
        raise HTTPException(status_code=400, detail="无法删除默认 Prompt")

    await db.delete(prompt)
    return {"message": "删除成功"}


@router.post("/{prompt_id}/activate")
async def activate_prompt(prompt_id: int, db: AsyncSession = Depends(get_db)):
    """激活指定的 Prompt 模板"""
    result = await db.execute(
        select(PromptTemplate).where(PromptTemplate.id == prompt_id)
    )
    prompt = result.scalar_one_or_none()
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt 不存在")

    # 取消所有激活
    active_result = await db.execute(
        select(PromptTemplate).where(PromptTemplate.is_active == True)
    )
    for active in active_result.scalars().all():
        active.is_active = False

    # 激活指定模板
    prompt.is_active = True
    await db.flush()

    return {"message": f"已激活 Prompt: {prompt.name}"}


@router.post("/reset-default")
async def reset_default_prompt(db: AsyncSession = Depends(get_db)):
    """恢复默认 Prompt"""
    # 删除所有模板
    result = await db.execute(select(PromptTemplate))
    for p in result.scalars().all():
        await db.delete(p)

    # 创建默认模板
    default_prompt = PromptTemplate(
        name="默认系统提示词",
        content=settings.SYSTEM_PROMPT,
        is_default=True,
        is_active=True,
    )
    db.add(default_prompt)
    await db.flush()

    return {"message": "已恢复默认 Prompt"}


@router.post("/export")
async def export_prompts(db: AsyncSession = Depends(get_db)):
    """导出所有 Prompt 模板"""
    result = await db.execute(
        select(PromptTemplate).order_by(PromptTemplate.id)
    )
    prompts = result.scalars().all()

    export_data = []
    for p in prompts:
        export_data.append({
            "name": p.name,
            "content": p.content,
            "is_default": p.is_default,
        })

    return {"prompts": export_data, "export_time": __import__("datetime").datetime.now().isoformat()}


@router.post("/import")
async def import_prompts(
    data: dict,
    db: AsyncSession = Depends(get_db),
):
    """导入 Prompt 模板"""
    prompts_data = data.get("prompts", [])
    if not prompts_data:
        raise HTTPException(status_code=400, detail="导入数据为空")

    imported = 0
    for item in prompts_data:
        name = item.get("name", "导入的模板")
        content = item.get("content", "")
        if not content:
            continue

        # 检查同名模板
        result = await db.execute(
            select(PromptTemplate).where(PromptTemplate.name == name)
        )
        existing = result.scalar_one_or_none()

        if existing:
            existing.content = content
        else:
            prompt = PromptTemplate(
                name=name,
                content=content,
                is_default=False,
                is_active=False,
            )
            db.add(prompt)
        imported += 1

    await db.flush()
    return {"message": f"成功导入 {imported} 个 Prompt 模板", "count": imported}
