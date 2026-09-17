[← Project overview](../README.md) · [Full project story](story.md) · [Dashboard walkthrough](dashboard.md)

# From a loyalty question to hotel suggestions

## Business question

The agency team could not reliably identify loyal customers. I asked which routine took the most time, used that answer to define the initial problem, and then investigated what the available records could support. Booking timing and hotel geography became additional use cases during that work.

The original context is two branches and approximately 4,500 customer records. Customer identity is based on names, so the records are not a verified count of distinct people.

## Decisions I made

| Decision | Reason and operational use | Evidence |
|---|---|---|
| Request monthly exports and structure them with Python | The source had no booking-date column. Month and year from the filename provide a booking-month proxy, stored as the first day of the month, so booking lead time can be examined at limited precision. | [Missing source fields](story.md#why-the-data-couldnt-answer-it), [implementation](story.md#what-i-built), [merger script](../src/merger.py) |
| Use five lifecycle states with calendar-year windows | The agency's seasonal business made annual purchase patterns useful for distinguishing new, loyal, one-time, lapsed and won-back customers. | [Lifecycle rules](story.md#what-i-built), [model notes](dashboard.md#how-the-segmentation-is-defined) |
| Normalise hotel keys and fix the units represented by joined tables | Different spellings lost matches; a relationship at the wrong grain multiplied rows and inflated measures. Both problems had to be resolved before using the results. | [Name and grain decisions](story.md#what-i-built) |
| Explore additional sources, then use geography when pricing did not support income segmentation | Hotel names and locations could support a useful recommendation view even though the earlier pricing idea did not hold up. | [Source exploration](story.md#what-i-built) |
| Geocode names, cache results and pass unresolved hotels for manual completion | LocationIQ resolved 425 of 972 hotels automatically. Remaining locations were completed manually rather than silently omitted. | [Original-data tooling](story.md#original-data-tooling-optional), [geocoding script](../src/geocode.py) |

## Sources, units of analysis and constraints

The workflow combines structured monthly sales exports with hotel/location information. Reservation rows, customer histories and hotels represent different units of analysis. The public SQL companion documents one reservation per accepted fact row and one standardised hotel per join key, with controls for duplicate reservations, unmatched hotels and row loss or multiplication. See the [data dictionary](../sql/DATA_DICTIONARY.md) and [quality checks](../sql/04_quality_checks.sql).

Hotel-name normalisation improves joins; it does not solve customer identity. Identical customer names can merge different people, and spelling differences can split one person. The published lifecycle model uses a fixed **2026** reference year. Refreshing later does not advance that year, and changing a year slicer does not redefine the lifecycle windows.

Booking dates are month-level proxies rather than actual transaction days. Lead-time patterns therefore have limited precision and must also be read in the context of seasonal travel dates.

## How staff use it

1. Export the sales periods month by month and prepare the records with the Python workflow.
2. Update the source data and refresh the report manually.
3. Review the customer's lifecycle and previous bookings, plus hotel patterns for relevant age and group profiles.
4. Use that context to narrow suggestions during a sales conversation.

Phone numbers and callback scheduling are outside the report. It does not generate a contact list or automate calls. Whether a suggestion was used and whether it led to a booking are not captured as a measured conversion process.

## Evidence and outcome scope

- [Dashboard pages](dashboard.md) show lifecycle, booking timing and hotel geography. Public figures and identities are anonymised or synthetic; they are not production outcome totals.
- [Project findings](story.md#what-i-found) explain how the views can support recommendations. No increase in conversion or revenue has been measured.
- [SQL results](../sql/RESULTS.md) and [queries](../sql/03_marts.sql) make the synthetic lifecycle, hotel and booking calculations inspectable. SQL is a public portfolio companion, not a claim about the original production workflow.

## Implemented and proposed work

**Implemented:** monthly export preparation, booking-month proxies, hotel-key normalisation, corrected table relationships, five-state lifecycle reporting, geocoding with manual completion, and a runnable synthetic SQL companion. Operational reports are in use and refreshed manually.

**Proposed, not implemented here:** a consistent way for staff to record whether a recommendation was used and its booking outcome, followed by evaluation over a defined period. Similar-customer recommendations remain a future idea described in the [full story](story.md#where-this-could-go-next). Customer identity and reference-year maintenance would need to be addressed before expanding the workflow.
