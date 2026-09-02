from __future__ import annotations

import json
import re
import time
import uuid

from .config import Settings
from .database import Database, utcnow
from .knowledge import KnowledgeCenter, SearchHit
from .providers import AIProvider
from .security import validate_context
from .tools import ToolCatalog


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
SALES_TODAY_TERMS = re.compile(
    r"\b(vend(?:a|as|emos|eu|ido|idos)?|fatur(?:amento|ado|amos)?)\b", re.I
)
TODAY_TERMS = re.compile(r"\b(hoje|dia atual|neste dia)\b", re.I)


class Orchestrator:
    def __init__(self, db: Database, knowledge: KnowledgeCenter,
                 provider: AIProvider, settings: Settings,
                 tools: ToolCatalog | None = None):
        self.db = db
        self.knowledge = knowledge
        self.provider = provider
        self.settings = settings
        self.tools = tools

    @staticmethod
    def detect_domain(question: str) -> str | None:
        lower = question.lower()
        scores = {domain: sum(term in lower for term in terms) for domain, terms in DOMAIN_TERMS.items()}
        domain, score = max(scores.items(), key=lambda item: item[1])
        return domain if score else None

    @staticmethod
    def _is_sales_today(question: str, domain: str | None) -> bool:
        return domain == "Vendas" and bool(
            SALES_TODAY_TERMS.search(question) and TODAY_TERMS.search(question)
        )

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

        if self._is_sales_today(question, domain):
            return self._answer_sales_today(
                started, request_id, conversation_id, question, context
            )

        hits = self.knowledge.search(
            question, domain, self.settings.top_k, self.settings.max_context_chars
        )

        if domain is None and not hits and not ERP_ANCHORS.search(question):
            answer = "Posso responder somente perguntas relacionadas ao ERP, seus dados e sua documentação."
            self._message(conversation_id, "assistant", answer)
            self._audit(started, question, context, conversation_id, None, [], True, None)
            return {
                "request_id": request_id, "conversation_id": conversation_id,
                "status": "refused_out_of_scope", "answer": answer,
                "knowledge_sufficient": False, "sources": [], "suggested_action": None,
                "knowledge_request_id": None, "usage": None, "error": None,
            }

        if CURRENT_DATA_TERMS.search(question):
            result = self._insufficient(
                request_id, conversation_id,
                "Ainda não existe uma ferramenta autorizada e habilitada para consultar esse dado atual.",
                context, domain, "Ferramenta de dados vivos não disponível"
            )
            self._audit(started, question, context, conversation_id, domain, [], False,
                        "LIVE_DATA_TOOL_UNAVAILABLE")
            return result

        if not hits:
            result = self._insufficient(
                request_id, conversation_id,
                "Ainda não tenho conhecimento suficiente sobre este assunto no ERP. "
                "Posso aprender quando a documentação correspondente for adicionada ao Centro de Conhecimento.",
                context, domain, "Nenhuma evidência aprovada recuperada"
            )
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
        except Exception:
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

    def _answer_sales_today(self, started: float, request_id: str,
                            conversation_id: str, question: str, context: dict) -> dict:
        if self.tools is None:
            return self._live_data_error(
                started, request_id, conversation_id, question, context,
                "TOOL_CATALOG_NOT_CONFIGURED", "Catálogo de ferramentas não configurado."
            )

        parameters = {"codfilial": str(context["branch_code"])}
        allowed_branches = {str(x) for x in context["allowed_branch_codes"]}

        try:
            rows = self.tools.execute("vendas_hoje", parameters, allowed_branches)
            total = 0
            if rows:
                total = rows[0].get("total_vendas", 0) or 0

            try:
                total_number = float(total)
                total_text = f"R$ {total_number:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")
            except (TypeError, ValueError):
                total_text = str(total)

            answer = f"Total vendido hoje na filial {context['branch_code']}: {total_text}."
            source = {
                "source_type": "live_data",
                "source_id": "BI_VENDA_FLYGESTOR",
                "title": "BI_VENDA_FLYGESTOR",
                "version": None,
            }
            self._message(conversation_id, "assistant", answer)
            self._audit(
                started, question, context, conversation_id, "Vendas", [source], True, None,
                tool="vendas_hoje",
                sql_text=(
                    "SELECT NVL(SUM(VRVENDA), 0) AS TOTAL_VENDAS FROM BI_VENDA_FLYGESTOR "
                    "WHERE CODFILIAL = :codfilial AND TRUNC(DATAMOVIMENTO) = TRUNC(SYSDATE)"
                ),
            )
            return {
                "request_id": request_id, "conversation_id": conversation_id,
                "status": "answered", "answer": answer,
                "knowledge_sufficient": True, "sources": [source],
                "suggested_action": None, "knowledge_request_id": None,
                "usage": None, "error": None,
            }
        except Exception as exc:
            return self._live_data_error(
                started, request_id, conversation_id, question, context,
                "LIVE_DATA_QUERY_ERROR", str(exc)
            )

    def _live_data_error(self, started: float, request_id: str,
                         conversation_id: str, question: str, context: dict,
                         code: str, technical_message: str) -> dict:
        correlation = str(uuid.uuid4())
        answer = "Não foi possível consultar os dados atuais do ERP neste momento."
        self._message(conversation_id, "assistant", answer)
        self._audit(started, question, context, conversation_id, "Vendas", [], False, code,
                    tool="vendas_hoje")
        return {
            "request_id": request_id, "conversation_id": conversation_id,
            "status": "error", "answer": answer,
            "knowledge_sufficient": False, "sources": [], "suggested_action": None,
            "knowledge_request_id": None, "usage": None,
            "error": {"code": code, "user_message": technical_message,
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
                (demand_id, "", context["user_code"], context["company_code"],
                 context["branch_code"], domain, None, reason, "ABERTA", conversation_id, now, now),
            )
            row = conn.execute(
                "SELECT conteudo FROM ia_mensagem WHERE conversa_id=? AND papel='user' ORDER BY criada_em DESC LIMIT 1",
                (conversation_id,)
            ).fetchone()
            conn.execute("UPDATE ia_demanda_conhecimento SET pergunta=? WHERE id=?",
                         (row["conteudo"] if row else "", demand_id))
        self._message(conversation_id, "assistant", answer)
        return {"request_id": request_id, "conversation_id": conversation_id,
                "status": "knowledge_insufficient", "answer": answer,
                "knowledge_sufficient": False, "sources": [], "suggested_action": "teach_ai",
                "knowledge_request_id": demand_id, "usage": None, "error": None}

    def _ensure_conversation(self, conversation_id: str, question: str, context: dict) -> None:
        now = utcnow()
        with self.db.connect() as conn:
            row = conn.execute("SELECT usuario,empresa,filial FROM ia_conversa WHERE id=?",
                               (conversation_id,)).fetchone()
            if row:
                if (row["usuario"], row["empresa"], row["filial"]) != (
                    context["user_code"], context["company_code"], context["branch_code"]):
                    raise PermissionError("Conversa pertence a outro contexto.")
                conn.execute("UPDATE ia_conversa SET atualizada_em=? WHERE id=?", (now, conversation_id))
            else:
                conn.execute(
                    "INSERT INTO ia_conversa(id,titulo,usuario,empresa,filial,criada_em,atualizada_em) VALUES(?,?,?,?,?,?,?)",
                    (conversation_id, question[:80], context["user_code"], context["company_code"],
                     context["branch_code"], now, now)
                )

    def _message(self, conversation_id: str, role: str, content: str) -> None:
        with self.db.connect() as conn:
            conn.execute("INSERT INTO ia_mensagem VALUES(?,?,?,?,?)",
                         (str(uuid.uuid4()), conversation_id, role, content, utcnow()))

    def _audit(self, started: float, question: str, context: dict, conversation_id: str,
               domain: str | None, sources: list[dict], success: bool, error: str | None,
               input_tokens: int = 0, output_tokens: int = 0, model: str = "",
               tool: str | None = None, sql_text: str | None = None) -> None:
        with self.db.connect() as conn:
            conn.execute(
                "INSERT INTO ia_auditoria(id,usuario,empresa,filial,conversa_id,pergunta,dominio,fontes,ferramenta,sql_texto,duracao_ms,sucesso,codigo_erro,tokens_entrada,tokens_saida,provider,modelo,criada_em) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (str(uuid.uuid4()), context["user_code"], context["company_code"], context["branch_code"],
                 conversation_id, question, domain, json.dumps(sources, ensure_ascii=False),
                 tool, sql_text, int((time.monotonic() - started) * 1000), int(success), error,
                 input_tokens, output_tokens, self.provider.name, model, utcnow()),
            )
