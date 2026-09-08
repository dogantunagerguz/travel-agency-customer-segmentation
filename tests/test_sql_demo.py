import sys
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sql"))
import run_demo  # noqa: E402


class SqlPortfolioDemoTests(unittest.TestCase):
    def setUp(self):
        self.connection = run_demo.build_connection()

    def tearDown(self):
        self.connection.close()

    def test_lifecycle_distribution_matches_fixture(self):
        rows = self.connection.execute("""
            SELECT lifecycle_segment, COUNT(*)
            FROM customer_lifecycle_2026
            GROUP BY lifecycle_segment
        """).fetchall()
        self.assertEqual(dict(rows), {
            "New": 6,
            "Loyal": 6,
            "One-time": 6,
            "Lapsed": 6,
            "Won back": 6,
        })

    def test_pipeline_preserves_source_grain(self):
        row = self.connection.execute("""
            SELECT raw_reservations, staged_reservations, accepted_reservations,
                   matched_fact_rows, customers, hotels
            FROM pipeline_reconciliation
        """).fetchone()
        self.assertEqual(tuple(row), (48, 48, 48, 48, 30, 6))

    def test_all_quality_checks_pass(self):
        failures = self.connection.execute("""
            SELECT check_name FROM quality_check_results WHERE issue_count <> 0
        """).fetchall()
        self.assertEqual(failures, [])

    def test_committed_results_snapshot_is_current(self):
        expected = run_demo.render_results(self.connection)
        actual = (ROOT / "sql/RESULTS.md").read_text(encoding="utf-8")
        self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
