[Project overview](../README.md#qa--validation) · [SQL results](../sql/RESULTS.md) · [Automated runs](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/actions/workflows/ci.yml)

# QA and validation evidence

The synthetic demo has 12 SQL controls. Its clean run produces 48 reporting rows from 48 reservations, with 30 customers and 6 hotels. The automated suite compares a fresh run with the committed output and checks how the pipeline handles deliberately flawed records. [Clean output](../sql/RESULTS.md)

## Example of a missing row and a duplicate

The test removes source row 1 from the reporting output and adds a second copy of row 2. The output still contains 48 rows. The audit reports two inconsistencies.

| Source row | Expected reporting rows | Observed reporting rows |
|---:|---:|---:|
| 1 | 1 | 0 |
| 2 | 1 | 2 |

The audit starts from individual raw rows. It compares the expected outcome with the number and reservation number of the actual reporting rows. It also flags reporting rows with no source key. Accepted rows with bad data remain traceable in the rejection view. [Audit SQL](../sql/04_quality_checks.sql) · [Test cases](../tests/test_sql_demo.py)

## SQL controls

| Control | What it counts |
|---|---|
| `missing_reservation_number` | Accepted rows without a reservation number |
| `duplicate_reservation_number` | Reservation numbers repeated among accepted rows. All rows with that number are rejected. |
| `missing_customer_or_hotel_key` | Accepted rows with an empty customer or hotel key |
| `accepted_hotel_not_matched` | Accepted rows whose hotel key has no match |
| `normalized_hotel_key_collision` | Hotel keys shared by multiple dimension rows. Affected reservations are rejected with `ambiguous_hotel_match`. |
| `invalid_date` | Accepted rows with a missing or invalid booking, arrival or departure date |
| `booking_after_arrival` | Accepted rows where the booking date is after arrival |
| `stay_length_not_reconciled` | Accepted rows with invalid nights or a difference between recorded nights and the date span |
| `invalid_amount` | Accepted rows with missing, nonnumeric or nonfinite total, paid or balance amounts |
| `balance_not_reconciled` | Accepted rows where total minus paid and recorded balance differ by more than one cent after rounding |
| `reservation_lineage_mismatch` | Source rows with missing, repeated or mismatched output, plus output keys with no source row |
| `customer_not_classified` | Customers outside the fixed lifecycle rules, for example when their only booking falls after 2026 |

The counts can overlap because one source row can fail several checks. For example, an accepted row with an invalid date and a missing payment produces two rejection reasons and stays out of the KPI data. The runner exits with an error when any control reports an issue. [Rejection rules](../sql/02_staging.sql) · [Control counts](../sql/04_quality_checks.sql)

## Automated test coverage

| Tests | Methods | Coverage |
|---|---:|---|
| [Public demo](../tests/test_demo.py) | 6 | Workbook references, keys, relocation, repeatable sample values and preservation of existing files |
| [SQL demo](../tests/test_sql_demo.py) | 20 | Clean results, invalid fields, missing and duplicate matches, reservation audit, reloading and rollback, and KPI definitions |
| [Python regression tests](../tests/test_regressions.py) | 11 | Signed and locale-formatted amounts, Excel output and local key configuration with placeholders |

The reload tests repeat the same input, replace a changed amount and simulate both a bad header and a database failure during insertion. The database failure test verifies that both input tables return to their previous state.

## Reproduce the checks

From the repository root, install its requirements and run the tests and demo.

```bash
python -m pip install -r requirements.txt
python -m unittest discover -s tests -p 'test_*.py' -v
python sql/run_demo.py
```

The suite reports `Ran 37 tests` with `OK`. The demo ends with `PASS: all SQL data-quality checks returned zero issues.` GitHub Actions runs the same test suite on Python 3.12. [CI workflow](../.github/workflows/ci.yml)

## Scope

The SQL demo uses a fresh in-memory database and synthetic workbook contents. One source row ID identifies a row within one load. The model uses name-based customer keys and fixed 2026 lifecycle windows. It expects whole-day Excel serials for travel dates and ISO dates for bookings. The tests exercise the Python and SQLite code and check workbook references in the Power BI project. [SQL data dictionary](../sql/DATA_DICTIONARY.md) · [Decision workflow](decision-workflow.md)
