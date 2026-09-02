import tempfile
import unittest
from pathlib import Path

from erp_ia.database import Database
from erp_ia.knowledge import KnowledgeCenter, chunk_text


class KnowledgeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.db = Database(Path(self.temp.name) / "test.db")
        self.db.initialize()
        self.center = KnowledgeCenter(self.db)
        self.module_id = self.center.create_module("Financeiro")

    def tearDown(self):
        self.temp.cleanup()

    def test_pending_document_is_not_searchable_until_approval(self):
        document_id = self.center.submit_document(
            module_id=self.module_id, subject="Baixa", description="", keywords="",
            author="tester", content_type="text/markdown",
            content="A rotina de baixa exige a conferência do portador.",
        )
        self.assertEqual([], self.center.search("conferência portador", "Financeiro", 5, 10000))
        self.center.approve(document_id, "approver")
        hits = self.center.search("conferência portador", "Financeiro", 5, 10000)
        self.assertEqual(1, len(hits))
        self.assertEqual(document_id, hits[0].source_id)

    def test_rejects_pdf_until_extractor_is_configured(self):
        with self.assertRaises(ValueError):
            self.center.submit_document(module_id=self.module_id, subject="X", description="",
                keywords="", author="x", content_type="application/pdf", content="bytes")

    def test_chunking_respects_large_content(self):
        chunks = chunk_text("A" * 5000, target_chars=1000, overlap_chars=100)
        self.assertGreaterEqual(len(chunks), 5)


if __name__ == "__main__":
    unittest.main()
