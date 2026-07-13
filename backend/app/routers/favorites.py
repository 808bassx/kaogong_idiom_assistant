"""
收藏管理 API 路由
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models import Word, Favorite

router = APIRouter(prefix="/api/favorites", tags=["收藏管理"])


@router.get("")
async def list_favorites(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """获取收藏列表"""
    # 总数
    count_result = await db.execute(
        select(func.count(Word.id)).where(Word.is_favorite == True)
    )
    total = count_result.scalar() or 0

    # 分页查询
    result = await db.execute(
        select(Word)
        .where(Word.is_favorite == True)
        .order_by(Word.updated_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    words = [w.to_dict() for w in result.scalars().all()]

    return {"total": total, "page": page, "page_size": page_size, "words": words}


@router.post("/{word_id}")
async def add_favorite(word_id: int, db: AsyncSession = Depends(get_db)):
    """添加收藏"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        return {"error": "词语不存在"}

    word.is_favorite = True

    # 检查收藏记录
    fav_result = await db.execute(
        select(Favorite).where(Favorite.word_id == word_id)
    )
    if not fav_result.scalar_one_or_none():
        fav = Favorite(word_id=word_id, word=word.word)
        db.add(fav)

    await db.flush()
    return {"message": "已收藏", "word_id": word_id}


@router.delete("/{word_id}")
async def remove_favorite(word_id: int, db: AsyncSession = Depends(get_db)):
    """取消收藏"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if word:
        word.is_favorite = False

    # 删除收藏记录
    result = await db.execute(
        select(Favorite).where(Favorite.word_id == word_id)
    )
    fav = result.scalar_one_or_none()
    if fav:
        await db.delete(fav)

    await db.flush()
    return {"message": "已取消收藏", "word_id": word_id}
