"""
AI 对话 API 路由
支持流式输出
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models import ChatMessage, Word as WordModel
from app.schemas import ChatRequest, ChatHistoryResponse
from app.services.ai_service import ai_service
from app.services.review_service import review_service

router = APIRouter(prefix="/api/chat", tags=["AI对话"])


def _set_word_field(word, section: str, text: str):
    """根据章节名设置词语字段"""
    mapping = {
        "拼音": "pinyin",
        "释义": "meaning",
        "出处": "source",
        "用法": "usage",
        "例句": "example",
        "近义词": "synonym",
        "反义词": "antonym",
        "易混词": "confusable",
        "记忆技巧": "memory_tip",
    }
    field = mapping.get(section)
    if field and text:
        setattr(word, field, text)


async def _parse_and_save_word(word: str, ai_content: str, db: AsyncSession):
    """解析 AI 回复中的成语信息并保存到词库"""
    try:
        result = await db.execute(
            select(WordModel).where(WordModel.word == word)
        )
        existing = result.scalar_one_or_none()

        if not existing:
            new_word = WordModel(word=word)
            lines = ai_content.split("\n")
            current_section = ""
            section_content = []

            for line in lines:
                line = line.strip()
                if line.startswith("## "):
                    if current_section and section_content:
                        text = "\n".join(section_content).strip()
                        _set_word_field(new_word, current_section, text)
                    current_section = line.replace("## ", "").strip()
                    section_content = []
                else:
                    section_content.append(line)

            if current_section and section_content:
                text = "\n".join(section_content).strip()
                _set_word_field(new_word, current_section, text)

            db.add(new_word)
            await db.flush()
            await review_service.auto_schedule(new_word.id, new_word.word, db)
    except Exception:
        pass  # 解析失败不影响聊天


async def _stream_chat(message: str, db: AsyncSession, word_id: int = None):
    """流式聊天 - 发送事件流"""
    full_content = ""
    async for chunk in ai_service.chat(
        message=message,
        db=db,
        stream=True,
    ):
        full_content += chunk
        yield f"data: {json.dumps({'content': chunk})}\n\n"

    # 流结束后保存完整的 AI 回复
    if full_content:
        assistant_msg = ChatMessage(
            role="assistant",
            content=full_content,
            word_id=word_id,
        )
        db.add(assistant_msg)
        await db.commit()

    yield f"data: {json.dumps({'content': '[DONE]', 'done': True})}\n\n"


async def _stream_explain(word: str, db: AsyncSession):
    """流式解释成语"""
    import json
    full_content = ""
    async for chunk in ai_service.explain_idiom(
        word=word,
        db=db,
        stream=True,
    ):
        full_content += chunk
        yield f"data: {json.dumps({'content': chunk})}\n\n"

    # 尝试自动加入词库
    if full_content:
        await _parse_and_save_word(word, full_content, db)

    # 保存 AI 回复
    if full_content:
        assistant_msg = ChatMessage(
            role="assistant",
            content=full_content,
        )
        db.add(assistant_msg)
        await db.commit()

    yield f"data: {json.dumps({'content': '[DONE]', 'done': True})}\n\n"


@router.post("")
async def chat(request: ChatRequest, db: AsyncSession = Depends(get_db)):
    """AI 对话接口（支持流式）"""
    # 保存用户消息
    user_msg = ChatMessage(
        role="user",
        content=request.message,
        word_id=request.word_id,
    )
    db.add(user_msg)
    await db.flush()

    if request.stream:
        return StreamingResponse(
            _stream_chat(request.message, db, request.word_id),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )
    else:
        # 非流式 - 收集完整回复
        full_response = ""
        async for chunk in ai_service.chat(
            message=request.message,
            db=db,
            stream=False,
        ):
            full_response += chunk

        # 保存 AI 回复
        assistant_msg = ChatMessage(
            role="assistant",
            content=full_response,
            word_id=request.word_id,
        )
        db.add(assistant_msg)
        await db.flush()

        return {
            "id": assistant_msg.id,
            "role": "assistant",
            "content": full_response,
            "created_at": assistant_msg.created_at.isoformat() if assistant_msg.created_at else None,
        }


@router.post("/explain")
async def explain_idiom(
    request: ChatRequest,
    db: AsyncSession = Depends(get_db),
):
    """解释成语 - 流式返回详细解释"""
    word = request.message.strip()
    # 保存用户查询
    user_msg = ChatMessage(
        role="user",
        content=f"请解释成语：{word}",
    )
    db.add(user_msg)
    await db.flush()

    return StreamingResponse(
        _stream_explain(word, db),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/history", response_model=ChatHistoryResponse)
async def get_chat_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """获取聊天历史"""
    count_result = await db.execute(select(func.count(ChatMessage.id)))
    total = count_result.scalar() or 0

    result = await db.execute(
        select(ChatMessage)
        .order_by(ChatMessage.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    messages = list(result.scalars().all())

    return ChatHistoryResponse(
        total=total,
        page=page,
        page_size=page_size,
        messages=[
            {
                "id": m.id,
                "role": m.role,
                "content": m.content,
                "created_at": m.created_at.isoformat() if m.created_at else None,
            }
            for m in reversed(messages)
        ],
    )


@router.delete("/history")
async def clear_chat_history(db: AsyncSession = Depends(get_db)):
    """清空聊天历史"""
    result = await db.execute(select(ChatMessage))
    messages = list(result.scalars().all())
    for m in messages:
        await db.delete(m)
    return {"message": "聊天历史已清空"}
