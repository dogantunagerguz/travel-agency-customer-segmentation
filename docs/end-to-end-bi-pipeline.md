# End-to-end BI pipeline

[← Project overview](../README.md) · [SQL companion](../sql/README.md) · [QA evidence](qa.md)

This page explains the portfolio pipeline at a junior BI / data analyst level. It separates implemented evidence from deployment steps that are only documented.

## Implemented flow

```text
Synthetic Excel sources
        ↓
Raw SQLite landing tables
        ↓
Staging views: types, dates and normalized business keys
        ↓
Star schema: dim_customer, dim_hotel, dim_date, fct_booking
        ↓
Decision marts and KPI views
        ↓
Power BI semantic model, DAX measures and report pages
        ↓
Manual Desktop refresh for the public demo
```

The public demo is reproducible and contains no private customer, booking or credential data.

## Layer responsibilities

| Layer | Implemented evidence | Junior-level responsibility demonstrated |
|---|---|---|
| Source | Synthetic Excel workbooks shaped like the operational extracts | Identify source grain and required columns |
| Raw | `raw_hotels`, `raw_reservations` | Land source values before applying business rules |
| Staging | `stg_hotels`, `stg_reservations` | Convert dates and amounts; standardize customer and hotel keys |
| Star schema | `dim_customer`, `dim_hotel`, `dim_date`, `fct_booking` | Separate descriptive attributes from reservation events |
| Marts | lifecycle, customer value, monthly KPIs, recommendation signals | Translate business questions into reusable datasets |
| Semantic model | PBIP/TMDL model, relationships and DAX measures | Build report logic and KPIs |
| QA | original nine SQL controls, four star-schema controls and automated tests | Reconcile row counts, joins, dates, balances and classifications |
| Refresh | local setup script and Power BI Desktop Refresh | Rebuild the public demo from generated sources |

## Star-schema grain

- **`fct_booking`:** one accepted reservation.
- **`dim_customer`:** one normalized customer key. The public demo uses a name-based key, which is a known limitation.
- **`dim_hotel`:** one normalized hotel key.
- **`dim_date`:** one distinct booking, arrival or departure date used by the fact.

The fact stores foreign keys and numeric measures. Customer, hotel and calendar descriptions remain in dimensions. The existing `fct_reservations` view is retained for backward compatibility with earlier portfolio outputs.

## Quality gates

A successful SQL run requires both groups to return zero issues:

1. the original nine source, join, date, amount and lifecycle controls;
2. four star-schema checks covering fact grain and customer, hotel and booking-date relationships.

Run:

```bash
python sql/run_demo.py
python -m unittest discover -s tests -p "test_*.py" -v
```

GitHub Actions executes the automated suite on pushes and pull requests.

## Power BI Service boundary

The repository demonstrates Power BI Desktop Import-mode refresh. It does **not** claim that this public project is deployed to Power BI Service.

A future Service deployment would require:

1. publish the semantic model and report to a workspace;
2. replace local file paths with SharePoint/OneDrive or another supported source;
3. configure credentials and, where required, a gateway;
4. define a scheduled refresh;
5. record refresh history and investigate failed refreshes;
6. reconcile Service KPIs against the SQL results after refresh.

These are deployment steps, not completed evidence in this repository.

## Skills demonstrated

Power BI · Power Query · DAX · SQL/SQLite · dimensional modelling · KPI design · data-quality checks · Python test automation · Git/GitHub Actions

The scope is intentionally junior: the project demonstrates an understandable and testable BI pipeline without claiming enterprise orchestration, Fabric, dbt, production database administration or cloud deployment.
