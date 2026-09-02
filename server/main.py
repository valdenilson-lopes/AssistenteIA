from erp_ia.config import Settings
from erp_ia.http_api import serve


if __name__ == "__main__":
    serve(Settings.from_env())
