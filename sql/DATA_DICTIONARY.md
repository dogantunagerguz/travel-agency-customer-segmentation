# SQL data dictionary

| Relation | Grain | Key fields / interpretation |
|---|---|---|
| `raw_hotels` | one generated hotel row | source hotel name and location fields exactly as loaded |
| `raw_reservations` | one generated reservation row | `reservation_no`; Excel serial arrival/departure dates are preserved raw |
| `stg_hotels` | one standardized hotel | trimmed, case-folded key with Turkish İ/Ş/Ğ/Ü/Ö/Ç transliteration |
| `stg_reservations` | one typed reservation | customer/hotel keys, ISO dates and numeric amounts |
| `fct_reservations` | one accepted reservation matched to one hotel | `reservation_no`; `lead_days = arrival_date - booking_date` |
| `customer_lifecycle_2026` | one customer | fixed windows: 2026, 2025, before 2025 |
| `customer_value_2026` | one customer | recency at 2026-12-31, distinct booking count, value and rank |
| `monthly_booking_kpis` | one booking month | distinct reservations/customers, revenue and average lead days |
| `hotel_recommendation_signals` | one age-band/hotel combination | bookings, revenue and within-band preference rank |
| `quality_check_results` | one validation rule | `issue_count = 0` is required |

All monetary values and identities originate from the fully synthetic public demo generator. They are not operational totals.
