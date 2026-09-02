from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator


SCHEMA = """
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS ia_modulo (
  id TEXT PRIMARY KEY, nome TEXT NOT NULL UNIQUE, descricao TEXT NOT NULL DEFAULT '',
  ativo INTEGER NOT NULL DEFAULT 1, criado_em TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS ia_documento (
  id TEXT PRIMARY KEY, modulo_id TEXT NOT NULL REFERENCES ia_modulo(id),
  assunto TEXT NOT NULL, descricao TEXT NOT NULL DEFAULT '', palavras_chave TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL CHECK(status IN ('RASCUNHO','PENDENTE','APROVADO','REJEITADO','INATIVO')),
  autor TEXT NOT NULL, criado_em TEXT NOT NULL, atualizado_em TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS ia_documento_versao (
  id TEXT PRIMARY KEY, documento_id TEXT NOT NULL REFERENCES ia_documento(id),
  numero INTEGER NOT NULL, tipo_conteudo TEXT NOT NULL, nome_arquivo TEXT,
  conteudo TEXT NOT NULL, hash_sha256 TEXT NOT NULL, criado_por TEXT NOT NULL,
  criado_em TEXT NOT NULL, aprovado_por TEXT, aprovado_em TEXT,
  indexado_em TEXT, UNIQUE(documento_id, numero)
);
CREATE TABLE IF NOT EXISTS ia_chunk (
  id TEXT PRIMARY KEY, versao_id TEXT NOT NULL REFERENCES ia_documento_versao(id) ON DELETE CASCADE,
  modulo_id TEXT NOT NULL, assunto TEXT NOT NULL, ordem INTEGER NOT NULL,
  conteudo TEXT NOT NULL, tokens_estimados INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_ia_chunk_modulo ON ia_chunk(modulo_id, assunto);
CREATE TABLE IF NOT EXISTS ia_conversa (
  id TEXT PRIMARY KEY, titulo TEXT NOT NULL DEFAULT '', usuario TEXT NOT NULL,
  empresa TEXT NOT NULL, filial TEXT NOT NULL, criada_em TEXT NOT NULL,
  atualizada_em TEXT NOT NULL, arquivada INTEGER NOT NULL DEFAULT 0,
  resumo TEXT NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS ia_mensagem (
  id TEXT PRIMARY KEY, conversa_id TEXT NOT NULL REFERENCES ia_conversa(id),
  papel TEXT NOT NULL CHECK(papel IN ('user','assistant','system')),
  conteudo TEXT NOT NULL, criada_em TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_ia_mensagem_conversa ON ia_mensagem(conversa_id, criada_em);
CREATE TABLE IF NOT EXISTS ia_demanda_conhecimento (
  id TEXT PRIMARY KEY, pergunta TEXT NOT NULL, usuario TEXT NOT NULL,
  empresa TEXT NOT NULL, filial TEXT NOT NULL, modulo_provavel TEXT,
  assunto_provavel TEXT, motivo TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'ABERTA',
  conversa_id TEXT, documento_resolucao_id TEXT, criada_em TEXT NOT NULL,
  atualizada_em TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS ia_auditoria (
  id TEXT PRIMARY KEY, usuario TEXT NOT NULL, empresa TEXT NOT NULL, filial TEXT NOT NULL,
  conversa_id TEXT, pergunta TEXT, dominio TEXT, fontes TEXT NOT NULL DEFAULT '[]',
  ferramenta TEXT, sql_texto TEXT, duracao_ms INTEGER NOT NULL DEFAULT 0,
  sucesso INTEGER NOT NULL, codigo_erro TEXT, tokens_entrada INTEGER NOT NULL DEFAULT 0,
  tokens_saida INTEGER NOT NULL DEFAULT 0, provider TEXT, modelo TEXT,
  criada_em TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS ia_view_autorizada (
  nome TEXT PRIMARY KEY, modulo TEXT NOT NULL, autorizada INTEGER NOT NULL DEFAULT 0,
  coluna_escopo_filial TEXT, limite_linhas INTEGER NOT NULL DEFAULT 200,
  observacoes TEXT NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS ia_operacao (
  nome TEXT PRIMARY KEY, modulo TEXT NOT NULL, descricao TEXT NOT NULL,
  sql_texto TEXT NOT NULL, habilitada INTEGER NOT NULL DEFAULT 0,
  criada_em TEXT NOT NULL
);
"""


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class Database:
    def __init__(self, path: Path):
        self.path = path

    def initialize(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as conn:
            conn.executescript(SCHEMA)

    @contextmanager
    def connect(self) -> Iterator[sqlite3.Connection]:
        conn = sqlite3.connect(self.path, timeout=10)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
