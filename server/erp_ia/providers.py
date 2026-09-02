from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol


@dataclass(frozen=True)
class ProviderResult:
    text: str
    input_tokens: int = 0
    output_tokens: int = 0
    latency_ms: int = 0
    model: str = ""


class AIProvider(Protocol):
    name: str
    def answer(self, question: str, context: str) -> ProviderResult: ...


class DisabledProvider:
    name = "disabled"

    def answer(self, question: str, context: str) -> ProviderResult:
        raise RuntimeError("Provider de IA não configurado no servidor.")


class OpenAIResponsesProvider:
    name = "openai"

    def __init__(self, api_key: str, model: str, system_prompt_path: Path):
        if not api_key:
            raise ValueError("OPENAI_API_KEY não configurada no servidor.")
        self.api_key = api_key
        self.model = model
        self.instructions = system_prompt_path.read_text(encoding="utf-8")

    def answer(self, question: str, context: str) -> ProviderResult:
        payload = {
            "model": self.model,
            "store": False,
            "instructions": self.instructions,
            "input": (
                "Responda somente com base nas evidências abaixo. Se elas não sustentarem "
                "a resposta, declare conhecimento insuficiente.\n\nEVIDÊNCIAS:\n" +
                context + "\n\nPERGUNTA:\n" + question
            ),
        }
        request = urllib.request.Request(
            "https://api.openai.com/v1/responses",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Authorization": "Bearer " + self.api_key, "Content-Type": "application/json"},
            method="POST",
        )
        started = time.monotonic()
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                data = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:1000]
            raise RuntimeError(f"Falha do provider ({exc.code}): {detail}") from exc
        text_parts: list[str] = []
        for item in data.get("output", []):
            if item.get("type") == "message":
                for content in item.get("content", []):
                    if content.get("type") == "output_text":
                        text_parts.append(content.get("text", ""))
        usage = data.get("usage") or {}
        return ProviderResult(
            text="\n".join(text_parts).strip(),
            input_tokens=int(usage.get("input_tokens", 0)),
            output_tokens=int(usage.get("output_tokens", 0)),
            latency_ms=int((time.monotonic() - started) * 1000),
            model=data.get("model", self.model),
        )
