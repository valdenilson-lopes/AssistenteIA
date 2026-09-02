from __future__ import annotations

import json
from pathlib import Path

from .config import Settings
from .database import Database
from .knowledge import KnowledgeCenter
from .orchestrator import Orchestrator
from .providers import DisabledProvider, OpenAIResponsesProvider


class AppService:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.db = Database(settings.database_path)
        self.db.initialize()
        self.knowledge = KnowledgeCenter(self.db)
        if settings.provider == "openai":
            provider = OpenAIResponsesProvider(settings.openai_api_key, settings.openai_model,
                                                Path(__file__).resolve().parents[1] / "system-prompt.txt")
        else:
            provider = DisabledProvider()
        self.orchestrator = Orchestrator(self.db, self.knowledge, provider, settings)

    def conversation(self, conversation_id: str, user: str, company: str, branch: str) -> dict | None:
        with self.db.connect() as conn:
            row = conn.execute("SELECT * FROM ia_conversa WHERE id=? AND usuario=? AND empresa=? AND filial=?",
                               (conversation_id, user, company, branch)).fetchone()
            if not row:
                return None
            messages = [dict(x) for x in conn.execute(
                "SELECT id,papel,conteudo,criada_em FROM ia_mensagem WHERE conversa_id=? ORDER BY criada_em", (conversation_id,))]
            result = dict(row)
            result["mensagens"] = messages
            return result

    def demands(self) -> list[dict]:
        with self.db.connect() as conn:
            return [dict(x) for x in conn.execute("SELECT * FROM ia_demanda_conhecimento ORDER BY criada_em DESC LIMIT 500")]

    def metrics(self) -> dict:
        with self.db.connect() as conn:
            row = conn.execute("SELECT COUNT(*) total, SUM(sucesso) sucessos, SUM(tokens_entrada) entrada, SUM(tokens_saida) saida, AVG(duracao_ms) latencia_media_ms FROM ia_auditoria").fetchone()
            return dict(row)
