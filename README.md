# Travel Agency Customer Segmentation

**Business question:** Who are our loyal customers, when do they book, and which hotels are relevant to the next sales conversation?

![Dashboard](assets/dashboard.png)

*Earlier Power BI export. The current model uses the shorter **Customers** KPI caption; [see the current model notes](docs/dashboard.md#insights).*

I started with the team's difficulty identifying loyal customers. I changed the export routine to recover booking-month information, resolved hotel-name and join-grain problems, and added lifecycle, lead-time and location views. Staff can use past booking patterns to narrow hotel suggestions across two travel-agency branches.

**Operational use:** Prepare the monthly exports, refresh the report manually, and review the customer profile and hotel history before a sales conversation.

**Tools:** Power BI · DAX · Power Query · SQL / SQLite (public companion) · Python · LocationIQ<br>
**Status:** In operational use; manually refreshed; source data remains private.

[Decision workflow and evidence](docs/decision-workflow.md) · [▶ Run the public demo](#run-the-public-demo) · [SQL companion](sql/) · [QA & validation](#qa--validation) · [Full story](docs/story.md)

## Run the public demo

The demo uses **fully synthetic data**, generated locally without private files, credentials, or API requests.

1. Download this repository (Code → Download ZIP) and extract it, or clone it.
2. Install Python 3.10+ and a current [Power BI Desktop for Windows with PBIP/TMDL support](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview).
3. Close the project in Power BI Desktop, then run these commands from the repository folder:

```bash
python -m pip install -r requirements.txt
python scripts/setup_demo.py
```

4. Open `Travel-Agency-Mock.pbip` and select **Refresh**.

The script creates sample workbooks in `demo-data/` and updates the local project's `DemoDataFolder` Power Query parameter. If you move the repository, close Power BI Desktop and rerun the setup command. For another sample-data location, use `python scripts/setup_demo.py --data-dir "path/to/demo-data"`, or edit `DemoDataFolder` under **Transform data → Manage Parameters**.

Python generates the files on Windows, macOS, or Linux; viewing the report requires Power BI Desktop for Windows. No Power BI Service workspace or cloud refresh setup is required. If a map requests an online map service, the remaining report pages can still be reviewed offline.

The sample uses a fixed **2026 reference year**, invented identities, and matching keys across related tables. Its totals differ from the original project's screenshots and operational figures. [View all dashboard pages and segmentation notes](docs/dashboard.md).

## SQL evidence

The SQLite companion uses **48 synthetic reservations, 30 customers and 6 hotels**. Python loads the two Excel sources. SQL checks dates, amounts and hotel matches, keeps a reason for each rejected reservation, and checks that every valid source reservation reaches the KPI data once. The resulting queries show repeat bookings, average booked value by segment and change from the previous calendar month. [SQL walkthrough](sql/README.md)

After installing the dependencies above, run it from the repository root:

```bash
python sql/run_demo.py
```

[Executed SQL results](sql/RESULTS.md) · [SQL data dictionary](sql/DATA_DICTIONARY.md)

## QA & Validation

[![Python and SQL tests](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/dogantunagerguz/travel-agency-customer-segmentation/actions/workflows/ci.yml)

**12 SQL controls and 37 automated tests.** All 48 clean reservations reach the output exactly once. A separate test removes one output row and duplicates another. The total stays at 48 and the reservation audit flags both rows. [Validation evidence](docs/qa.md#example-of-a-missing-row-and-a-duplicate)

| Test group | Tests | Coverage |
|---|---:|---|
| Demo sources and portability | 6 | Workbook/sheet/column references, related keys, relocation, repeatable sample values and preservation of existing files |
| SQL | 20 | Invalid input, reservation audit, repeat loads and rollback, customer and month KPIs, and result-snapshot consistency |
| Money parsing and API-key configuration | 11 | Signed and locale-formatted amounts, Excel output and local configuration using test-only keys |

After installing the dependencies, run the same suite as GitHub CI:

```bash
python -m unittest discover -s tests -p "test_*.py" -v
```

[QA record, control definitions and coverage limits](docs/qa.md) · [Executed SQL results](sql/RESULTS.md) · [Test source](tests/)

The tests exercise the Python/SQLite demo and verify the Power BI project's source references and demo setup.

For the business context, design decisions, operational limitations, and original-data tooling, read the [full project story](docs/story.md).
