"""
Pydantic 数据验证模式（请求/响应）
"""
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field


# ===== Word =====
class WordCreate(BaseModel):
    word: str = Field(..., min_length=1, max_length=50, description="成语")
    pinyin: str = ""
    meaning: str = ""
    source: str = ""
    usage: str = ""
    example: str = ""
    synonym: str = ""
    antonym: str = ""
    confusable: str = ""
    memory_tip: str = ""
    tags: str = ""
    notes: str = ""


class WordUpdate(BaseModel):
    word: Optional[str] = None
    pinyin: Optional[str] = None
    meaning: Optional[str] = None
    source: Optional[str] = None
    usage: Optional[str] = None
    example: Optional[str] = None
    synonym: Optional[str] = None
    antonym: Optional[str] = None
    confusable: Optional[str] = None
    memory_tip: Optional[str] = None
    tags: Optional[str] = None
    is_mastered: Optional[bool] = None
    notes: Optional[str] = None
    is_favorite: Optional[bool] = None


class WordResponse(BaseModel):
    id: int
    word: str
    pinyin: str = ""
    meaning: str = ""
    source: str = ""
    usage: str = ""
    example: str = ""
    synonym: str = ""
    antonym: str = ""
    confusable: str = ""
    memory_tip: str = ""
    tags: List[str] = []
    is_mastered: bool = False
    review_count: int = 0
    error_count: int = 0
    is_favorite: bool = False
    notes: str = ""
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    last_reviewed_at: Optional[str] = None

    class Config:
        from_attributes = True


class WordListResponse(BaseModel):
    total: int
    page: int
    page_size: int
    words: List[WordResponse]


# ===== Study =====
class StudyRecord(BaseModel):
    word: str = Field(..., description="学习的词语")


class StudyResponse(BaseModel):
    word_id: int
    word: str
    pinyin: str
    meaning: str
    source: str
    usage: str
    example: str
    synonym: str
    antonym: str
    confusable: str
    memory_tip: str


# ===== Chat =====
class ChatRequest(BaseModel):
    message: str = Field(..., description="用户消息")
    word_id: Optional[int] = None
    stream: bool = True


class ChatResponse(BaseModel):
    id: int
    role: str
    content: str
    created_at: str


class ChatHistoryResponse(BaseModel):
    total: int
    page: int
    page_size: int
    messages: List[ChatResponse]


# ===== Quiz =====
class QuizRequest(BaseModel):
    count: int = Field(5, ge=5, le=20, description="题目数量")


class QuizQuestion(BaseModel):
    id: int
    word: str
    # 显示词语，用户回答释义


class QuizAnswer(BaseModel):
    question_id: int
    word: str
    user_answer: str
    correct_answer: str
    is_correct: bool


class QuizResult(BaseModel):
    total: int
    correct: int
    wrong: int
    accuracy: float
    answers: List[QuizAnswer]


# ===== Review =====
class ReviewItem(BaseModel):
    id: int
    word_id: int
    word: str
    stage: int
    next_review_date: str
    meaning: str
    example: str


class ReviewResponse(BaseModel):
    total: int
    items: List[ReviewItem]


class ReviewSubmit(BaseModel):
    word_id: int
    is_correct: bool


# ===== Stats =====
class StatsOverview(BaseModel):
    total_words: int
    today_learned: int
    today_new: int
    mastered: int
    favorite_count: int
    accuracy: float
    total_reviews: int


class DailyStats(BaseModel):
    date: str
    count: int
    mastered: int


class StatsResponse(BaseModel):
    overview: StatsOverview
    daily_stats: List[DailyStats]


# ===== Export =====
class ExportRequest(BaseModel):
    format: str = Field(..., pattern="^(csv|excel|markdown|json)$")
    word_ids: Optional[List[int]] = None


# ===== Import =====
class ImportRequest(BaseModel):
    data: List[dict]


class ImportResult(BaseModel):
    total: int
    success: int
    failed: int
    errors: List[str]


# ===== Settings =====
class SettingUpdate(BaseModel):
    key: str
    value: str


class AIConfig(BaseModel):
    engine: str = "ollama"
    base_url: str = "http://localhost:11434"
    model: str = "qwen2.5:7b"


class AIConfigUpdate(BaseModel):
    engine: Optional[str] = None
    base_url: Optional[str] = None
    model: Optional[str] = None


# ===== Prompt =====
class PromptCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    content: str = Field(..., min_length=1)


class PromptUpdate(BaseModel):
    name: Optional[str] = None
    content: Optional[str] = None
    is_active: Optional[bool] = None


class PromptResponse(BaseModel):
    id: int
    name: str
    content: str
    is_default: bool
    is_active: bool
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


# ===== Search =====
class SearchRequest(BaseModel):
    keyword: str = Field(..., min_length=1, description="搜索关键词")
    search_type: str = Field("keyword", pattern="^(keyword|pinyin|fuzzy)$")
    tag: Optional[str] = None
    favorite_only: bool = False
    page: int = 1
    page_size: int = 20


# ===== Tag =====
class TagCount(BaseModel):
    tag: str
    count: int
