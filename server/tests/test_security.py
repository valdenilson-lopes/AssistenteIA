import unittest

from erp_ia.security import ConservativeSelectValidator, SqlRejected, validate_context


class SecurityTests(unittest.TestCase):
    def setUp(self):
        self.validator = ConservativeSelectValidator()

    def test_accepts_single_whitelisted_select(self):
        result = self.validator.validate(
            "SELECT SUM(vrvenda) FROM BI_VENDA_FLYGESTOR WHERE codfilial=:codfilial",
            {"BI_VENDA_FLYGESTOR"},
        )
        self.assertEqual(("BI_VENDA_FLYGESTOR",), result.referenced_objects)

    def test_rejects_dml_obfuscated_by_comment(self):
        with self.assertRaises(SqlRejected):
            self.validator.validate("SEL/*x*/ECT * FROM X", {"X"})

    def test_rejects_second_statement(self):
        with self.assertRaises(SqlRejected):
            self.validator.validate("SELECT * FROM X; DELETE FROM X", {"X"})

    def test_rejects_non_whitelisted_object(self):
        with self.assertRaises(SqlRejected):
            self.validator.validate("SELECT * FROM SEGREDO", {"X"})

    def test_context_requires_current_branch_in_allowed_set(self):
        with self.assertRaises(PermissionError):
            validate_context({"user_code": "1", "company_code": "1", "branch_code": "2",
                              "allowed_branch_codes": ["1"], "erp_version": "x"})


if __name__ == "__main__":
    unittest.main()
