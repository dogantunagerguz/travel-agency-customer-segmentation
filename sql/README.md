# SQL portfolio companion

This companion loads the **same fully synthetic Excel workbooks used by the public Power BI project**, lands them in raw SQLite tables, standardizes them in staging views, and builds decision-facing marts. It does **not** imply that SQL was part of the original production workflow and does not reproduce private data or operational totals.

[View the executed result snapshot](RESULTS.md)

[Review the SQL data dictionary](DATA_DICTIONARY.md)

## What this demonstrates

- source-to-mart lineage: Excel → `raw_*` → `stg_*` → `fct_*` / KPI views
- fixed-window 2026 customer lifecycle segmentation with `CASE`
- customer value and recency calculations
- joins at an explicit customer/reservation/hotel grain
- Turkish-character hotel-key normalization before the fact-to-dimension join
- `LAG` and `DENSE_RANK` window functions
- guarded treatment of accepted bookings versus refunds
- referential, date, amount, balance and classification quality checks

## Run

Run the repository's normal demo setup first only if you want to open Power BI. The SQL runner independently generates those same workbooks in a temporary folder, loads them with `openpyxl`, and executes SQLite in memory.

```bash
python sql/run_demo.py
```

Refresh the committed evidence snapshot with `python sql/run_demo.py --write-results`. A successful run ends with `PASS: all SQL data-quality checks returned zero issues.` The reference windows intentionally match the published model: 2026, 2025 and before 2025.

## Files

| File | Purpose |
|---|---|
| `01_raw_schema.sql` | landing tables matching the generated workbooks |
| `02_staging.sql` | type, key and date standardization plus the reservation fact join |
| `03_marts.sql` | segmentation, value, monthly KPI and recommendation marts |
| `04_quality_checks.sql` | row-loss, join, date, balance and classification controls |
| `run_demo.py` | source generation, loading, execution and result rendering |
| `RESULTS.md` | committed output generated from the runnable pipeline |
| `DATA_DICTIONARY.md` | relation grains, keys and metric interpretation |
