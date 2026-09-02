from __future__ import annotations

import re
from dataclasses import dataclass


class SqlRejected(ValueError):
    pass


@dataclass(frozen=True)
class ValidatedSql:
    sql: str
    referenced_objects: tuple[str, ...]


class ConservativeSelectValidator:
    """Validador conservador; deve ser substituído por parser Oracle na fase ad hoc."""

    DENIED = frozenset({
        "INSERT", "UPDATE", "DELETE", "MERGE", "ALTER", "DROP", "CREATE",
        "TRUNCATE", "EXECUTE", "EXEC", "GRANT", "REVOKE", "COMMIT",
        "ROLLBACK", "BEGIN", "DECLARE", "CALL", "DBMS_SQL", "UTL_HTTP",
        "DBMS_SCHEDULER", "PRAGMA", "INTO",
    })
    SOURCE_RE = re.compile(r"\b(?:FROM|JOIN)\s+([A-Z][A-Z0-9_$#]*(?:\.[A-Z][A-Z0-9_$#]*)?)", re.I)

    def validate(self, sql: str, whitelist: set[str]) -> ValidatedSql:
        if not sql or len(sql) > 100_000:
            raise SqlRejected("SQL vazio ou acima do limite.")
        clean = self._strip_comments_and_literals(sql)
        tokens = re.findall(r"[A-Z_][A-Z0-9_$#]*|;", clean.upper())
        if not tokens or tokens[0] not in {"SELECT", "WITH"}:
            raise SqlRejected("Somente SELECT é permitido.")
        if ";" in tokens:
            raise SqlRejected("Ponto e vírgula e múltiplas instruções são proibidos.")
        denied = self.DENIED.intersection(tokens)
        if denied:
            raise SqlRejected("Comando proibido: " + sorted(denied)[0])
        objects = tuple(dict.fromkeys(x.upper().split(".")[-1] for x in self.SOURCE_RE.findall(clean)))
        if not objects:
            raise SqlRejected("A consulta não possui fonte identificável.")
        allowed = {x.upper() for x in whitelist}
        unexpected = [x for x in objects if x not in allowed]
        if unexpected:
            raise SqlRejected("Objeto não autorizado: " + unexpected[0])
        return ValidatedSql(sql=sql.strip(), referenced_objects=objects)

    @staticmethod
    def _strip_comments_and_literals(sql: str) -> str:
        out: list[str] = []
        i = 0
        while i < len(sql):
            if sql.startswith("--", i):
                raise SqlRejected("Comentários SQL são proibidos no modo conservador.")
            elif sql.startswith("/*", i):
                raise SqlRejected("Comentários SQL são proibidos no modo conservador.")
            elif sql[i] == "'":
                out.append("''")
                i += 1
                while i < len(sql):
                    if sql[i] == "'":
                        if i + 1 < len(sql) and sql[i + 1] == "'":
                            i += 2
                            continue
                        i += 1
                        break
                    i += 1
                else:
                    raise SqlRejected("Literal não terminado.")
            else:
                out.append(sql[i])
                i += 1
        return "".join(out)


def validate_context(context: dict) -> None:
    required = ("user_code", "company_code", "branch_code", "allowed_branch_codes", "erp_version")
    missing = [name for name in required if not context.get(name)]
    if missing:
        raise ValueError("Contexto incompleto: " + ", ".join(missing))
    branches = {str(x) for x in context["allowed_branch_codes"]}
    if str(context["branch_code"]) not in branches:
        raise PermissionError("Filial atual não autorizada no contexto.")
