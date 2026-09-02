from __future__ import annotations

import hmac
import json
import re
import uuid
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

from .config import Settings
from .service import AppService


class ApiHandler(BaseHTTPRequestHandler):
    service: AppService
    settings: Settings
    server_version = "ERP-IA/0.1"

    def log_message(self, format: str, *args) -> None:
        # Evita registrar corpo, token ou pergunta no log HTTP padrão.
        print(f"{self.address_string()} [{self.log_date_time_string()}] {format % args}")

    def do_GET(self) -> None:
        try:
            self._authenticate()
            path = urlparse(self.path).path
            if path == "/health":
                return self._json(200, {"status": "ok", "provider": self.settings.provider})
            if path == "/ia/conhecimento/demandas":
                self._require_role("knowledge_admin")
                return self._json(200, {"items": self.service.demands()})
            if path == "/ia/metricas":
                self._require_role("ia_admin")
                return self._json(200, self.service.metrics())
            match = re.fullmatch(r"/ia/conversas/([0-9a-fA-F-]+)", path)
            if match:
                user, company, branch = self._identity_headers()
                result = self.service.conversation(match.group(1), user, company, branch)
                return self._json(200, result) if result else self._error(404, "NOT_FOUND", "Conversa não encontrada.")
            self._error(404, "NOT_FOUND", "Recurso não encontrado.")
        except Exception as exc:
            self._handle_exception(exc)

    def do_POST(self) -> None:
        try:
            self._authenticate()
            path = urlparse(self.path).path
            body = self._read_json()
            if path == "/ia/perguntar":
                self._validate_identity(body.get("context") or {})
                return self._json(200, self.service.orchestrator.ask(body))
            if path == "/ia/conversas":
                self._validate_identity(body.get("context") or {})
                body.setdefault("request_id", str(uuid.uuid4()))
                body.setdefault("question", "Nova conversa")
                # A conversa é criada naturalmente na primeira pergunta; não cria mensagem artificial.
                return self._json(201, {"conversation_id": str(uuid.uuid4())})
            if path == "/ia/conhecimento/modulos":
                self._require_role("knowledge_admin")
                module_id = self.service.knowledge.create_module(body.get("name", ""), body.get("description", ""))
                return self._json(201, {"id": module_id})
            if path == "/ia/conhecimento/documentos":
                self._require_role("knowledge_admin")
                document_id = self.service.knowledge.submit_document(
                    module_id=body.get("module_id", ""), subject=body.get("subject", ""),
                    description=body.get("description", ""), keywords=body.get("keywords", ""),
                    author=self.headers.get("X-ERP-User", ""), content_type=body.get("content_type", ""),
                    content=body.get("content", ""), filename=body.get("filename"),
                )
                return self._json(201, {"id": document_id, "status": "PENDENTE"})
            match = re.fullmatch(r"/ia/conhecimento/([0-9a-fA-F-]+)/(aprovar|rejeitar|reindexar)", path)
            if match:
                document_id, action = match.groups()
                if action in {"aprovar", "rejeitar"}:
                    self._require_role("knowledge_approver")
                else:
                    self._require_role("knowledge_admin")
                if action == "aprovar":
                    self.service.knowledge.approve(document_id, self.headers.get("X-ERP-User", ""))
                elif action == "rejeitar":
                    self.service.knowledge.reject(document_id)
                else:
                    self.service.knowledge.reindex(document_id)
                return self._json(200, {"id": document_id, "action": action, "success": True})
            self._error(404, "NOT_FOUND", "Recurso não encontrado.")
        except Exception as exc:
            self._handle_exception(exc)

    def _authenticate(self) -> None:
        expected = self.settings.api_bearer_token
        if not expected:
            if self.client_address[0] not in {"127.0.0.1", "::1"}:
                raise PermissionError("API sem autenticação só aceita loopback.")
            return
        supplied = self.headers.get("Authorization", "")
        if not hmac.compare_digest(supplied, "Bearer " + expected):
            raise PermissionError("Token da API inválido.")

    def _identity_headers(self) -> tuple[str, str, str]:
        values = tuple(self.headers.get(x, "").strip() for x in ("X-ERP-User", "X-ERP-Company", "X-ERP-Branch"))
        if not all(values):
            raise PermissionError("Identidade ERP não fornecida pelo gateway.")
        return values  # type: ignore[return-value]

    def _validate_identity(self, context: dict) -> None:
        identity = self._identity_headers()
        payload = (str(context.get("user_code", "")), str(context.get("company_code", "")), str(context.get("branch_code", "")))
        if identity != payload:
            raise PermissionError("Contexto diverge da identidade autenticada.")

    def _require_role(self, role: str) -> None:
        roles = {x.strip() for x in self.headers.get("X-ERP-Roles", "").split(",") if x.strip()}
        if role not in roles:
            raise PermissionError("Permissão necessária: " + role)

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > 2_000_000:
            raise ValueError("Corpo vazio ou acima do limite.")
        value = json.loads(self.rfile.read(length).decode("utf-8"))
        if not isinstance(value, dict):
            raise ValueError("O corpo deve ser um objeto JSON.")
        return value

    def _json(self, status: int, value) -> None:
        data = json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(data)

    def _error(self, status: int, code: str, message: str) -> None:
        self._json(status, {"error": {"code": code, "user_message": message,
                                      "correlation_id": str(uuid.uuid4())}})

    def _handle_exception(self, exc: Exception) -> None:
        if isinstance(exc, PermissionError):
            self._error(403, "FORBIDDEN", str(exc))
        elif isinstance(exc, (ValueError, json.JSONDecodeError)):
            self._error(400, "INVALID_REQUEST", str(exc))
        else:
            self._error(500, "INTERNAL_ERROR", "Falha interna. Consulte o identificador de correlação.")


def serve(settings: Settings) -> None:
    service = AppService(settings)
    handler = type("ConfiguredApiHandler", (ApiHandler,), {"service": service, "settings": settings})
    server = ThreadingHTTPServer((settings.host, settings.port), handler)
    print(f"ERP IA ouvindo em http://{settings.host}:{settings.port}")
    server.serve_forever()
