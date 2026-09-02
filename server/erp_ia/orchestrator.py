from __future__ import annotations

import json
import re
import time
import uuid
from dataclasses import asdict

from .config import Settings
from .database import Database, utcnow
from .knowledge import KnowledgeCenter, SearchHit
from .providers import AIProvider
from .security import validate_context


DOMAIN_TERMS = {
    "Financeiro": ("financeiro", "receber", "pagar", "título", "titulo", "boleto", "vencid"),
    "Vendas": ("vend", "pedido", "vendedor", "faturamento"),
    "Estoque": ("estoque", "saldo", "prateleira"),
    "Produtos": ("produto", "preço", "preco", "código de barras"),
    "Clientes": ("cliente", "fornecedor", "clifor"),
    "PIX": ("pix", "conciliação", "conciliacao"),
    "Fiscal": ("fiscal", "nota", "nfe", "tribut"),
    "Compras": ("compra", "fornecedor"),
}

CURRENT_DATA_TERMS = re.compile(
    r"\b(hoje|agora|atual|quanto|quantos|total|saldo|pendente|vencid|maior|menor)\b", re.I
)
ERP_ANCHORS = re.compile(
    r"\b(erp|rotina|sistema|cadastro|campo|relatório|relatorio|módulo|modulo|documentação|documentacao)\b",
    re.I,
)


