#!/usr/bin/env python3
"""
Geocode hotel names into coordinates and administrative areas via LocationIQ.

The sales exports carry hotel names but no addresses or coordinates, so a map
isn't possible without geocoding them first. This script reads a spreadsheet of
hotel names, looks each one up, and writes the results back into new columns.

LocationIQ is built on OpenStreetMap data. Its free tier allows 5,000 requests
per day and permits storing results indefinitely, which is what makes it usable
here: the lookup runs once and the results live in the spreadsheet. Attribution
for LocationIQ and "© OpenStreetMap contributors" is required wherever the
results are displayed.

The run is resumable. Rows that already have coordinates are skipped, and
progress is saved periodically, so a daily limit or a crash doesn't cost the
whole run.

Setup:
    cp .env.example .env     # then add your LocationIQ key

Usage:
    python geocode.py --input <hotels.xlsx> --output <hotels_geocoded.xlsx>
"""

import argparse
import os
import time

import requests
from openpyxl import load_workbook

ENDPOINT = "https://eu1.locationiq.com/v1/search"  # EU endpoint

SLEEP_SECONDS = 0.7   # stay under the per-second rate limit
SAVE_EVERY = 25       # flush to disk every N rows so progress survives a crash
MAX_RETRY = 5         # attempts before giving up on repeated rate limiting

HOTEL_COLUMN = "Otel Adı"

# Results are written to new columns. Any existing city/district values in the
# sheet are left untouched, so a bad match can't overwrite known-good data.
OUTPUT_COLUMNS = [
    "OSM_il_adaylari",
    "OSM_ilce_adaylari",
    "Enlem",
    "Boylam",
    "OSM_adres",
]


def get_api_key():
    key = os.environ.get("LOCATIONIQ_API_KEY")
    if not key:
        raise SystemExit(
            "LOCATIONIQ_API_KEY is not set.\n"
            "Copy .env.example to .env and add your key, or export it:\n"
            "    export LOCATIONIQ_API_KEY=your_key_here"
        )
    return key


def geocode(name, session, api_key):
    """Look up one hotel name. Backs off and retries on rate limiting.

    Returns None when there's no match, rather than guessing.
    """
    params = {
        "key": api_key,
        "q": f"{name}, Turkiye",
        "format": "json",
        "addressdetails": 1,
        "limit": 1,
        "countrycodes": "tr",   # restrict to Turkey; cuts down on wrong matches
        "accept-language": "tr",
    }

    for attempt in range(MAX_RETRY):
        response = session.get(ENDPOINT, params=params, timeout=20)

        if response.status_code == 429:
            wait = 2 ** attempt   # exponential backoff on the per-second limit
            print(f"    rate limited (429), waiting {wait}s...")
            time.sleep(wait)
            continue

        if response.status_code == 404:
            return None

        response.raise_for_status()
        data = response.json()
        if not data:
            return None

        top = data[0]
        address = top.get("address", {})

        # OSM doesn't map its administrative fields onto Turkish province and
        # district consistently, and which field holds which varies by record.
        # Rather than pick one and be silently wrong, every candidate is
        # written out side by side so the correct mapping can be settled by
        # inspection against rows whose real location is already known.
        province_candidates = " | ".join(
            filter(None, [address.get("province"), address.get("state")])
        )
        district_candidates = " | ".join(
            filter(None, [
                address.get("county"), address.get("town"), address.get("city"),
                address.get("district"), address.get("suburb"),
                address.get("municipality"),
            ])
        )

        return {
            "OSM_il_adaylari": province_candidates,
            "OSM_ilce_adaylari": district_candidates,
            "Enlem": top.get("lat"),
            "Boylam": top.get("lon"),
            # Full matched address, kept so each match can be sanity-checked
            # against the hotel name it came from.
            "OSM_adres": top.get("display_name"),
        }

    raise RuntimeError(
        "Repeated 429s, most likely the daily limit. Re-run later; "
        "completed rows are skipped automatically."
    )


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Spreadsheet of hotel names")
    parser.add_argument("--output", required=True, help="Where to write results")
    return parser.parse_args()


def main():
    args = parse_args()
    api_key = get_api_key()

    # Resume from the output file if it exists, so a re-run picks up where the
    # last one stopped instead of starting over.
    source = args.output if os.path.exists(args.output) else args.input
    workbook = load_workbook(source)
    worksheet = workbook.active

    headers = [cell.value for cell in worksheet[1]]
    if HOTEL_COLUMN not in headers:
        raise SystemExit(f"Column '{HOTEL_COLUMN}' not found. Headers: {headers}")
    hotel_index = headers.index(HOTEL_COLUMN) + 1

    for column in OUTPUT_COLUMNS:
        if column not in headers:
            headers.append(column)
            worksheet.cell(row=1, column=len(headers), value=column)
    column_index = {header: i + 1 for i, header in enumerate(headers)}

    session = requests.Session()
    done = 0

    for row in range(2, worksheet.max_row + 1):
        if worksheet.cell(row=row, column=column_index["Enlem"]).value not in (None, ""):
            continue  # already geocoded

        name = worksheet.cell(row=row, column=hotel_index).value
        if not name:
            continue

        try:
            result = geocode(str(name).strip(), session, api_key)
        except Exception as error:
            print(f"[row {row}] ERROR: {name} -> {error}")
            workbook.save(args.output)  # don't lose completed rows
            raise

        if result:
            for key, value in result.items():
                worksheet.cell(row=row, column=column_index[key], value=value)
        else:
            # Flag it rather than leave it blank. Unresolved hotels go to
            # manual entry instead of silently dropping out of the map.
            worksheet.cell(row=row, column=column_index["OSM_adres"], value="NOT FOUND")

        done += 1
        if done % SAVE_EVERY == 0:
            workbook.save(args.output)
            print(f"{done} rows processed, saved...")
        time.sleep(SLEEP_SECONDS)

    workbook.save(args.output)
    print(f"Done. {done} new row(s) processed. Output: {args.output}")


if __name__ == "__main__":
    main()
