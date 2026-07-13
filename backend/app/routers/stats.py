"""
数据统计 API 路由
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services.stats_service import stats_service

router = APIRouter(prefix="/api/stats", tags=["数据统计"])


@router.get("/overview")
async def get_overview(db: AsyncSession = Depends(get_db)):
    """获取学习概览统计"""
    overview = await stats_service.get_overview(db)
    return overview


@router.get("/daily")
async def get_daily_stats(
    days: int = Query(30, ge=7, le=365),
    db: AsyncSession = Depends(get_db),
):
    """获取每日学习统计"""
    stats = await stats_service.get_daily_stats(db, days)
    return stats


@router.get("/tags")
async def get_tag_distribution(db: AsyncSession = Depends(get_db)):
    """获取标签分布"""
    tags = await stats_service.get_tag_distribution(db)
    return tags


@router.get("/calendar")
async def get_calendar(
    year: int = Query(..., ge=2020, le=2030),
    month: int = Query(..., ge=1, le=12),
    db: AsyncSession = Depends(get_db),
):
    """获取学习日历"""
    calendar = await stats_service.get_learning_calendar(db, year, month)
    return calendar
