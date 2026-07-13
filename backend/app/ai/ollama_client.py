"""
Ollama API 客户端
通过 HTTP 请求调用本地 Ollama 服务
"""
import json
import httpx
from typing import AsyncGenerator, Optional
from app.config import settings


class OllamaClient:
    """Ollama 本地大模型调用客户端"""

    def __init__(self, base_url: str = None, model: str = None):
        self.base_url = base_url or settings.OLLAMA_BASE_URL
        self.model = model or settings.OLLAMA_MODEL
        self.generate_url = f"{self.base_url}/api/generate"
        self.chat_url = f"{self.base_url}/api/chat"

    async def generate(
        self,
        prompt: str,
        system_prompt: str = None,
        stream: bool = False,
        temperature: float = 0.7,
        max_tokens: int = 2048,
    ) -> AsyncGenerator[str, None]:
        """
        调用 Ollama 生成回复（流式或非流式）
        """
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": stream,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            }
        }
        if system_prompt:
            payload["system"] = system_prompt

        async with httpx.AsyncClient(timeout=300.0) as client:
            if stream:
                async with client.stream("POST", self.generate_url, json=payload) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if line.strip():
                            try:
                                data = json.loads(line)
                                if "response" in data:
                                    yield data["response"]
                                if data.get("done", False):
                                    break
                            except json.JSONDecodeError:
                                continue
            else:
                response = await client.post(self.generate_url, json=payload)
                response.raise_for_status()
                data = response.json()
                yield data.get("response", "")

    async def chat(
        self,
        messages: list,
        system_prompt: str = None,
        stream: bool = False,
        temperature: float = 0.7,
        max_tokens: int = 2048,
    ) -> AsyncGenerator[str, None]:
        """
        调用 Ollama 聊天接口（流式或非流式）
        messages: [{"role": "user"/"assistant", "content": "..."}]
        """
        ollama_messages = []
        if system_prompt:
            ollama_messages.append({"role": "system", "content": system_prompt})
        ollama_messages.extend(messages)

        payload = {
            "model": self.model,
            "messages": ollama_messages,
            "stream": stream,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            }
        }

        async with httpx.AsyncClient(timeout=300.0) as client:
            if stream:
                async with client.stream("POST", self.chat_url, json=payload) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if line.strip():
                            try:
                                data = json.loads(line)
                                if "message" in data and "content" in data["message"]:
                                    yield data["message"]["content"]
                                if data.get("done", False):
                                    break
                            except json.JSONDecodeError:
                                continue
            else:
                response = await client.post(self.chat_url, json=payload)
                response.raise_for_status()
                data = response.json()
                if "message" in data and "content" in data["message"]:
                    yield data["message"]["content"]

    async def list_models(self) -> list:
        """获取 Ollama 可用模型列表"""
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(f"{self.base_url}/api/tags")
                response.raise_for_status()
                data = response.json()
                return [m["name"] for m in data.get("models", [])]
            except Exception as e:
                return [f"无法获取模型列表: {str(e)}"]

    async def check_health(self) -> bool:
        """检查 Ollama 服务是否可用"""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{self.base_url}/api/tags")
                return response.status_code == 200
        except Exception:
            return False


class LlamaCppClient:
    """llama.cpp HTTP Server 客户端"""

    def __init__(self, api_url: str = None, model: str = None):
        self.api_url = api_url or settings.LLAMACPP_API_URL
        self.model = model or settings.LLAMACPP_MODEL
        self.completion_url = f"{self.api_url}/completion"

    async def generate(
        self,
        prompt: str,
        system_prompt: str = None,
        stream: bool = False,
        temperature: float = 0.7,
        max_tokens: int = 2048,
    ) -> AsyncGenerator[str, None]:
        """
        调用 llama.cpp 生成回复
        """
        full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

        payload = {
            "prompt": full_prompt,
            "stream": stream,
            "temperature": temperature,
            "n_predict": max_tokens,
        }

        async with httpx.AsyncClient(timeout=300.0) as client:
            if stream:
                async with client.stream("POST", self.completion_url, json=payload) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if line.startswith("data: "):
                            try:
                                data = json.loads(line[6:])
                                if "content" in data:
                                    yield data["content"]
                                if data.get("stop", False):
                                    break
                            except json.JSONDecodeError:
                                continue
            else:
                response = await client.post(self.completion_url, json=payload)
                response.raise_for_status()
                data = response.json()
                yield data.get("content", "")

    async def check_health(self) -> bool:
        """检查 llama.cpp 服务是否可用"""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{self.api_url}/health")
                return response.status_code == 200
        except Exception:
            return False
