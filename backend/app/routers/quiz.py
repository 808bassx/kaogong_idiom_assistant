"""
抽查模式 API 路由
"""
import random
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models import Word, StudyHistory
from app.schemas import QuizRequest, QuizAnswer, QuizResult

router = APIRouter(prefix="/api/quiz", tags=["抽查模式"])


@router.post("/generate")
async def generate_quiz(
    data: QuizRequest,
    tag: str = Query(None, description="按标签筛选"),
    db: AsyncSession = Depends(get_db),
):
    """生成随机测验题目"""
    query = select(Word)
    if tag:
        query = query.where(Word.tags.contains(tag))

    result = await db.execute(query)
    all_words = list(result.scalars().all())

    if not all_words:
        raise HTTPException(status_code=404, detail="词库为空，请先学习成语")

    # 随机抽取
    count = min(data.count, len(all_words))
    selected = random.sample(all_words, count)

    questions = []
    for w in selected:
        questions.append({
            "id": w.id,
            "word": w.word,
            "pinyin": w.pinyin,
            "meaning": w.meaning,
            "example": w.example,
        })

    return {"questions": questions, "total": count}


@router.post("/submit")
async def submit_quiz(
    answers: list[dict],
    db: AsyncSession = Depends(get_db),
):
    """提交测验答案并评分"""
    if not answers:
        raise HTTPException(status_code=400, detail="答案列表为空")

    correct = 0
    wrong = 0
    results = []

    for ans in answers:
        word_id = ans.get("question_id", ans.get("id"))
        user_answer = ans.get("user_answer", "").strip()

        result = await db.execute(select(Word).where(Word.id == word_id))
        word = result.scalar_one_or_none()

        if not word:
            continue

        # 简单评分：根据用户回答与释义的相似度（关键词匹配）
        is_correct = _evaluate_answer(user_answer, word.meaning)
        if is_correct:
            correct += 1
        else:
            wrong += 1

        results.append(QuizAnswer(
            question_id=word.id,
            word=word.word,
            user_answer=user_answer,
            correct_answer=word.meaning,
            is_correct=is_correct,
        ))

        # 记录答题历史
        history = StudyHistory(
            word_id=word.id,
            word=word.word,
            action="quiz",
            score=100 if is_correct else 0,
        )
        db.add(history)

        # 更新错误计数
        if not is_correct:
            word.error_count += 1

    total = correct + wrong
    accuracy = round(correct / total * 100, 1) if total > 0 else 0

    await db.flush()

    return QuizResult(
        total=total,
        correct=correct,
        wrong=wrong,
        accuracy=accuracy,
        answers=results,
    )


def _evaluate_answer(user_answer: str, correct_meaning: str) -> bool:
    """
    评估用户答案是否正确
    使用关键词匹配策略
    """
    if not user_answer or not correct_meaning:
        return False

    user_answer = user_answer.lower()
    correct_meaning = correct_meaning.lower()

    # 提取关键词（取释义中的名词/动词关键词）
    import re
    # 简单的关键词提取：取2字以上的词
    keywords = re.findall(r'[一-鿿]{2,}', correct_meaning)

    if not keywords:
        # 如果没有中文关键词，比较长度和包含关系
        return user_answer in correct_meaning or correct_meaning in user_answer

    # 检查用户回答是否包含至少一个关键词
    hit_count = sum(1 for kw in keywords if kw in user_answer)
    # 至少命中30%的关键词才算正确
    threshold = max(1, len(keywords) // 3)
    return hit_count >= threshold


@router.get("/random")
async def get_random_word(db: AsyncSession = Depends(get_db)):
    """随机获取一个词语"""
    result = await db.execute(select(func.count(Word.id)))
    total = result.scalar() or 0
    if total == 0:
        raise HTTPException(status_code=404, detail="词库为空")

    offset = random.randint(0, total - 1)
    result = await db.execute(
        select(Word).offset(offset).limit(1)
    )
    word = result.scalar_one_or_none()
    if not word:
        raise HTTPException(status_code=404, detail="获取失败")

    return word.to_dict()
