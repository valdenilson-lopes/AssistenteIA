from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from .security import ConservativeSelectValidator


class ReadOnlyQueryExecutor(Protocol):
    """Adaptador a implementar com Oracle/FireDAC ou infraestrutura corporativa."""
    def execute(self, sql: str, binds: dict[str, object], timeout_seconds: int,
                max_rows: int) -> list[dict]: ...


@dataclass(frozen=True)
class KnownOperation:
    name: str
    module: str
    description: str
    sql: str
    allowed_views: frozenset[str]
    required_parameters: frozenset[str]
    branch_parameter: str = "codfilial"


class ToolCatalog:
    def __init__(self, executor: ReadOnlyQueryExecutor | None, timeout_seconds: int = 15,
                 max_rows: int = 200):
        self.executor = executor
        self.timeout_seconds = timeout_seconds
        self.max_rows = max_rows
        self.validator = ConservativeSelectValidator()
        self._operations: dict[str, KnownOperation] = {}

    def register(self, operation: KnownOperation) -> None:
        if operation.name in self._operations:
            raise ValueError("Operação já registrada: " + operation.name)
        self.validator.validate(operation.sql, set(operation.allowed_views))
        if ":" + operation.branch_parameter.lower() not in operation.sql.lower():
            raise ValueError("A operação não possui bind obrigatório de filial.")
        self._operations[operation.name] = operation

    def execute(self, name: str, parameters: dict[str, object], allowed_branches: set[str]) -> list[dict]:
        operation = self._operations.get(name)
        if not operation:
            raise PermissionError("Ferramenta inexistente ou não habilitada.")
        if self.executor is None:
            raise RuntimeError("Executor de dados vivos não configurado.")
        missing = operation.required_parameters.difference(parameters)
        if missing:
            raise ValueError("Parâmetro obrigatório ausente: " + sorted(missing)[0])
        branch = str(parameters.get(operation.branch_parameter, ""))
        if branch not in allowed_branches:
            raise PermissionError("Filial não autorizada para a operação.")
        validated = self.validator.validate(operation.sql, set(operation.allowed_views))
        rows = self.executor.execute(validated.sql, parameters, self.timeout_seconds, self.max_rows)
        return rows[: self.max_rows]

    def definitions(self) -> list[dict]:
        return [{"name": x.name, "module": x.module, "description": x.description,
                 "read_only": True} for x in self._operations.values()]
