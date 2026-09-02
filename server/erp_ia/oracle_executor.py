from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class OracleConnectionSettings:
    user: str
    password: str
    dsn: str

    @property
    def configured(self) -> bool:
        return bool(self.user.strip() and self.password and self.dsn.strip())


class OracleReadOnlyExecutor:
    """Executor Oracle usado somente por SQL previamente validado e autorizado."""

    def __init__(self, settings: OracleConnectionSettings):
        self.settings = settings

    def execute(self, sql: str, binds: dict[str, object], timeout_seconds: int,
                max_rows: int) -> list[dict]:
        if not self.settings.configured:
            raise RuntimeError("Conexão Oracle da API não configurada.")

        try:
            import oracledb
        except ImportError as exc:
            raise RuntimeError(
                "Driver Oracle não instalado no Python. Instale o pacote 'oracledb'."
            ) from exc

        connection = oracledb.connect(
            user=self.settings.user,
            password=self.settings.password,
            dsn=self.settings.dsn,
        )
        try:
            connection.call_timeout = max(1, int(timeout_seconds)) * 1000
            cursor = connection.cursor()
            try:
                cursor.arraysize = min(max(1, max_rows), 200)
                cursor.execute(sql, binds)
                columns = [item[0].lower() for item in cursor.description or []]
                rows = cursor.fetchmany(max_rows)
                return [dict(zip(columns, row)) for row in rows]
            finally:
                cursor.close()
        finally:
            connection.close()
