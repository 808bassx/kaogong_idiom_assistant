"""
学习管理 API 路由
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc

from app.database import get_db
from app.models import Word, StudyHistory

router = APIRouter(prefix="/api/study", tags=["学习管理"])


@router.get("/today")
async def get_today_study(db: AsyncSession = Depends(get_db)):
    """获取今日学习概况"""
    from datetime import datetime, date

    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())

    # 今日学习数
    result = await db.execute(
        select(func.count(StudyHistory.id))
        .where(
            and_(
                StudyHistory.created_at >= today_start,
                StudyHistory.action.in_(["learn", "review"]),
            )
        )
    )
    today_learned = result.scalar() or 0

    # 今日新增
    result = await db.execute(
        select(func.count(Word.id))
        .where(Word.created_at >= today_start)
    )
    today_new = result.scalar() or 0

    # 累计
    result = await db.execute(select(func.count(Word.id)))
    total = result.scalar() or 0

    # 最近学习
    result = await db.execute(
        select(Word)
        .order_by(Word.updated_at.desc())
        .limit(5)
    )
    recent_words = [w.to_dict() for w in result.scalars().all()]

    return {
        "today_learned": today_learned,
        "today_new": today_new,
        "total_words": total,
        "recent_words": recent_words,
    }


@router.get("/recent")
async def get_recent_study(
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
):
    """获取最近学习记录"""
    result = await db.execute(
        select(StudyHistory)
        .order_by(StudyHistory.created_at.desc())
        .limit(limit)
    )
    records = [r.to_dict() for r in result.scalars().all()]
    return {"records": records}


@router.get("/history")
async def get_study_history(
    page: int = 1,
    page_size: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """获取学习历史"""
    from sqlalchemy import desc

    count_result = await db.execute(
        select(func.count(StudyHistory.id))
    )
    total = count_result.scalar() or 0

    result = await db.execute(
        select(StudyHistory)
        .order_by(desc(StudyHistory.created_at))
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    records = [r.to_dict() for r in result.scalars().all()]

    return {"total": total, "page": page, "page_size": page_size, "records": records}
