# SQL portfolio companion

This SQLite companion uses the same synthetic Excel workbooks as the public Power BI project. It shows how each reservation moves from source data to reporting and records why a row was rejected.

[View the executed result snapshot](RESULTS.md)

[Review the SQL data dictionary](DATA_DICTIONARY.md)

[QA control register, test coverage and verification record](../docs/qa.md)

## How the data moves

1. Python reads the reservation and hotel workbooks into SQLite. A reload replaces both raw tables in one transaction.
2. Staging trims keys, standardizes hotel names and validates dates and monetary fields. Reservation numbers stay as text so leading zeros survive.
3. An accepted reservation reaches the reporting rows when its number is unique among accepted bookings, it matches exactly one hotel, and it passes the field checks. The rejection view shows one row per reason for each rejected booking. Other statuses, such as refunds, are excluded by the reporting rule.
4. The reservation audit compares each source row with the reporting rows. It checks that included reservations appear once with the same reservation number and that rejected and excluded rows have zero matches.
5. The KPI queries report customer lifecycle, repeat bookings and average booked value by segment. `DENSE_RANK` ranks customers by value. `LAG` supports monthly change when the preceding calendar month is also present in the data.

## How to explain it in an interview

> I loaded two sample Excel files into SQLite with Python. Before counting a booking, I checked that it had one hotel match and valid dates and amounts. I kept a reason for every rejected booking. Then I checked each source reservation individually. In one test I removed a reservation from the output and duplicated another. The total stayed the same, but the row audit found both problems.

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
| `02_staging.sql` | key, date and amount validation, rejection reasons, and the reservation fact join |
| `03_marts.sql` | segmentation, value, monthly KPI and recommendation marts |
| `04_quality_checks.sql` | reservation audit and quality control counts |
| `run_demo.py` | workbook generation, snapshot replacement, execution and result rendering |
| `RESULTS.md` | committed output generated from the runnable pipeline |
| `DATA_DICTIONARY.md` | relation grains, keys and metric interpretation |
