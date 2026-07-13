"""
SQLAlchemy ORM 模型定义
包含所有数据表的结构
"""
from datetime import datetime, date
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Date, Boolean, Float, JSON, Index
)
from app.database import Base


class Word(Base):
    """成语词库表"""
    __tablename__ = "words"

    id = Column(Integer, primary_key=True, autoincrement=True)
    word = Column(String(50), nullable=False, index=True, comment="成语词语")
    pinyin = Column(String(200), default="", comment="拼音")
    meaning = Column(Text, default="", comment="释义")
    source = Column(String(500), default="", comment="出处")
    usage = Column(Text, default="", comment="用法")
    example = Column(Text, default="", comment="例句")
    synonym = Column(String(500), default="", comment="近义词")
    antonym = Column(String(500), default="", comment="反义词")
    confusable = Column(String(500), default="", comment="易混词")
    memory_tip = Column(Text, default="", comment="记忆技巧")
    tags = Column(String(200), default="", comment="标签，逗号分隔：高频,低频,申论,行测,易错")
    is_mastered = Column(Boolean, default=False, comment="是否掌握")
    review_count = Column(Integer, default=0, comment="复习次数")
    error_count = Column(Integer, default=0, comment="错误次数")
    is_favorite = Column(Boolean, default=False, comment="是否收藏")
    notes = Column(Text, default="", comment="用户备注")
    created_at = Column(DateTime, default=datetime.now, comment="创建时间")
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, comment="更新时间")
    last_reviewed_at = Column(DateTime, nullable=True, comment="最后复习时间")

    __table_args__ = (
        Index("idx_word_word_pinyin", "word", "pinyin"),
        Index("idx_word_tags", "tags"),
        Index("idx_word_mastered", "is_mastered"),
        Index("idx_word_favorite", "is_favorite"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "word": self.word,
            "pinyin": self.pinyin,
            "meaning": self.meaning,
            "source": self.source,
            "usage": self.usage,
            "example": self.example,
            "synonym": self.synonym,
            "antonym": self.antonym,
            "confusable": self.confusable,
            "memory_tip": self.memory_tip,
            "tags": self.tags.split(",") if self.tags else [],
            "is_mastered": self.is_mastered,
            "review_count": self.review_count,
            "error_count": self.error_count,
            "is_favorite": self.is_favorite,
            "notes": self.notes,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "last_reviewed_at": self.last_reviewed_at.isoformat() if self.last_reviewed_at else None,
        }


class StudyHistory(Base):
    """学习历史记录表"""
    __tablename__ = "study_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    word_id = Column(Integer, nullable=False, index=True, comment="词语ID")
    word = Column(String(50), nullable=False, comment="词语")
    action = Column(String(20), nullable=False, comment="操作类型: learn/review/quiz/error")
    score = Column(Integer, default=0, comment="得分(0-100)")
    detail = Column(Text, default="", comment="详情JSON")
    created_at = Column(DateTime, default=datetime.now, comment="学习时间")

    __table_args__ = (
        Index("idx_history_word_id", "word_id"),
        Index("idx_history_action", "action"),
        Index("idx_history_created", "created_at"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "word_id": self.word_id,
            "word": self.word,
            "action": self.action,
            "score": self.score,
            "detail": self.detail,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class ReviewRecord(Base):
    """复习记录表（艾宾浩斯遗忘曲线）"""
    __tablename__ = "review_records"

    id = Column(Integer, primary_key=True, autoincrement=True)
    word_id = Column(Integer, nullable=False, index=True, comment="词语ID")
    word = Column(String(50), nullable=False, comment="词语")
    stage = Column(Integer, default=0, comment="复习阶段(0-5)")
    next_review_date = Column(Date, nullable=False, comment="下次复习日期")
    is_completed = Column(Boolean, default=False, comment="是否已完成本轮复习")
    correct_count = Column(Integer, default=0, comment="正确次数")
    wrong_count = Column(Integer, default=0, comment="错误次数")
    created_at = Column(DateTime, default=datetime.now, comment="创建时间")
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, comment="更新时间")

    __table_args__ = (
        Index("idx_review_date", "next_review_date"),
        Index("idx_review_word", "word_id"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "word_id": self.word_id,
            "word": self.word,
            "stage": self.stage,
            "next_review_date": self.next_review_date.isoformat() if self.next_review_date else None,
            "is_completed": self.is_completed,
            "correct_count": self.correct_count,
            "wrong_count": self.wrong_count,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Favorite(Base):
    """收藏表"""
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, autoincrement=True)
    word_id = Column(Integer, nullable=False, index=True, unique=True, comment="词语ID")
    word = Column(String(50), nullable=False, comment="词语")
    created_at = Column(DateTime, default=datetime.now, comment="收藏时间")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "word_id": self.word_id,
            "word": self.word,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class ChatMessage(Base):
    """AI对话消息表"""
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, autoincrement=True)
    role = Column(String(20), nullable=False, comment="角色: user/assistant/system")
    content = Column(Text, nullable=False, comment="消息内容")
    word_id = Column(Integer, nullable=True, index=True, comment="关联词语ID")
    is_streaming = Column(Boolean, default=False, comment="是否流式输出")
    tokens = Column(Integer, default=0, comment="Token数量")
    created_at = Column(DateTime, default=datetime.now, comment="发送时间")

    __table_args__ = (
        Index("idx_chat_created", "created_at"),
        Index("idx_chat_role", "role"),
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "role": self.role,
            "content": self.content,
            "word_id": self.word_id,
            "is_streaming": self.is_streaming,
            "tokens": self.tokens,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class AppSetting(Base):
    """应用设置表"""
    __tablename__ = "settings"

    id = Column(Integer, primary_key=True, autoincrement=True)
    key = Column(String(100), nullable=False, unique=True, index=True, comment="设置键")
    value = Column(Text, default="", comment="设置值")
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, comment="更新时间")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "key": self.key,
            "value": self.value,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class PromptTemplate(Base):
    """System Prompt 模板表"""
    __tablename__ = "prompt_templates"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True, comment="模板名称")
    content = Column(Text, nullable=False, comment="Prompt内容")
    is_default = Column(Boolean, default=False, comment="是否为默认模板")
    is_active = Column(Boolean, default=False, comment="是否当前激活")
    created_at = Column(DateTime, default=datetime.now, comment="创建时间")
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now, comment="更新时间")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "content": self.content,
            "is_default": self.is_default,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
