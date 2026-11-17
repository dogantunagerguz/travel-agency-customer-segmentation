# Executed SQL results

> Generated from the same fully synthetic Excel workbooks used by the public Power BI demo. These are portfolio-demo outputs, not private or operational results.

**Reference model:** fixed 2026 lifecycle windows; SQLite in-memory execution.

## Pipeline reconciliation

| raw_reservations | staged_reservations | accepted_reservations | matched_fact_rows | customers | hotels | excluded_by_status | rejected_reservations |
|---|---|---|---|---|---|---|---|
| 48 | 48 | 48 | 48 | 30 | 6 | 0 | 0 |

## Reservation row audit

| expected_outcome | source_rows | output_rows |
|---|---|---|
| included | 48 | 48 |

## Lifecycle distribution

| lifecycle_segment | customers |
|---|---|
| Lapsed | 6 |
| Loyal | 6 |
| New | 6 |
| One-time | 6 |
| Won back | 6 |

## Top customer value records

| customer_name | booking_frequency | lifetime_value | value_rank |
|---|---|---|---|
| DEMO CUSTOMER 029 | 2 | 32960.0 | 1 |
| DEMO CUSTOMER 017 | 2 | 25280.0 | 2 |
| DEMO CUSTOMER 022 | 2 | 24920.0 | 3 |
| DEMO CUSTOMER 027 | 2 | 23760.0 | 4 |
| DEMO CUSTOMER 010 | 2 | 18200.0 | 5 |

## Customer KPIs by segment

| lifecycle_segment | customers | repeat_customers | repeat_customer_rate_pct | average_booked_value |
|---|---|---|---|---|
| Lapsed | 6 | 6 | 100.0 | 16993.33 |
| Loyal | 6 | 6 | 100.0 | 16913.33 |
| New | 6 | 0 | 0.0 | 8136.67 |
| One-time | 6 | 0 | 0.0 | 8576.67 |
| Won back | 6 | 6 | 100.0 | 16433.33 |

## 2026 monthly KPIs

| booking_month | bookings | customers | booked_revenue | average_lead_days | revenue_change_vs_previous_month |
|---|---|---|---|---|---|
| 2026-02 | 5 | 5 | 43240.0 | 33.8 |  |
| 2026-05 | 6 | 6 | 45880.0 | 36.0 |  |
| 2026-08 | 4 | 4 | 36320.0 | 35.0 |  |
| 2026-11 | 3 | 3 | 23420.0 | 36.0 |  |

## Rejected reservation rows

_No rows._

## Data-quality checks

| check_name | issue_count |
|---|---|
| accepted_hotel_not_matched | 0 |
| balance_not_reconciled | 0 |
| booking_after_arrival | 0 |
| customer_not_classified | 0 |
| duplicate_reservation_number | 0 |
| invalid_amount | 0 |
| invalid_date | 0 |
| missing_customer_or_hotel_key | 0 |
| missing_reservation_number | 0 |
| normalized_hotel_key_collision | 0 |
| reservation_lineage_mismatch | 0 |
| stay_length_not_reconciled | 0 |
