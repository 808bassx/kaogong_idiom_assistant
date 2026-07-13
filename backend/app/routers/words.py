"""
成语词库 API 路由
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, func, and_

from app.database import get_db
from app.models import Word, StudyHistory, ReviewRecord, Favorite
from app.schemas import (
    WordCreate, WordUpdate, WordResponse, WordListResponse,
)
from app.services.review_service import review_service

router = APIRouter(prefix="/api/words", tags=["成语词库"])


@router.get("", response_model=WordListResponse)
async def list_words(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    tag: Optional[str] = None,
    favorite_only: bool = False,
    mastered_only: Optional[bool] = None,
    db: AsyncSession = Depends(get_db),
):
    """获取词语列表（分页）"""
    query = select(Word)

    if tag:
        query = query.where(Word.tags.contains(tag))
    if favorite_only:
        query = query.where(Word.is_favorite == True)
    if mastered_only is not None:
        query = query.where(Word.is_mastered == mastered_only)

    # 总数
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 分页
    query = query.order_by(Word.updated_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)

    result = await db.execute(query)
    words = list(result.scalars().all())

    return WordListResponse(
        total=total,
        page=page,
        page_size=page_size,
        words=[WordResponse(**w.to_dict()) for w in words],
    )


@router.get("/search", response_model=WordListResponse)
async def search_words(
    keyword: str = Query(..., min_length=1),
    search_type: str = Query("keyword", pattern="^(keyword|pinyin|fuzzy)$"),
    tag: Optional[str] = None,
    favorite_only: bool = False,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """搜索词语"""
    query = select(Word)

    if search_type == "keyword":
        query = query.where(Word.word.contains(keyword))
    elif search_type == "pinyin":
        query = query.where(Word.pinyin.contains(keyword))
    elif search_type == "fuzzy":
        query = query.where(
            or_(
                Word.word.contains(keyword),
                Word.meaning.contains(keyword),
                Word.pinyin.contains(keyword),
                Word.synonym.contains(keyword),
                Word.antonym.contains(keyword),
            )
        )

    if tag:
        query = query.where(Word.tags.contains(tag))
    if favorite_only:
        query = query.where(Word.is_favorite == True)

    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    query = query.order_by(Word.updated_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)

    result = await db.execute(query)
    words = list(result.scalars().all())

    return WordListResponse(
        total=total,
        page=page,
        page_size=page_size,
        words=[WordResponse(**w.to_dict()) for w in words],
    )


@router.get("/{word_id}", response_model=WordResponse)
async def get_word(word_id: int, db: AsyncSession = Depends(get_db)):
    """获取词语详情"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        raise HTTPException(status_code=404, detail="词语不存在")
    return WordResponse(**word.to_dict())


@router.post("", response_model=WordResponse)
async def create_word(data: WordCreate, db: AsyncSession = Depends(get_db)):
    """创建词语"""
    # 检查是否已存在
    result = await db.execute(select(Word).where(Word.word == data.word))
    existing = result.scalar_one_or_none()
    if existing:
        # 更新已有词条
        for key, value in data.model_dump(exclude_unset=True).items():
            if value:
                setattr(existing, key, value)
        await db.flush()
        # 记录学习历史
        history = StudyHistory(
            word_id=existing.id,
            word=existing.word,
            action="learn",
            score=100,
        )
        db.add(history)
        return WordResponse(**existing.to_dict())

    word = Word(**data.model_dump(exclude_unset=True))
    db.add(word)
    await db.flush()

    # 记录学习历史
    history = StudyHistory(
        word_id=word.id,
        word=word.word,
        action="learn",
        score=100,
    )
    db.add(history)

    # 自动创建复习计划
    await review_service.auto_schedule(word.id, word.word, db)

    return WordResponse(**word.to_dict())


@router.put("/{word_id}", response_model=WordResponse)
async def update_word(word_id: int, data: WordUpdate, db: AsyncSession = Depends(get_db)):
    """更新词语"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        raise HTTPException(status_code=404, detail="词语不存在")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(word, key, value)

    await db.flush()
    return WordResponse(**word.to_dict())


@router.delete("/{word_id}")
async def delete_word(word_id: int, db: AsyncSession = Depends(get_db)):
    """删除词语"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        raise HTTPException(status_code=404, detail="词语不存在")

    await db.delete(word)

    # 同时删除关联记录
    for model_cls in [StudyHistory, ReviewRecord, Favorite]:
        await db.execute(
            select(model_cls).where(model_cls.word_id == word_id)
        )

    return {"message": "删除成功", "id": word_id}


@router.post("/{word_id}/master")
async def toggle_master(word_id: int, db: AsyncSession = Depends(get_db)):
    """切换掌握状态"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        raise HTTPException(status_code=404, detail="词语不存在")
    word.is_mastered = not word.is_mastered
    await db.flush()
    return {"is_mastered": word.is_mastered}


@router.post("/{word_id}/favorite")
async def toggle_favorite(word_id: int, db: AsyncSession = Depends(get_db)):
    """切换收藏状态"""
    result = await db.execute(select(Word).where(Word.id == word_id))
    word = result.scalar_one_or_none()
    if not word:
        raise HTTPException(status_code=404, detail="词语不存在")
    word.is_favorite = not word.is_favorite

    if word.is_favorite:
        # 检查收藏记录
        fav_result = await db.execute(
            select(Favorite).where(Favorite.word_id == word_id)
        )
        if not fav_result.scalar_one_or_none():
            fav = Favorite(word_id=word_id, word=word.word)
            db.add(fav)
    else:
        await db.execute(
            select(Favorite).where(Favorite.word_id == word_id)
        )

    await db.flush()
    return {"is_favorite": word.is_favorite}


@router.get("/tags/list", response_model=list)
async def get_tags(db: AsyncSession = Depends(get_db)):
    """获取所有标签及计数"""
    result = await db.execute(select(Word.tags))
    rows = result.all()

    tag_counts = {}
    for (tags_str,) in rows:
        if tags_str:
            for tag in tags_str.split(","):
                tag = tag.strip()
                if tag:
                    tag_counts[tag] = tag_counts.get(tag, 0) + 1

    return [{"tag": k, "count": v} for k, v in sorted(tag_counts.items(), key=lambda x: -x[1])]
