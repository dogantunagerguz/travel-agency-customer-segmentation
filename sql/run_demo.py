#!/usr/bin/env python3
"""Execute the self-contained SQL portfolio companion with Python stdlib."""

from pathlib import Path
import sqlite3

SQL_DIR = Path(__file__).resolve().parent
SQL_FILES = [
    "01_demo_schema_and_seed.sql",
    "02_analysis.sql",
    "03_data_quality.sql",
]
REPORTS = [
    ("Lifecycle distribution", """
        SELECT lifecycle_segment, COUNT(*) AS customers
        FROM customer_lifecycle_2026
        GROUP BY lifecycle_segment
        ORDER BY lifecycle_segment
    """),
    ("Customer value", """
        SELECT customer_name, booking_frequency, lifetime_value, value_rank
        FROM customer_value_2026
        ORDER BY value_rank, customer_name
    """),
    ("2026 monthly KPIs", """
        SELECT * FROM monthly_booking_kpis
        WHERE booking_month LIKE '2026-%'
        ORDER BY booking_month
    """),
    ("Data-quality checks", """
        SELECT * FROM quality_check_results ORDER BY check_name
    """),
]


def build_connection():
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    for filename in SQL_FILES:
        connection.executescript((SQL_DIR / filename).read_text(encoding="utf-8"))
    return connection


def print_rows(title, rows):
    print(f"\n{title}")
    if not rows:
        print("(no rows)")
        return
    columns = rows[0].keys()
    print(" | ".join(columns))
    for row in rows:
        print(" | ".join("" if row[column] is None else str(row[column]) for column in columns))


def main():
    connection = build_connection()
    try:
        for title, query in REPORTS:
            print_rows(title, connection.execute(query).fetchall())
        failures = connection.execute(
            "SELECT check_name, issue_count FROM quality_check_results WHERE issue_count <> 0"
        ).fetchall()
        if failures:
            raise SystemExit("SQL demo failed one or more data-quality checks.")
        print("\nPASS: all SQL data-quality checks returned zero issues.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()

