"""
AI 服务层
统一管理 Ollama 和 llama.cpp 的调用
处理成语查询、对话等功能
"""
import json
from typing import AsyncGenerator, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.ai.ollama_client import OllamaClient, LlamaCppClient
from app.models import AppSetting, PromptTemplate, Word
from app.config import settings


class AIService:
    """AI 服务 - 统一接口"""

    def __init__(self):
        self._ollama_client: Optional[OllamaClient] = None
        self._llamacpp_client: Optional[LlamaCppClient] = None
        self._current_engine: str = settings.AI_ENGINE
        self._current_model: str = ""
        self._current_base_url: str = ""

    async def _load_config(self, db: AsyncSession = None):
        """从数据库加载 AI 配置"""
        if db:
            try:
                for key in ["ai_engine", "ai_base_url", "ai_model"]:
                    result = await db.execute(
                        select(AppSetting).where(AppSetting.key == key)
                    )
                    setting = result.scalar_one_or_none()
                    if setting:
                        if key == "ai_engine":
                            self._current_engine = setting.value
                        elif key == "ai_base_url":
                            self._current_base_url = setting.value
                        elif key == "ai_model":
                            self._current_model = setting.value
            except Exception:
                pass

        if not self._current_base_url:
            self._current_base_url = settings.OLLAMA_BASE_URL
        if not self._current_model:
            self._current_model = settings.OLLAMA_MODEL

    def _get_client(self):
        """获取当前配置的 AI 客户端"""
        if self._current_engine == "llamacpp":
            if not self._llamacpp_client:
                self._llamacpp_client = LlamaCppClient(
                    api_url=self._current_base_url,
                    model=self._current_model,
                )
            return self._llamacpp_client
        else:
            if not self._ollama_client:
                self._ollama_client = OllamaClient(
                    base_url=self._current_base_url,
                    model=self._current_model,
                )
            return self._ollama_client

    async def get_active_prompt(self, db: AsyncSession) -> str:
        """获取当前激活的系统 Prompt"""
        result = await db.execute(
            select(PromptTemplate).where(PromptTemplate.is_active == True)
        )
        prompt = result.scalar_one_or_none()
        if prompt:
            return prompt.content
        # 检查 settings 表
        result = await db.execute(
            select(AppSetting).where(AppSetting.key == "system_prompt")
        )
        setting = result.scalar_one_or_none()
        if setting:
            return setting.value
        return settings.SYSTEM_PROMPT

    async def chat(
        self,
        message: str,
        db: AsyncSession,
        system_prompt: str = None,
        stream: bool = False,
    ) -> AsyncGenerator[str, None]:
        """AI 对话"""
        await self._load_config(db)

        if not system_prompt:
            system_prompt = await self.get_active_prompt(db)

        client = self._get_client()
        messages = [{"role": "user", "content": message}]

        async for chunk in client.chat(
            messages=messages,
            system_prompt=system_prompt,
            stream=stream,
        ):
            yield chunk

    async def explain_idiom(
        self,
        word: str,
        db: AsyncSession,
        stream: bool = False,
    ) -> AsyncGenerator[str, None]:
        """解释成语 - 返回拼音、释义、出处、用法等"""
        await self._load_config(db)

        system_prompt = await self.get_active_prompt(db)
        user_prompt = f"""请详细解释成语「{word}」，按以下格式回复：

## 拼音
[填写拼音]

## 释义
[填写释义]

## 出处
[填写出处]

## 用法
[填写用法说明]

## 例句
[填写例句]

## 近义词
[填写近义词]

## 反义词
[填写反义词]

## 易混词
[填写易混词辨析]

## 记忆技巧
[填写记忆技巧]

## 考公应用
[说明该成语在申论或行测中的常见用法]
"""

        client = self._get_client()
        async for chunk in client.generate(
            prompt=user_prompt,
            system_prompt=system_prompt,
            stream=stream,
        ):
            yield chunk

    async def check_health(self) -> dict:
        """检查 AI 服务健康状态"""
        ollama_ok = await OllamaClient(
            base_url=settings.OLLAMA_BASE_URL
        ).check_health()
        llamacpp_ok = await LlamaCppClient(
            api_url=settings.LLAMACPP_API_URL
        ).check_health()

        ollama_models = []
        if ollama_ok:
            client = OllamaClient(base_url=settings.OLLAMA_BASE_URL)
            ollama_models = await client.list_models()

        return {
            "ollama": {"available": ollama_ok, "models": ollama_models},
            "llamacpp": {"available": llamacpp_ok},
            "current_engine": self._current_engine,
        }

    async def list_available_models(self, engine: str = None) -> list:
        """获取可用模型列表"""
        engine = engine or self._current_engine
        if engine == "ollama":
            client = OllamaClient(base_url=self._current_base_url or settings.OLLAMA_BASE_URL)
            return await client.list_models()
        return ["llama.cpp 模型需在配置中指定路径"]


# 全局 AI 服务实例
ai_service = AIService()
