# SQL portfolio companion

These SQL files implement equivalent analytical logic for portfolio review on a small, fully synthetic dataset. They do **not** imply that SQL was part of the original production workflow, and they do not reproduce private data or the operational dashboard totals.

## What this demonstrates

- fixed-window 2026 customer lifecycle segmentation with `CASE`
- customer value and recency calculations
- joins at an explicit customer/reservation/hotel grain
- `LAG` and `DENSE_RANK` window functions
- guarded treatment of accepted bookings versus refunds
- referential, date, amount, balance and classification quality checks

## Run

Python 3 is the only requirement; the runner uses the standard-library SQLite engine.

```bash
python sql/run_demo.py
```

A successful run ends with `PASS: all SQL data-quality checks returned zero issues.` The fixture produces six classified customers: one New, two Loyal, one One-time, one Lapsed and one Won back. The reference windows intentionally match the published model: 2026, 2025 and before 2025.

## Files

| File | Purpose |
|---|---|
| `01_demo_schema_and_seed.sql` | normalized schema and invented records |
| `02_analysis.sql` | segmentation, customer value, monthly KPI and recommendation views |
| `03_data_quality.sql` | auditable checks; zero issues is the expected result |
| `run_demo.py` | reproducible top-to-bottom execution and bounded result preview |

