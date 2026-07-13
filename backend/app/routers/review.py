"""
复习管理 API 路由（艾宾浩斯遗忘曲线）
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Word, ReviewRecord
from app.schemas import ReviewSubmit
from app.services.review_service import review_service

router = APIRouter(prefix="/api/review", tags=["复习管理"])


@router.get("/today")
async def get_today_review(db: AsyncSession = Depends(get_db)):
    """获取今日待复习列表"""
    records = await review_service.get_today_reviews(db)
    count = await review_service.get_review_count(db)

    items = []
    for r in records:
        word_result = await db.execute(select(Word).where(Word.id == r.word_id))
        word = word_result.scalar_one_or_none()
        items.append({
            "id": r.id,
            "word_id": r.word_id,
            "word": r.word,
            "stage": r.stage,
            "next_review_date": r.next_review_date.isoformat() if r.next_review_date else None,
            "meaning": word.meaning if word else "",
            "example": word.example if word else "",
            "pinyin": word.pinyin if word else "",
        })

    return {"total": count, "items": items}


@router.post("/submit")
async def submit_review(
    data: ReviewSubmit,
    db: AsyncSession = Depends(get_db),
):
    """提交复习结果"""
    record = await review_service.submit_review(
        word_id=data.word_id,
        is_correct=data.is_correct,
        db=db,
    )

    # 记录学习历史
    from app.models import StudyHistory
    from datetime import datetime

    history = StudyHistory(
        word_id=data.word_id,
        word=record.word,
        action="review",
        score=100 if data.is_correct else 0,
    )
    db.add(history)

    # 更新词表的复习计数
    word_result = await db.execute(select(Word).where(Word.id == data.word_id))
    word = word_result.scalar_one_or_none()
    if word:
        word.review_count += 1
        if not data.is_correct:
            word.error_count += 1
        from datetime import datetime
        word.last_reviewed_at = datetime.now()

    await db.flush()

    return {
        "message": "复习记录已更新",
        "word_id": data.word_id,
        "is_correct": data.is_correct,
        "stage": record.stage,
        "next_review_date": record.next_review_date.isoformat() if record.next_review_date else None,
        "is_completed": record.is_completed,
    }


@router.get("/stats")
async def get_review_stats(db: AsyncSession = Depends(get_db)):
    """获取复习统计数据"""
    from datetime import date, timedelta
    from sqlalchemy import and_

    today = date.today()
    week_later = today + timedelta(days=7)

    # 今日待复习
    today_count = await review_service.get_review_count(db)

    # 本周待复习
    from app.models import ReviewRecord
    result = await db.execute(
        select(ReviewRecord)
        .where(
            and_(
                ReviewRecord.next_review_date <= week_later,
                ReviewRecord.next_review_date >= today,
                ReviewRecord.is_completed == False,
            )
        )
    )
    week_count = len(list(result.scalars().all()))

    # 已完成复习
    result = await db.execute(
        select(ReviewRecord).where(ReviewRecord.is_completed == True)
    )
    completed_count = len(list(result.scalars().all()))

    return {
        "today_review": today_count,
        "week_review": week_count,
        "completed": completed_count,
        "total_reviews": today_count + completed_count,
    }