class Orchestrator:
    def __init__(self, db: Database, knowledge: KnowledgeCenter,
                 provider: AIProvider, settings: Settings):
        self.db, self.knowledge, self.provider, self.settings = db, knowledge, provider, settings

    @staticmethod
    def detect_domain(question: str) -> str | None:
        lower = question.lower()
        scores = {domain: sum(term in lower for term in terms) for domain, terms in DOMAIN_TERMS.items()}
        domain, score = max(scores.items(), key=lambda item: item[1])
        return domain if score else None

    def ask(self, request: dict) -> dict:
        started = time.monotonic()
        request_id = str(request.get("request_id") or uuid.uuid4())
        question = str(request.get("question") or "").strip()
        context = request.get("context") or {}
        validate_context(context)
        if not question or len(question) > self.settings.max_question_chars:
            raise ValueError("Pergunta vazia ou acima do limite.")
        conversation_id = str(request.get("conversation_id") or uuid.uuid4())
        domain = self.detect_domain(question)
        self._ensure_conversation(conversation_id, question, context)
        self._message(conversation_id, "user", question)
        hits = self.knowledge.search(question, domain, self.settings.top_k,
                                     self.settings.max_context_chars)

        if domain is None and not hits and not ERP_ANCHORS.search(question):
            answer = "Posso responder somente perguntas relacionadas ao ERP, seus dados e sua documentação."
            self._message(conversation_id, "assistant", answer)
            self._audit(started, question, context, conversation_id, None, [], True, None)
            return {"request_id": request_id, "conversation_id": conversation_id,
                    "status": "refused_out_of_scope", "answer": answer,
                    "knowledge_sufficient": False, "sources": [], "suggested_action": None,
                    "knowledge_request_id": None, "usage": None, "error": None}

        # Dados vivos nunca são respondidos usando texto documental como se fosse atual.
        if CURRENT_DATA_TERMS.search(question):
            result = self._insufficient(request_id, conversation_id,
                "Ainda não existe uma ferramenta autorizada e habilitada para consultar esse dado atual.",
                context, domain, "Ferramenta de dados vivos não disponível")
            self._audit(started, question, context, conversation_id, domain, [], False,
                        "LIVE_DATA_TOOL_UNAVAILABLE")
            return result

        if not hits:
            result = self._insufficient(request_id, conversation_id,
                "Ainda não tenho conhecimento suficiente sobre este assunto no ERP. "
                "Posso aprender quando a documentação correspondente for adicionada ao Centro de Conhecimento.",
                context, domain, "Nenhuma evidência aprovada recuperada")
            self._audit(started, question, context, conversation_id, domain, [], True, None)
            return result

        evidence = "\n\n".join(
            f"[Fonte {i}: {hit.title} | módulo {hit.module} | versão {hit.version}]\n{hit.content}"
            for i, hit in enumerate(hits, 1)
        )
        try:
            answer = self.provider.answer(question, evidence)
            if not answer.text:
                raise RuntimeError("Provider retornou resposta vazia.")
            sources = [self._source(hit) for hit in hits]
            self._message(conversation_id, "assistant", answer.text)
            self._audit(started, question, context, conversation_id, domain, sources, True, None,
                        answer.input_tokens, answer.output_tokens, answer.model)
            return {
                "request_id": request_id, "conversation_id": conversation_id,
                "status": "answered", "answer": answer.text,
                "knowledge_sufficient": True, "sources": sources,
                "suggested_action": None, "knowledge_request_id": None,
                "usage": {"provider": self.provider.name, "model": answer.model,
                          "input_tokens": answer.input_tokens, "output_tokens": answer.output_tokens,
                          "latency_ms": answer.latency_ms, "cost": None, "currency": None},
                "error": None,
            }
        except Exception as exc:
            correlation = str(uuid.uuid4())
            self._audit(started, question, context, conversation_id, domain,
                        [self._source(x) for x in hits], False, "PROVIDER_ERROR")
            return {
                "request_id": request_id, "conversation_id": conversation_id,
                "status": "error", "answer": "Não foi possível gerar a resposta neste momento.",
                "knowledge_sufficient": False, "sources": [], "suggested_action": None,
                "knowledge_request_id": None, "usage": None,
                "error": {"code": "PROVIDER_ERROR", "user_message": "Serviço de IA indisponível.",
                          "correlation_id": correlation},
            }

    @staticmethod
    def _source(hit: SearchHit) -> dict:
        return {"source_type": "knowledge", "source_id": hit.source_id,
                "title": hit.title, "version": hit.version}

    def _insufficient(self, request_id: str, conversation_id: str, answer: str,
                      context: dict, domain: str | None, reason: str) -> dict:
        demand_id = str(uuid.uuid4())
        now = utcnow()
        with self.db.connect() as conn:
            conn.execute(
                "INSERT INTO ia_demanda_conhecimento(id,pergunta,usuario,empresa,filial,modulo_provavel,assunto_provavel,motivo,status,conversa_id,criada_em,atualizada_em) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
                (demand_id, answer if False else "", context["user_code"], context["company_code"],
                 context["branch_code"], domain, None, reason, "ABERTA", conversation_id, now, now),
            )
            # Pergunta é preenchida pela última mensagem para não duplicar parâmetro sensível em chamadas internas.
            row = conn.execute("SELECT conteudo FROM ia_mensagem WHERE conversa_id=? AND papel='user' ORDER BY criada_em DESC LIMIT 1", (conversation_id,)).fetchone()
            conn.execute("UPDATE ia_demanda_conhecimento SET pergunta=? WHERE id=?", (row["conteudo"] if row else "", demand_id))
        self._message(conversation_id, "assistant", answer)
        return {"request_id": request_id, "conversation_id": conversation_id,
                "status": "knowledge_insufficient", "answer": answer,
                "knowledge_sufficient": False, "sources": [], "suggested_action": "teach_ai",
                "knowledge_request_id": demand_id, "usage": None, "error": None}

    def _ensure_conversation(self, conversation_id: str, question: str, context: dict) -> None:
        now = utcnow()
        with self.db.connect() as conn:
            row = conn.execute("SELECT usuario,empresa,filial FROM ia_conversa WHERE id=?", (conversation_id,)).fetchone()
            if row:
                if (row["usuario"], row["empresa"], row["filial"]) != (
                    context["user_code"], context["company_code"], context["branch_code"]):
                    raise PermissionError("Conversa pertence a outro contexto.")
                conn.execute("UPDATE ia_conversa SET atualizada_em=? WHERE id=?", (now, conversation_id))
            else:
                conn.execute("INSERT INTO ia_conversa(id,titulo,usuario,empresa,filial,criada_em,atualizada_em) VALUES(?,?,?,?,?,?,?)",
                             (conversation_id, question[:80], context["user_code"], context["company_code"], context["branch_code"], now, now))

    def _message(self, conversation_id: str, role: str, content: str) -> None:
        with self.db.connect() as conn:
            conn.execute("INSERT INTO ia_mensagem VALUES(?,?,?,?,?)",
                         (str(uuid.uuid4()), conversation_id, role, content, utcnow()))

    def _audit(self, started: float, question: str, context: dict, conversation_id: str,
               domain: str | None, sources: list[dict], success: bool, error: str | None,
               input_tokens: int = 0, output_tokens: int = 0, model: str = "") -> None:
        with self.db.connect() as conn:
            conn.execute(
                "INSERT INTO ia_auditoria(id,usuario,empresa,filial,conversa_id,pergunta,dominio,fontes,duracao_ms,sucesso,codigo_erro,tokens_entrada,tokens_saida,provider,modelo,criada_em) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (str(uuid.uuid4()), context["user_code"], context["company_code"], context["branch_code"],
                 conversation_id, question, domain, json.dumps(sources, ensure_ascii=False),
                 int((time.monotonic() - started) * 1000), int(success), error,
                 input_tokens, output_tokens, self.provider.name, model, utcnow()),
            )
