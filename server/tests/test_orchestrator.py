import tempfile
import unittest
from pathlib import Path

from erp_ia.config import Settings
from erp_ia.database import Database
from erp_ia.knowledge import KnowledgeCenter
from erp_ia.orchestrator import Orchestrator
from erp_ia.providers import ProviderResult


class FakeProvider:
    name = "fake"
    def answer(self, question, context):
        return ProviderResult("Resposta baseada na documentação.", 10, 5, 1, "fake-model")


class OrchestratorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "test.db"
        self.db = Database(path)
        self.db.initialize()
        self.knowledge = KnowledgeCenter(self.db)
        self.settings = Settings(database_path=path)
        self.orchestrator = Orchestrator(self.db, self.knowledge, FakeProvider(), self.settings)
        self.context = {"user_code": "u1", "company_code": "e1", "branch_code": "f1",
                        "allowed_branch_codes": ["f1"], "erp_version": "1"}

    def tearDown(self):
        self.temp.cleanup()

    def ask(self, question):
        return self.orchestrator.ask({"question": question, "context": self.context})

    def test_missing_knowledge_creates_demand(self):
        result = self.ask("Como funciona a rotina especial?")
        self.assertEqual("knowledge_insufficient", result["status"])
        self.assertTrue(result["knowledge_request_id"])

    def test_current_data_never_uses_document_as_live_value(self):
        result = self.ask("Quanto vendemos hoje?")
        self.assertEqual("knowledge_insufficient", result["status"])
        self.assertIn("ferramenta", result["answer"].lower())

    def test_external_question_is_refused(self):
        result = self.ask("Qual é a capital da França?")
        self.assertEqual("refused_out_of_scope", result["status"])
        self.assertIsNone(result["knowledge_request_id"])

    def test_approved_document_can_answer(self):
        module = self.knowledge.create_module("Fiscal")
        doc = self.knowledge.submit_document(module_id=module, subject="Emissão de nota",
            description="", keywords="", author="a", content_type="text/plain",
            content="Na rotina fiscal, a nota é conferida antes da emissão.")
        self.knowledge.approve(doc, "b")
        result = self.ask("Como a nota é conferida na rotina fiscal?")
        self.assertEqual("answered", result["status"])
        self.assertEqual(1, len(result["sources"]))


if __name__ == "__main__":
    unittest.main()
