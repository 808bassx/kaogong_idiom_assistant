"""
数据统计服务
提供学习统计、图表数据等
"""
from datetime import datetime, date, timedelta
from typing import List, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, cast, Date

from app.models import Word, StudyHistory, ReviewRecord


class StatsService:
    """学习统计服务"""

    async def get_overview(self, db: AsyncSession) -> dict:
        """获取概览统计"""
        today = date.today()
        today_start = datetime.combine(today, datetime.min.time())
        week_start = today - timedelta(days=today.weekday())
        month_start = date(today.year, today.month, 1)

        # 总词数
        total_result = await db.execute(select(func.count(Word.id)))
        total_words = total_result.scalar() or 0

        # 今日学习
        today_result = await db.execute(
            select(func.count(StudyHistory.id))
            .where(
                and_(
                    StudyHistory.created_at >= today_start,
                    StudyHistory.action.in_(["learn", "review"]),
                )
            )
        )
        today_learned = today_result.scalar() or 0

        # 今日新增
        today_new_result = await db.execute(
            select(func.count(Word.id))
            .where(cast(Word.created_at, Date) == today)
        )
        today_new = today_new_result.scalar() or 0

        # 已掌握
        mastered_result = await db.execute(
            select(func.count(Word.id)).where(Word.is_mastered == True)
        )
        mastered = mastered_result.scalar() or 0

        # 收藏数
        fav_result = await db.execute(
            select(func.count(Word.id)).where(Word.is_favorite == True)
        )
        favorite_count = fav_result.scalar() or 0

        # 总复习次数
        review_result = await db.execute(
            select(func.coalesce(func.sum(Word.review_count), 0))
        )
        total_reviews = review_result.scalar() or 0

        # 正确率 (用最近100次学习记录)
        recent_result = await db.execute(
            select(StudyHistory)
            .where(StudyHistory.action == "quiz")
            .order_by(StudyHistory.created_at.desc())
            .limit(100)
        )
        recent_records = list(recent_result.scalars().all())
        if recent_records:
            scores = [r.score for r in recent_records if r.score is not None]
            accuracy = sum(scores) / len(scores) if scores else 0
        else:
            accuracy = 0

        # 本周学习
        week_start_dt = datetime.combine(week_start, datetime.min.time())
        week_result = await db.execute(
            select(func.count(StudyHistory.id))
            .where(
                and_(
                    StudyHistory.created_at >= week_start_dt,
                    StudyHistory.action.in_(["learn", "review"]),
                )
            )
        )
        week_learned = week_result.scalar() or 0

        # 本月学习
        month_start_dt = datetime.combine(month_start, datetime.min.time())
        month_result = await db.execute(
            select(func.count(StudyHistory.id))
            .where(
                and_(
                    StudyHistory.created_at >= month_start_dt,
                    StudyHistory.action.in_(["learn", "review"]),
                )
            )
        )
        month_learned = month_result.scalar() or 0

        return {
            "total_words": total_words,
            "today_learned": today_learned,
            "today_new": today_new,
            "mastered": mastered,
            "favorite_count": favorite_count,
            "accuracy": round(accuracy, 2),
            "total_reviews": total_reviews,
            "week_learned": week_learned,
            "month_learned": month_learned,
        }

    async def get_daily_stats(self, db: AsyncSession, days: int = 30) -> List[dict]:
        """获取每日学习统计"""
        start_date = date.today() - timedelta(days=days)
        start_datetime = datetime.combine(start_date, datetime.min.time())

        # 按日期分组统计学习记录
        result = await db.execute(
            select(
                cast(StudyHistory.created_at, Date).label("study_date"),
                func.count(StudyHistory.id).label("count"),
            )
            .where(
                and_(
                    StudyHistory.created_at >= start_datetime,
                    StudyHistory.action.in_(["learn", "review"]),
                )
            )
            .group_by(cast(StudyHistory.created_at, Date))
            .order_by("study_date")
        )
        rows = result.all()

        # 填充所有日期
        stats_map = {}
        for row in rows:
            stats_map[row.study_date.isoformat()] = row.count

        daily_stats = []
        for i in range(days):
            d = (start_date + timedelta(days=i + 1)).isoformat()
            daily_stats.append({"date": d, "count": stats_map.get(d, 0)})

        return daily_stats

    async def get_tag_distribution(self, db: AsyncSession) -> List[dict]:
        """获取标签分布"""
        result = await db.execute(select(Word.tags, func.count(Word.id)))
        rows = result.all()

        tag_counts = {}
        for tags_str, count in rows:
            if tags_str:
                for tag in tags_str.split(","):
                    tag = tag.strip()
                    if tag:
                        tag_counts[tag] = tag_counts.get(tag, 0) + count

        return [{"tag": k, "count": v} for k, v in tag_counts.items()]

    async def get_learning_calendar(self, db: AsyncSession, year: int, month: int) -> dict:
        """获取学习日历数据"""
        start_date = date(year, month, 1)
        if month == 12:
            end_date = date(year + 1, 1, 1)
        else:
            end_date = date(year, month + 1, 1)

        start_dt = datetime.combine(start_date, datetime.min.time())
        end_dt = datetime.combine(end_date, datetime.min.time())

        result = await db.execute(
            select(
                cast(StudyHistory.created_at, Date).label("study_date"),
                func.count(StudyHistory.id).label("count"),
            )
            .where(
                and_(
                    StudyHistory.created_at >= start_dt,
                    StudyHistory.created_at < end_dt,
                    StudyHistory.action.in_(["learn", "review"]),
                )
            )
            .group_by(cast(StudyHistory.created_at, Date))
        )
        rows = result.all()

        calendar_data = {}
        for row in rows:
            calendar_data[row.study_date.isoformat()] = row.count

        return {
            "year": year,
            "month": month,
            "data": calendar_data,
        }


stats_service = StatsService()
