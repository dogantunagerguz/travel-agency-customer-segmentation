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
            "New": 1,
            "Loyal": 2,
            "One-time": 1,
            "Lapsed": 1,
            "Won back": 1,
        })

    def test_refund_does_not_change_lifecycle_or_customer_value(self):
        row = self.connection.execute("""
            SELECT l.lifecycle_segment, v.booking_frequency, v.lifetime_value
            FROM customer_lifecycle_2026 AS l
            JOIN customer_value_2026 AS v USING (customer_id)
            WHERE l.customer_id = 1
        """).fetchone()
        self.assertEqual(tuple(row), ("New", 1, 5000))

    def test_2026_total_is_reconciled(self):
        row = self.connection.execute("""
            SELECT SUM(bookings), SUM(booked_revenue)
            FROM monthly_booking_kpis
            WHERE booking_month LIKE '2026-%'
        """).fetchone()
        self.assertEqual(tuple(row), (4, 21300))

    def test_all_quality_checks_pass(self):
        failures = self.connection.execute("""
            SELECT check_name FROM quality_check_results WHERE issue_count <> 0
        """).fetchall()
        self.assertEqual(failures, [])


if __name__ == "__main__":
    unittest.main()

