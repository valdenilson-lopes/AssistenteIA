from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    database_path: Path
    host: str = "127.0.0.1"
    port: int = 8080
    api_bearer_token: str = ""
    provider: str = "disabled"
    openai_api_key: str = ""
    openai_model: str = "gpt-5-mini"
    top_k: int = 5
    max_context_chars: int = 12000
    max_question_chars: int = 8000
    max_result_rows: int = 200
    query_timeout_seconds: int = 15
    oracle_user: str = ""
    oracle_password: str = ""
    oracle_dsn: str = ""

    @classmethod
    def from_env(cls) -> "Settings":
        root = Path(__file__).resolve().parents[2]
        return cls(
            database_path=Path(os.getenv("ERP_IA_DB", root / "data" / "erp_ia.db")),
            host=os.getenv("ERP_IA_HOST", "127.0.0.1"),
            port=int(os.getenv("ERP_IA_PORT", "8080")),
            api_bearer_token=os.getenv("ERP_IA_API_BEARER_TOKEN", ""),
            provider=os.getenv("ERP_IA_PROVIDER", "disabled").lower(),
            openai_api_key=os.getenv("OPENAI_API_KEY", ""),
            openai_model=os.getenv("ERP_IA_OPENAI_MODEL", "gpt-5-mini"),
            top_k=int(os.getenv("ERP_IA_TOP_K", "5")),
            max_context_chars=int(os.getenv("ERP_IA_MAX_CONTEXT_CHARS", "12000")),
            max_question_chars=int(os.getenv("ERP_IA_MAX_QUESTION_CHARS", "8000")),
            max_result_rows=int(os.getenv("ERP_IA_MAX_RESULT_ROWS", "200")),
            query_timeout_seconds=int(os.getenv("ERP_IA_QUERY_TIMEOUT_SECONDS", "15")),
            oracle_user=os.getenv("ERP_IA_ORACLE_USER", ""),
            oracle_password=os.getenv("ERP_IA_ORACLE_PASSWORD", ""),
            oracle_dsn=os.getenv("ERP_IA_ORACLE_DSN", ""),
        )
