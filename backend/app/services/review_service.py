"""
复习服务 - 基于艾宾浩斯遗忘曲线
计算每天的复习计划
"""
from datetime import date, timedelta
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models import ReviewRecord, Word
from app.config import settings


class ReviewService:
    """复习计划服务"""

    INTERVALS = settings.REVIEW_INTERVALS_DAY  # [1, 2, 4, 7, 15, 30]

    async def get_today_reviews(self, db: AsyncSession) -> List[ReviewRecord]:
        """获取今天需要复习的所有词语"""
        today = date.today()
        result = await db.execute(
            select(ReviewRecord)
            .where(
                and_(
                    ReviewRecord.next_review_date <= today,
                    ReviewRecord.is_completed == False,
                )
            )
            .order_by(ReviewRecord.next_review_date)
        )
        return list(result.scalars().all())

    async def get_review_count(self, db: AsyncSession) -> int:
        """获取今天需要复习的数量"""
        today = date.today()
        result = await db.execute(
            select(ReviewRecord)
            .where(
                and_(
                    ReviewRecord.next_review_date <= today,
                    ReviewRecord.is_completed == False,
                )
            )
        )
        return len(list(result.scalars().all()))

    async def submit_review(
        self, word_id: int, is_correct: bool, db: AsyncSession
    ) -> ReviewRecord:
        """提交复习结果，更新复习阶段"""
        result = await db.execute(
            select(ReviewRecord).where(
                and_(
                    ReviewRecord.word_id == word_id,
                    ReviewRecord.is_completed == False,
                )
            )
        )
        record = result.scalar_one_or_none()

        if record is None:
            # 创建新的复习记录
            record = ReviewRecord(
                word_id=word_id,
                word="",  # 稍后更新
                stage=0,
                next_review_date=date.today(),
                is_completed=False,
                correct_count=0,
                wrong_count=0,
            )
            db.add(record)

        # 获取词语名称
        word_result = await db.execute(select(Word).where(Word.id == word_id))
        word = word_result.scalar_one_or_none()
        if word:
            record.word = word.word

        if is_correct:
            record.correct_count += 1
            # 正确则进入下一阶段
            if record.stage < len(self.INTERVALS) - 1:
                record.stage += 1
                interval = self.INTERVALS[record.stage]
                record.next_review_date = date.today() + timedelta(days=interval)
            else:
                # 已完成所有阶段
                record.is_completed = True
                if word:
                    word.is_mastered = True
        else:
            record.wrong_count += 1
            # 错误则重置到第一阶段
            record.stage = 0
            record.next_review_date = date.today() + timedelta(days=1)

        await db.flush()
        return record

    async def auto_schedule(self, word_id: int, word_name: str, db: AsyncSession):
        """学习新词时自动创建复习计划"""
        # 检查是否已有记录
        result = await db.execute(
            select(ReviewRecord).where(ReviewRecord.word_id == word_id)
        )
        existing = result.scalar_one_or_none()
        if existing:
            return existing

        record = ReviewRecord(
            word_id=word_id,
            word=word_name,
            stage=0,
            next_review_date=date.today() + timedelta(days=1),
            is_completed=False,
        )
        db.add(record)
        await db.flush()
        return record


review_service = ReviewService()
