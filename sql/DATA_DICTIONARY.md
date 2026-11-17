# SQL data dictionary

| Relation | Grain | Key fields / interpretation |
|---|---|---|
| `raw_hotels` | one generated hotel row | source hotel name and location fields exactly as loaded |
| `raw_reservations` | one row from the reservation workbook | `source_row_id` identifies the raw row within one load. `source_row_no` copies the workbook's No column. `reservation_no` is the text business key. |
| `stg_hotels` | one standardized hotel row | trimmed, case-folded key with Turkish İ/Ş/Ğ/Ü/Ö/Ç transliteration |
| `stg_reservations` | one typed row for each raw reservation | normalized keys, ISO dates and numeric amounts. Invalid dates or amounts become NULL for validation. |
| `reservation_rejection_reasons` | one row per rejected source row and reason | `source_row_id`, workbook row number, reservation number and reason |
| `fct_reservations` | one valid accepted reservation matched to one hotel | `source_row_id` traces the source. `lead_days` is arrival date minus booking date. |
| `reservation_reconciliation` | one row per raw reservation or orphan output key | expected outcome, fact row count, fact reservation number and `is_consistent` |
| `customer_lifecycle_2026` | one customer | fixed windows: 2026, 2025, before 2025 |
| `customer_value_2026` | one customer | recency at 2026-12-31, distinct booking count, value and rank |
| `segment_booking_kpis_2026` | one lifecycle segment | repeat customers booked at least twice by the end of 2026. The rate divides repeat customers by all customers in the segment. Average booked value uses recorded booking totals per customer. |
| `monthly_booking_kpis` | one observed booking month | distinct reservations/customers, booked value and average lead days. Change requires the preceding calendar month in the data. |
| `hotel_recommendation_signals` | one age-band/hotel combination | bookings, revenue and within-band preference rank |
| `quality_check_results` | one validation rule | `issue_count = 0` is required |

All monetary values and identities originate from the synthetic demo generator. Booked value is the recorded reservation total. Payments and balances have their own fields.
