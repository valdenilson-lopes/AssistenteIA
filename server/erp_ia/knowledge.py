from __future__ import annotations

import hashlib
import math
import re
import uuid
from collections import Counter
from dataclasses import dataclass

from .database import Database, utcnow


WORD_RE = re.compile(r"[\wÀ-ÿ]+", re.UNICODE)


def words(text: str) -> list[str]:
    return [x.lower() for x in WORD_RE.findall(text) if len(x) > 1]


def chunk_text(text: str, target_chars: int = 1800, overlap_chars: int = 200) -> list[str]:
    normalized = re.sub(r"\r\n?", "\n", text).strip()
    if not normalized:
        return []
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", normalized) if p.strip()]
    chunks: list[str] = []
    current = ""
    for paragraph in paragraphs:
        if len(current) + len(paragraph) + 2 <= target_chars:
            current = (current + "\n\n" + paragraph).strip()
            continue
        if current:
            chunks.append(current)
        while len(paragraph) > target_chars:
            chunks.append(paragraph[:target_chars])
            paragraph = paragraph[max(1, target_chars - overlap_chars):]
        current = paragraph
    if current:
        chunks.append(current)
    return chunks


@dataclass(frozen=True)
class SearchHit:
    source_id: str
    title: str
    version: str
    module: str
    subject: str
    content: str
    score: float


class KnowledgeCenter:
    def __init__(self, db: Database):
        self.db = db

    def create_module(self, name: str, description: str = "") -> str:
        module_id = str(uuid.uuid4())
        with self.db.connect() as conn:
            conn.execute(
                "INSERT INTO ia_modulo(id,nome,descricao,criado_em) VALUES(?,?,?,?)",
                (module_id, name.strip(), description.strip(), utcnow()),
            )
        return module_id

    def submit_document(self, *, module_id: str, subject: str, description: str,
                        keywords: str, author: str, content_type: str,
                        content: str, filename: str | None = None) -> str:
        if content_type.lower() not in {"text/plain", "text/markdown"}:
            raise ValueError("Formato ainda não suportado pela ingestão: " + content_type)
        if not content.strip():
            raise ValueError("Documento sem conteúdo.")
        now = utcnow()
        document_id, version_id = str(uuid.uuid4()), str(uuid.uuid4())
        digest = hashlib.sha256(content.encode("utf-8")).hexdigest()
        with self.db.connect() as conn:
            if not conn.execute("SELECT 1 FROM ia_modulo WHERE id=? AND ativo=1", (module_id,)).fetchone():
                raise ValueError("Módulo inexistente ou inativo.")
            conn.execute(
                "INSERT INTO ia_documento VALUES(?,?,?,?,?,?,?,?,?)",
                (document_id, module_id, subject.strip(), description.strip(), keywords.strip(),
                 "PENDENTE", author, now, now),
            )
            conn.execute(
                "INSERT INTO ia_documento_versao(id,documento_id,numero,tipo_conteudo,nome_arquivo,conteudo,hash_sha256,criado_por,criado_em) VALUES(?,?,?,?,?,?,?,?,?)",
                (version_id, document_id, 1, content_type.lower(), filename, content, digest, author, now),
            )
        return document_id

    def approve(self, document_id: str, approver: str) -> None:
        now = utcnow()
        with self.db.connect() as conn:
            row = conn.execute("SELECT status FROM ia_documento WHERE id=?", (document_id,)).fetchone()
            if not row or row["status"] != "PENDENTE":
                raise ValueError("Somente documentos pendentes podem ser aprovados.")
            conn.execute("UPDATE ia_documento SET status='APROVADO', atualizado_em=? WHERE id=?", (now, document_id))
            conn.execute("UPDATE ia_documento_versao SET aprovado_por=?, aprovado_em=? WHERE documento_id=? AND numero=1", (approver, now, document_id))
        self.reindex(document_id)

    def reject(self, document_id: str) -> None:
        with self.db.connect() as conn:
            changed = conn.execute("UPDATE ia_documento SET status='REJEITADO', atualizado_em=? WHERE id=? AND status='PENDENTE'", (utcnow(), document_id)).rowcount
            if not changed:
                raise ValueError("Somente documentos pendentes podem ser rejeitados.")

    def reindex(self, document_id: str) -> int:
        with self.db.connect() as conn:
            row = conn.execute(
                "SELECT d.modulo_id,d.assunto,v.id version_id,v.conteudo FROM ia_documento d JOIN ia_documento_versao v ON v.documento_id=d.id WHERE d.id=? AND d.status='APROVADO' ORDER BY v.numero DESC LIMIT 1",
                (document_id,),
            ).fetchone()
            if not row:
                raise ValueError("Somente documento aprovado pode ser indexado.")
            pieces = chunk_text(row["conteudo"])
            conn.execute("DELETE FROM ia_chunk WHERE versao_id=?", (row["version_id"],))
            for order, piece in enumerate(pieces):
                conn.execute(
                    "INSERT INTO ia_chunk VALUES(?,?,?,?,?,?,?)",
                    (str(uuid.uuid4()), row["version_id"], row["modulo_id"], row["assunto"],
                     order, piece, math.ceil(len(piece) / 4)),
                )
            conn.execute("UPDATE ia_documento_versao SET indexado_em=? WHERE id=?", (utcnow(), row["version_id"]))
        return len(pieces)

    def search(self, query: str, module: str | None, top_k: int, max_chars: int) -> list[SearchHit]:
        query_terms = Counter(words(query))
        if not query_terms:
            return []
        sql = """SELECT c.id,c.conteudo,c.assunto,m.nome modulo,d.id documento_id,v.numero
                 FROM ia_chunk c JOIN ia_modulo m ON m.id=c.modulo_id
                 JOIN ia_documento_versao v ON v.id=c.versao_id
                 JOIN ia_documento d ON d.id=v.documento_id
                 WHERE d.status='APROVADO'"""
        args: list[object] = []
        if module:
            sql += " AND lower(m.nome)=lower(?)"
            args.append(module)
        with self.db.connect() as conn:
            rows = conn.execute(sql, args).fetchall()
        hits: list[SearchHit] = []
        for row in rows:
            chunk_terms = Counter(words(row["conteudo"]))
            overlap = sum(min(count, chunk_terms[term]) for term, count in query_terms.items())
            if not overlap:
                continue
            score = overlap / math.sqrt(max(1, sum(chunk_terms.values())))
            hits.append(SearchHit(row["documento_id"], row["assunto"], str(row["numero"]),
                                  row["modulo"], row["assunto"], row["conteudo"], score))
        hits.sort(key=lambda x: x.score, reverse=True)
        selected: list[SearchHit] = []
        size = 0
        for hit in hits[:top_k]:
            if size + len(hit.content) > max_chars:
                continue
            selected.append(hit)
            size += len(hit.content)
        return selected
