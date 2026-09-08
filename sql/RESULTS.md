# Executed SQL results

> Generated from the same fully synthetic Excel workbooks used by the public Power BI demo. These are portfolio-demo outputs, not private or operational results.

**Reference model:** fixed 2026 lifecycle windows; SQLite in-memory execution.

## Pipeline reconciliation

| raw_reservations | staged_reservations | accepted_reservations | matched_fact_rows | customers | hotels |
|---|---|---|---|---|---|
| 48 | 48 | 48 | 48 | 30 | 6 |

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

## 2026 monthly KPIs

| booking_month | bookings | customers | booked_revenue | average_lead_days | revenue_change_vs_previous_month |
|---|---|---|---|---|---|
| 2026-02 | 5 | 5 | 43240.0 | 33.8 | 39100.0 |
| 2026-05 | 6 | 6 | 45880.0 | 36.0 | 2640.0 |
| 2026-08 | 4 | 4 | 36320.0 | 35.0 | -9560.0 |
| 2026-11 | 3 | 3 | 23420.0 | 36.0 | -12900.0 |

## Data-quality checks

| check_name | issue_count |
|---|---|
| accepted_hotel_not_matched | 0 |
| accepted_row_lost_or_multiplied | 0 |
| balance_not_reconciled | 0 |
| booking_after_arrival | 0 |
| customer_not_classified | 0 |
| duplicate_reservation_number | 0 |
| missing_customer_or_hotel_key | 0 |
| normalized_hotel_key_collision | 0 |
| stay_length_not_reconciled | 0 |
