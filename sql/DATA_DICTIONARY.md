# SQL data dictionary

| Relation | Grain | Key fields / interpretation |
|---|---|---|
| `raw_hotels` | one generated hotel row | source hotel name and location fields exactly as loaded |
| `raw_reservations` | one generated reservation row | `reservation_no`; Excel serial arrival/departure dates are preserved raw |
| `stg_hotels` | one standardized hotel | trimmed, case-folded key with Turkish İ/Ş/Ğ/Ü/Ö/Ç transliteration |
| `stg_reservations` | one typed reservation | customer/hotel keys, ISO dates and numeric amounts |
| `dim_customer` | one normalized customer key | customer name, age and age band; name-based identity is a known demo limitation |
| `dim_hotel` | one normalized hotel key | hotel name, geography, class and coordinates |
| `dim_date` | one distinct fact date | integer date key plus date, year, month, year-month and weekday |
| `fct_booking` | one accepted reservation | customer, hotel and role-playing date keys; booking amounts, party size, nights and lead days |
| `fct_reservations` | one accepted reservation matched to one hotel | backward-compatible denormalized view used by the original marts |
| `customer_lifecycle_2026` | one customer | fixed windows: 2026, 2025, before 2025 |
| `customer_value_2026` | one customer | recency at 2026-12-31, distinct booking count, value and rank |
| `monthly_booking_kpis` | one booking month | distinct reservations/customers, revenue and average lead days |
| `hotel_recommendation_signals` | one age-band/hotel combination | bookings, revenue and within-band preference rank |
| `quality_check_results` | one original validation rule | nine source, join, date, amount and lifecycle controls |
| `star_schema_quality_checks` | one star-schema validation rule | four fact-grain and dimension-relationship controls |

All monetary values and identities originate from the fully synthetic public demo generator. They are not operational totals.

[End-to-end pipeline and refresh boundary](../docs/end-to-end-bi-pipeline.md)
