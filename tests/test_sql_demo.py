import sqlite3
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from openpyxl import load_workbook

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sql"))
import run_demo  # noqa: E402


class SqlPortfolioDemoTests(unittest.TestCase):
    def setUp(self):
        self.connection = run_demo.build_connection()

    def tearDown(self):
        self.connection.close()

    def quality_issues(self):
        return dict(self.connection.execute("""
            SELECT check_name, issue_count
            FROM quality_check_results
            WHERE issue_count <> 0
        """).fetchall())

    def assert_rejected(self, source_row_id, *expected_reasons):
        reasons = self.connection.execute("""
            SELECT reason FROM reservation_rejection_reasons WHERE source_row_id = ?
        """, (source_row_id,)).fetchall()
        self.assertCountEqual([row["reason"] for row in reasons], expected_reasons)
        audit = self.connection.execute("""
            SELECT expected_outcome, fact_rows, is_consistent
            FROM reservation_reconciliation WHERE source_row_id = ?
        """, (source_row_id,)).fetchone()
        self.assertEqual(tuple(audit), ("rejected", 0, 1))

    def demo_workbooks(self):
        directory = TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        folder = Path(directory.name)
        run_demo.load_setup_module().build_data(folder)
        return folder

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

    def test_duplicate_reservation_number_rejects_both_source_rows(self):
        self.connection.execute("UPDATE raw_reservations SET reservation_no = '100001' WHERE source_row_id = 2")
        self.assertEqual(self.quality_issues(), {"duplicate_reservation_number": 1})
        self.assert_rejected(1, "duplicate_reservation_number")
        self.assert_rejected(2, "duplicate_reservation_number")

    def test_missing_keys_and_unmatched_hotel_show_distinct_reasons(self):
        self.connection.executescript("""
            UPDATE raw_reservations SET customer_name = '  ' WHERE source_row_id = 1;
            UPDATE raw_reservations SET hotel_name = NULL WHERE source_row_id = 2;
            UPDATE raw_reservations SET hotel_name = 'UNKNOWN DEMO HOTEL' WHERE source_row_id = 3;
            UPDATE raw_reservations SET reservation_no = ' ' WHERE source_row_id = 4;
        """)
        self.assertEqual(self.quality_issues(), {
            "missing_customer_or_hotel_key": 2,
            "accepted_hotel_not_matched": 1,
            "missing_reservation_number": 1,
        })
        self.assert_rejected(1, "missing_customer_or_hotel_key")
        self.assert_rejected(2, "missing_customer_or_hotel_key")
        self.assert_rejected(3, "accepted_hotel_not_matched")
        self.assert_rejected(4, "missing_reservation_number")

    def test_normalized_hotel_collision_does_not_multiply_reservations(self):
        self.connection.executescript("""
            UPDATE raw_hotels SET source_hotel_name = 'GÜRAL DEMO'
            WHERE source_hotel_name = 'DEMO HOTEL 01';
            UPDATE raw_reservations SET hotel_name = 'GÜRAL DEMO'
            WHERE hotel_name = 'DEMO HOTEL 01';
            INSERT INTO raw_hotels (source_hotel_name) VALUES ('GURAL DEMO');
        """)
        self.assertEqual(self.quality_issues(), {"normalized_hotel_key_collision": 1})
        self.assert_rejected(1, "ambiguous_hotel_match")
        self.assertFalse(self.connection.execute("""
            SELECT 1 FROM fct_reservations WHERE hotel_key = 'GURAL DEMO'
        """).fetchone())

    def test_missing_malformed_and_impossible_dates_stay_out_of_kpis(self):
        invalid = [
            ("transaction_date", None),
            ("transaction_date", "not a date"),
            ("transaction_date", "2026-02-30"),
            ("arrival_serial", "bad serial"),
            ("departure_serial", 46000.5),
            ("arrival_serial", 60),
        ]
        for source_row_id, (column, value) in enumerate(invalid, 1):
            self.connection.execute(
                f"UPDATE raw_reservations SET {column} = ? WHERE source_row_id = ?",
                (value, source_row_id),
            )
        self.assertEqual(self.quality_issues(), {"invalid_date": len(invalid)})
        for source_row_id in range(1, len(invalid) + 1):
            with self.subTest(source_row_id=source_row_id):
                self.assert_rejected(source_row_id, "invalid_date")

    def test_date_order_and_nights_are_validated(self):
        self.connection.executescript("""
            UPDATE raw_reservations SET transaction_date = '2026-12-31' WHERE source_row_id = 1;
            UPDATE raw_reservations SET nights = nights + 1 WHERE source_row_id = 2;
            UPDATE raw_reservations SET nights = NULL WHERE source_row_id = 3;
        """)
        self.assertEqual(self.quality_issues(), {
            "booking_after_arrival": 1,
            "stay_length_not_reconciled": 2,
        })
        self.assert_rejected(1, "booking_after_arrival")
        self.assert_rejected(2, "stay_length_not_reconciled")
        self.assert_rejected(3, "stay_length_not_reconciled")

    def test_missing_and_invalid_amounts_are_kept_out_with_all_reasons(self):
        self.connection.executescript("""
            UPDATE raw_reservations SET total_amount = '1.250,50', transaction_date = NULL
            WHERE source_row_id = 1;
            UPDATE raw_reservations SET paid_amount = NULL WHERE source_row_id = 2;
            UPDATE raw_reservations SET balance_amount = 1 WHERE source_row_id = 3;
        """)
        self.connection.execute(
            "UPDATE raw_reservations SET balance_amount = ? WHERE source_row_id = 4", (float("inf"),)
        )
        self.assertEqual(self.quality_issues(), {
            "invalid_amount": 3,
            "invalid_date": 1,
            "balance_not_reconciled": 1,
        })
        self.assert_rejected(1, "invalid_amount", "invalid_date")
        self.assert_rejected(2, "invalid_amount")
        self.assert_rejected(3, "balance_not_reconciled")
        self.assert_rejected(4, "invalid_amount")

    def test_refund_is_excluded_and_a_text_reservation_number_keeps_its_zeros(self):
        self.connection.executescript("""
            UPDATE raw_reservations SET acceptance_status = 'Refund' WHERE source_row_id = 1;
            UPDATE raw_reservations SET reservation_no = '00100002' WHERE source_row_id = 2;
        """)
        rows = self.connection.execute("""
            SELECT expected_outcome, fact_rows, fact_reservation_no, is_consistent
            FROM reservation_reconciliation WHERE source_row_id IN (1, 2)
            ORDER BY source_row_id
        """).fetchall()
        self.assertEqual([tuple(row) for row in rows], [
            ("excluded_by_status", 0, None, 1),
            ("included", 1, "00100002", 1),
        ])
        self.assertEqual(self.quality_issues(), {})

    def test_row_audit_detects_offsetting_row_loss_and_duplication(self):
        self.connection.executescript("""
            CREATE TABLE example_fact AS SELECT * FROM fct_reservations;
            DROP VIEW fct_reservations;
            CREATE VIEW fct_reservations AS
                SELECT * FROM example_fact WHERE source_row_id <> 1
                UNION ALL
                SELECT * FROM example_fact WHERE source_row_id = 2;
        """)
        self.assertEqual(self.connection.execute("SELECT COUNT(*) FROM fct_reservations").fetchone()[0], 48)
        self.assertEqual(self.quality_issues(), {"reservation_lineage_mismatch": 2})
        rows = self.connection.execute("""
            SELECT source_row_id, fact_rows FROM reservation_reconciliation
            WHERE is_consistent = 0 ORDER BY source_row_id
        """).fetchall()
        self.assertEqual([tuple(row) for row in rows], [(1, 0), (2, 2)])

    def test_row_audit_detects_orphan_output_and_changed_reservation_number(self):
        self.connection.executescript("""
            CREATE TABLE example_fact AS SELECT * FROM fct_reservations;
            UPDATE example_fact SET source_row_id = 999 WHERE source_row_id = 1;
            UPDATE example_fact SET reservation_no = 'WRONG-ID' WHERE source_row_id = 2;
            DROP VIEW fct_reservations;
            CREATE VIEW fct_reservations AS SELECT * FROM example_fact;
        """)
        rows = self.connection.execute("""
            SELECT source_row_id, expected_outcome FROM reservation_reconciliation
            WHERE is_consistent = 0 ORDER BY source_row_id
        """).fetchall()
        self.assertEqual([tuple(row) for row in rows], [(1, "included"), (2, "included"), (999, "orphan_output")])

    def test_future_only_customer_is_flagged_outside_lifecycle_windows(self):
        self.connection.execute("""
            UPDATE raw_reservations SET
                transaction_date = '2027-01-01',
                arrival_serial = CAST(julianday('2027-02-01') - julianday('1899-12-30') AS INTEGER),
                departure_serial = CAST(julianday('2027-02-01') - julianday('1899-12-30') AS INTEGER) + nights
            WHERE source_row_id = 1
        """)
        self.assertEqual(self.quality_issues(), {"customer_not_classified": 1})

    def test_segment_kpis_count_customer_key_once_despite_name_case_variation(self):
        self.connection.execute("""
            UPDATE raw_reservations SET customer_name = LOWER(customer_name)
            WHERE source_row_id = 2
        """)
        loyal = self.connection.execute("""
            SELECT customers, repeat_customers, repeat_customer_rate_pct, average_booked_value
            FROM segment_booking_kpis_2026 WHERE lifecycle_segment = 'Loyal'
        """).fetchone()
        self.assertEqual(tuple(loyal), (6, 6, 100.0, 16913.33))

    def test_monthly_change_requires_an_adjacent_calendar_month(self):
        initial = self.connection.execute("""
            SELECT source_row_id, total_amount FROM fct_reservations
            WHERE booking_date = '2026-05-01' ORDER BY source_row_id LIMIT 1
        """).fetchone()
        self.connection.execute("""
            UPDATE raw_reservations SET transaction_date = '2026-03-01' WHERE source_row_id = ?
        """, (initial["source_row_id"],))
        months = dict(self.connection.execute("""
            SELECT booking_month, revenue_change_vs_previous_month FROM monthly_booking_kpis
            WHERE booking_month IN ('2026-03', '2026-05')
        """).fetchall())
        self.assertEqual(months, {"2026-03": initial["total_amount"] - 43240.0, "2026-05": None})

    def test_reloading_same_workbooks_does_not_duplicate_rows(self):
        folder = self.demo_workbooks()
        before = run_demo.render_results(self.connection)
        run_demo.load_workbooks(self.connection, folder)
        run_demo.load_workbooks(self.connection, folder)
        self.assertEqual(run_demo.render_results(self.connection), before)

    def test_reloading_a_changed_booking_replaces_its_amount(self):
        folder = self.demo_workbooks()
        path = folder / "Travel-Mock.xlsx"
        book = load_workbook(path)
        try:
            new_amount = book.active["K2"].value + 100
            book.active["K2"] = new_amount
            book.active["L2"] = new_amount
            book.save(path)
        finally:
            book.close()
        run_demo.load_workbooks(self.connection, folder)
        facts = self.connection.execute("""
            SELECT total_amount FROM fct_reservations WHERE reservation_no = '100001'
        """).fetchall()
        self.assertEqual([row["total_amount"] for row in facts], [new_amount])
        self.assertEqual(self.quality_issues(), {})

    def test_reload_with_broken_header_preserves_current_workbooks(self):
        folder = self.demo_workbooks()
        path = folder / "Travel-Mock.xlsx"
        book = load_workbook(path)
        try:
            book.active["K1"] = "unexpected column"
            book.save(path)
        finally:
            book.close()
        before = run_demo.render_results(self.connection)
        with self.assertRaisesRegex(ValueError, "Toplam"):
            run_demo.load_workbooks(self.connection, folder)
        self.assertEqual(run_demo.render_results(self.connection), before)

    def test_partial_reload_failure_rolls_back_both_tables(self):
        folder = self.demo_workbooks()
        path = folder / "Hotels-Mock.xlsx"
        book = load_workbook(path)
        try:
            book.active["C2"] = "Changed city"
            book.save(path)
        finally:
            book.close()
        self.connection.executescript("""
            CREATE TRIGGER fail_reload BEFORE INSERT ON raw_reservations
            WHEN NEW.reservation_no = '100002'
            BEGIN
                SELECT RAISE(ABORT, 'simulated import failure');
            END;
        """)
        before = run_demo.render_results(self.connection)
        with self.assertRaisesRegex(sqlite3.IntegrityError, "simulated import failure"):
            run_demo.load_workbooks(self.connection, folder)
        self.assertEqual(run_demo.render_results(self.connection), before)
        city = self.connection.execute("""
            SELECT city FROM raw_hotels WHERE source_hotel_name = 'DEMO HOTEL 01'
        """).fetchone()["city"]
        self.assertEqual(city, "Antalya")


if __name__ == "__main__":
    unittest.main()
