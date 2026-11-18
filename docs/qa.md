[← Project overview](../README.md#qa--validation) · [SQL results](../sql/RESULTS.md) · [Automated runs](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/actions/workflows/ci.yml)

# QA and validation evidence

The public demo has **13 SQL data-quality controls and 23 automated test methods**. The original nine controls cover source, join, date, amount and lifecycle risks; four additional controls reconcile the star-schema fact and dimensions. The controls are exercised by SQL tests and are not additional test-method counts.

## Verification record

| Item | Recorded evidence |
|---|---|
| Local verification date | 22 September 2026 |
| Code and fixture baseline | [`fddd8b9`](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/commit/fddd8b9a668f5d7c4cb62defddce430329be6cf6) |
| Local environment | Python 3.12, with the repository's `requirements.txt` installed |
| Automated suite result | Dated baseline below: `Ran 21 tests` / `OK`; current suite adds two star-schema tests and is expected to run 23 methods in CI |
| SQL control result | Dated baseline: original 9 controls returned zero issues; current code adds 4 star-schema controls |
| Reconciliation | 48 raw, 48 staged, 48 accepted and 48 matched fact rows; 30 customers; 6 hotels |
| Lifecycle fixture | 6 customers in each of New, Loyal, One-time, Lapsed and Won back |
| Committed results | `test_committed_results_snapshot_is_current` passed: fresh output matches `sql/RESULTS.md` |
| CI evidence for this baseline | [Successful run, 18 September 2026](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/actions/runs/35292175335) |

This is a dated verification record. The [workflow history](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/actions/workflows/ci.yml) and README badge show subsequent runs. All fixture identities and amounts are synthetic; these counts are not business results.

## SQL control register

The implementation is in [`sql/04_quality_checks.sql`](../sql/04_quality_checks.sql); recorded counts are in [`sql/RESULTS.md`](../sql/RESULTS.md#data-quality-checks). Every control is expected to return **0** for the clean fixture.

| Control | Risk addressed | What a nonzero count means |
|---|---|---|
| `normalized_hotel_key_collision` | A normalised hotel key joins to multiple dimension rows | Number of hotel-key groups containing more than one row |
| `duplicate_reservation_number` | A reservation is repeated | Number of reservation-number groups containing more than one row |
| `missing_customer_or_hotel_key` | A source row cannot support customer or hotel analysis | Reservation rows with a null or blank customer/hotel key |
| `accepted_hotel_not_matched` | An accepted reservation loses its hotel match | Accepted reservation rows without a matching staged hotel |
| `accepted_row_lost_or_multiplied` | The join changes the number of accepted rows | Absolute difference between accepted source-row and fact-row counts |
| `booking_after_arrival` | Booking timing contradicts arrival timing | Fact rows whose booking date is later than arrival |
| `stay_length_not_reconciled` | Recorded nights disagree with the date span | Fact rows whose departure-minus-arrival days differ from nights |
| `balance_not_reconciled` | Total, payment and balance disagree | Fact rows where the absolute difference between total minus paid and balance exceeds 0.01 |
| `customer_not_classified` | Lifecycle logic leaves a customer outside the defined groups | Customer rows classified as `Unclassified` |

Counts have different units and can overlap. Adding them does not give the number of unique bad customers or reservations. The row-count reconciliation is an aggregate check, not a reservation-by-reservation lineage comparison.

## Star-schema control register

The implementation is also in [`sql/04_quality_checks.sql`](../sql/04_quality_checks.sql) under `star_schema_quality_checks`.

| Control | Risk addressed | What a nonzero count means |
|---|---|---|
| `star_fact_row_count_mismatch` | The new fact changes the accepted reservation grain | Absolute difference between accepted staged rows and booking fact rows |
| `fact_customer_dimension_not_matched` | A booking has no customer dimension row | Fact rows whose customer key cannot be resolved |
| `fact_hotel_dimension_not_matched` | A booking has no hotel dimension row | Fact rows whose hotel key cannot be resolved |
| `fact_booking_date_dimension_not_matched` | A booking date cannot join to the date dimension | Fact rows whose booking date key is missing from `dim_date` |

## Automated test coverage

| Source | Methods | Assertions covered |
|---|---:|---|
| [`tests/test_demo.py`](../tests/test_demo.py) | 6 | Required model workbooks, sheets and source columns exist; related keys match; the data-folder parameter follows a relocated repository with spaces and Turkish characters; DAX field-parameter references point to existing columns; repeat setup produces identical sample values; an existing non-demo workbook is preserved |
| [`tests/test_sql_demo.py`](../tests/test_sql_demo.py) | 6 | Expected five-segment distribution; raw/staging/fact reconciliation; star-schema grain; zero issues across thirteen SQL controls; exact agreement between regenerated and committed results |
| [`tests/test_regressions.py`](../tests/test_regressions.py), `MoneyParsingTests` | 6 | Negative, positive, zero, grouped and decimal currency values; rejection of missing/invalid/nonfinite inputs; preservation of signed amounts and reservation text identifiers in Excel output |
| [`tests/test_regressions.py`](../tests/test_regressions.py), `ApiKeyTests` | 5 | Project-local configuration from another working directory; environment-key precedence; operation without a local configuration file; clear errors for missing or empty keys |

Several methods use multiple subcases; **21 counts methods**, not every input variation. API-key tests use temporary files and placeholder keys. They do not make API requests. Excel identifier preservation is tested for the Python merger output; it is not a claim that the SQL staging layer preserves identifier formatting.

## Reproduce the checks

From the repository root:

```bash
python -m pip install -r requirements.txt
python -m unittest discover -s tests -p "test_*.py" -v
python sql/run_demo.py
```

Expected results are `Ran 23 tests` / `OK`, followed by SQL output ending in `PASS: all SQL and star-schema quality checks returned zero issues.` The SQL runner generates workbooks in a temporary folder and uses an in-memory SQLite database.

The [CI workflow](../.github/workflows/ci.yml) installs the dependencies and runs the complete suite on Ubuntu with Python 3.12 for pushes to `main`, pull requests and manual dispatches. A failing test fails the job.

## Coverage limits and remaining work

- **SQL bad-data scenarios:** all thirteen controls are currently checked against the clean fixture. Separate regressions that inject each relevant fault and assert its detection are not yet implemented. Invalid currency inputs are covered separately in the Python money-parsing tests.
- **Date and amount completeness:** the SQL comparisons operate on staged values. They do not comprehensively validate missing or unparseable dates and amounts; null values can escape comparison-based checks.
- **Power BI execution:** the SQL star schema is a portfolio companion and is not yet the source of the PBIP semantic model. Source-reference checks do not execute Power Query or DAX. A successful Desktop refresh, measure-by-measure comparison and visual/filter review have no signed QA record in this repository.
- **Geocoding:** key configuration is tested. Live match accuracy, HTTP retry behaviour and coordinate validity are outside this suite.
- **Operational acceptance:** the tests do not validate private company data, user sign-off, recommendation usage, conversion or revenue impact. Operational reports refresh manually.
- **Model assumptions:** customer identity is name-based and lifecycle windows are fixed to 2026. These limits remain even when the synthetic tests pass; see the [decision workflow](decision-workflow.md#sources-units-of-analysis-and-constraints).

Future manual verification should record the date, reviewer, model/version, sample and filter context, expected versus observed result, and any unresolved issue. The first entries should cover Desktop refresh, KPI agreement, lifecycle filters, customer drill-down and hotel/map behaviour. These are proposed checks, not completed acceptance evidence.

## Maintaining this record

When code or fixtures change, rerun the suite and update the baseline, counts and coverage notes. If an intended calculation change affects the snapshot, review the new output before running `python sql/run_demo.py --write-results`, then rerun the suite. Do not treat a regenerated snapshot alone as proof that the business definition is correct.
