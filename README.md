# From "Who Are Our Loyal Customers?" to Hotel Recommendations


[Run the public demo](#run-the-public-demo) — synthetic sample data, no private files or API key required.

| | |
|---|---|
| **Business impact** | Identifies customer lifecycle segments, reconstructs booking lead time, and supports more focused hotel recommendations. |
| **Tools** | Power BI, Power Query, DAX, Python, LocationIQ |
| **Status** | In operational use; manually refreshed; source data remains private. |


**TL;DR** — A Power BI report for a travel agency, built from sales exports laid out for humans rather than machines. It classifies customers by lifecycle (new, loyal, lapsed, and so on), reconstructs a transaction date the exports never recorded, and geocodes hotel names for a location view. Built remotely, in use by the sales team, refreshed by hand. The code and reasoning are here; the data belongs to the tour operator and isn't published.

*Jump to: [Why the data couldn't answer it](#why-the-data-couldnt-answer-it) · [What I built](#what-i-built) · [What I found](#what-i-found) · [Where this could go next](#where-this-could-go-next) · [Status and limitations](#status-and-limitations)*

It started with one question to the travel agency team: which routine costs you the most time? Their answer was simple. They couldn't reliably tell who their loyal customers were. Everything in this repository past that answer goes beyond what was asked for.

---

## Context

I built this for the travel agency arm of a small Turkish company. The agency resells holiday packages for a large tour operator and runs two branches in different cities. Its sales data arrives as exports from the operator's system, formatted for a person to read rather than for a machine to process. Roughly 4,500 customers across both branches, with a separate report built for each.

## What was asked, and what wasn't

That question and answer were the whole brief: a system that reliably identifies loyal customers, not a rebuild of the sales report.

Everything else here was extra. While working through the data, I noticed other questions it could answer, like where customers actually go and how far ahead they book. I built those too. My view is that people often don't know they need something until they see it.

This matters for reading the rest. The loyalty segmentation is what was delivered. Everything else is what the data turned out to say once someone started asking.

## Why the data couldn't answer it

**There was no transaction date.** Not missing values, no column at all. The exports carried the travel date but never recorded when the booking was made. Lead time, the gap between the two, wasn't hard to compute. It was a concept the dataset had no way to express. You can't filter your way to a column that isn't there.

**The exports were formatted, not structured.** The layout was built for reading, not processing. Loading them directly gave Power Query something it could open, but nothing useful to join to.

**Hotel identity was unstable.** Turkish hotel names use characters like İ, Ü, Ğ, Ş, Ö, and Ç, and different systems write them differently. The same hotel showed up as GÜRAL in one source and GURAL in another. A join on hotel name doesn't fail here, it just silently drops rows. Totals come out low and nothing tells you why.

**There was no location data.** Just hotel names, no addresses, no coordinates. A map wasn't possible without geocoding them first.

## What I built

**Customer lifecycle segmentation, the actual brief.** A five-state classification using a fixed **2026 reference year** in the published model, where each state points to a different action:

| State | Definition in the 2026 model | What it's for |
|---|---|---|
| New | No purchases before 2026 | Onboarding |
| Loyal | Bought in both 2026 and 2025 | Retention |
| One-time | No purchase in 2026, exactly one before 2026 | Reactivation |
| Lapsed | No purchase in 2026, more than one before 2026 | Call list |
| Won back | Skipped 2025, bought before 2025 and again in 2026 | Learn what worked |

In the published DAX column, `CurrentYear = 2026`: "this year" means 2026, "last year" means 2025, and older purchases are before 2025. It counts each customer's bookings across these three purchase-year windows and assigns a state from the combination. The reference year stays fixed when the project is opened or refreshed in a later year.

The choice of calendar-year windows rather than a rolling window reflects the agency's seasonal business. To use another reference year, update the column's year constant and refresh the model with the relevant source data. A year slicer filters the report without changing this classification's reference year. See [the segmentation and refresh notes](docs/dashboard.md#how-the-segmentation-is-defined).

**Transaction date, engineered rather than derived.** The rows had no date, but the filename did. When the sales system exported a period, it wrote the month and year into the file's name. The export itself was built for a person to read, not a machine to process, so before any date could be attached, the file first had to be turned into something structured. Instead of working around the missing column later, I changed how the data was collected and asked the team to export month by month. A Python script, merger.py, took each reading-oriented export, converted it into a processable table, read the month and year out of the filename, and wrote the transaction date into a new column as the first of that month. Lead time became travel date minus transaction date.

The precision is monthly, not daily. That's a real limit, and it's listed below.

**Finding data nobody thought to mention.** I asked the team to send me samples of everything they had, relevant or not, without filtering it themselves. That's how I found a source with hotel locations. Nobody had offered it, because nobody thought of it as data.

My first attempt with it failed. I tried to build an income segmentation from the pricing it held, and the data didn't support it. What it did support was geography. The map exists because a different idea didn't work.

**Geocoding.** What I actually wanted was hotel data, and I couldn't get it: scraping search results wasn't allowed or reliable, and the wholesale hotel-data providers are built for agencies trading inventory, not one-off enrichment. So instead of acquiring hotel data, I geocoded the names I already had. LocationIQ turns a name into coordinates, which was the part I actually needed; the script caches results, and hotels it can't resolve go to a colleague for manual entry rather than being silently dropped.

**Name normalization.** In Power Query, I strip the Turkish-specific characters from hotel names to build a stable join key, so GÜRAL and GURAL resolve to the same hotel no matter which source they came from.

**Grain.** Joining the hotel table to the sales table inflated every measure. The join fanned out and rows multiplied. This kind of problem has no error message, the report still renders fine, the numbers are just wrong. The fix was getting each table's grain right before building the relationship, not patching the measures afterward.

## What I found

Plotting average lead time by purchase month gives a U shape: January bookings sit around 150 days before travel, the gap shrinks to about a month by high summer, then climbs again toward year end. Much of that curve is mechanical, not behavioral: if almost everyone travels in summer, a January purchase is forced to sit far ahead of travel and a July purchase close to it. The part worth reading is at the edges, where late-year bookings for the following summer show up.

Segmenting by age and family type shows a related pattern. Different groups lean toward different hotels, and some hotels come up again and again for a specific age or family profile. Knowing that turns a generic recommendation into a specific one: when a new customer with a matching profile calls, the hotels their peers actually chose are already known.

The location map was built for the same reason, to see how loyal customers actually vacation. Some customers are loyal to a single hotel every time. Others prefer to move around, picking a different region each trip. That distinction could matter on a call. Knowing where a customer tends to go, before they mention it, could make a hotel suggestion feel personal instead of generic, though whether it actually does hasn't been tested.

The practical use is hotel recommendation. Selling a holiday is a complicated conversation. There are too many hotels and too many combinations, and customers are picky about leisure in a way they aren't about ordinary purchases. Knowing what customers of a given age and group size actually bought, and where a specific loyal customer tends to go, turns an open-ended conversation into a short list.

## Where this could go next

The segmentation is rule-based today. It buckets customers, then shows what each bucket booked. I'd tried getting at income more directly earlier, through hotel pricing, and it didn't hold up. So I set it aside.

The idea I keep coming back to is closer to how a video feed decides what to show next. Recommend hotels based on what similar customers have actually chosen, instead of a fixed bucket. Framed that way, income segmentation comes back as a side effect instead of something built from price data directly. The hotels a customer's peers book say something about spending capacity that price data alone couldn't.

## Status and limitations

- **Customer identity is a name string.** There's no customer ID in the source. Two people with the same name merge into one, and one person entered inconsistently splits into two. Across about 4,500 Turkish customers, both happen. Unlike hotel names, this can't be fixed by normalization. There's no ground truth that says two identical names are the same person.
- **In use, manually refreshed.** No scheduled refresh, no automated pipeline. Reports are published on Power BI Service, and the data is updated by hand.
- **No measured conversion.** This is decision support, not a targeting engine. It doesn't produce a call list. The underlying use case is telesales, but phone numbers aren't integrated into the report, a deliberate choice: that data is currently scattered across sources and callback dates need frequent updating, so keeping it out avoided a maintenance burden the report isn't set up to carry. Measuring conversion would mean the sales team recording whether they used a recommendation, which is a process change, not a dashboard change.
- **Transaction date resolves to month, not day.** Lead-time distributions are right in shape but coarse at the tail.
- **The data isn't published here.** The sales data belongs to the tour operator. This repository holds the code and the reasoning, not the dataset.

## What's in this repo

```
src/merger.py         # flattens reading-oriented exports, dates them from the filename
src/geocode.py        # LocationIQ lookup, caching, unresolved logging
src/generate_mock.py  # anonymizes the data for this public repo, keeping joins intact
docs/dashboard.md     # the three report pages, with notes and the segmentation logic
```

The dashboard walkthrough, with screenshots of all three report pages, is in [docs/dashboard.md](docs/dashboard.md).

## Run the public demo

The public demo uses **fully synthetic data**, generated locally without private files, credentials, or API requests. Demo figures are illustrative and do not reproduce the business results below.

1. Download this repository (Code → Download ZIP) and extract it, or clone it.
2. Install Python 3.10+ and a current Power BI Desktop for Windows with PBIP/TMDL support.
3. Close the project in Power BI Desktop, then run these commands from the repository folder:

```bash
python -m pip install -r requirements.txt
python scripts/setup_demo.py
```

4. Open `Travel-Agency-Mock.pbip` and select **Refresh**.

The script writes the sample workbooks to `demo-data/` and updates the single `DemoDataFolder` Power Query parameter in the local project. If you move the repository, close Power BI Desktop and run the setup command again. To use another sample-data location, run `python scripts/setup_demo.py --data-dir "path/to/demo-data"`. You can also edit `DemoDataFolder` through **Transform data → Manage Parameters**.

Python can generate the files on Windows, macOS, or Linux; opening the report requires [Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview). No Power BI Service workspace or cloud refresh setup is required for this local demo. If a map requests an online map service, the remaining report pages can still be reviewed offline.

The sample is anchored to 2026. It contains invented identities and transactions, with matching keys across related tables. Existing screenshots and operational results describe the original project; their totals will differ from this demo.

Run the automated source-data and relocation checks with:

```bash
python -m unittest discover -s tests -v
```

## Original-data tooling (optional)

The commands below process your own source exports; the standalone demo above does not require them.

Of 972 hotels, LocationIQ resolved 425 automatically with an address and coordinates. The rest were filled in by hand rather than dropped, which is why the map covers every hotel and not just the ones a geocoder happened to recognize.

```bash
pip install -r requirements.txt
cp .env.example .env        # add your LocationIQ API key

# Flatten the monthly exports into one table
python src/merger.py --input <folder-of-monthly-exports> --output reservations_clean.xlsx

# Geocode the hotel names
python src/geocode.py --input hotels.xlsx --output hotels_geocoded.xlsx
```

`merger.py` scans the input folder and its subfolders, so the monthly exports can stay in whatever structure they arrive in. The month and year are read from each filename, in either order: `2025 OCAK` and `OCAK 2026` both resolve. Files whose month can't be read are reported at the end rather than silently dated. Negative currency values keep their sign, including numeric cells, `-1.250,50`, and accounting-style `(1.250,50)`.

Whole-lira text can omit the decimal comma. When a text value contains only dots, complete groups of three digits are treated as thousands: `1.250 ₺` becomes `1250`, and `1.250.000 ₺` becomes `1250000`. Dot decimals such as `12.50` and numeric Excel cells keep their scale.

`geocode.py` automatically loads `.env` from the project root, even when launched from another directory. An existing `LOCATIONIQ_API_KEY` environment variable takes precedence. The script is resumable: rows that already have coordinates are skipped, and progress is written to disk periodically, so hitting the free tier's daily limit costs nothing but a re-run.

Run the regression checks from the project root (no API requests or private data required):

```bash
python -m unittest discover -s tests -v
```
