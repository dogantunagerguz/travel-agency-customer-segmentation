-- Fixed-window lifecycle logic equivalent to the published 2026 model.
CREATE VIEW customer_lifecycle_2026 AS
WITH customers AS (
    SELECT customer_key, MAX(customer_name) AS customer_name
    FROM fct_reservations
    GROUP BY customer_key
),
booking_windows AS (
    SELECT
        c.customer_key,
        c.customer_name,
        SUM(CASE WHEN r.booking_date >= '2026-01-01' AND r.booking_date < '2027-01-01'
                 THEN 1 ELSE 0 END) AS bookings_2026,
        SUM(CASE WHEN r.booking_date >= '2025-01-01' AND r.booking_date < '2026-01-01'
                 THEN 1 ELSE 0 END) AS bookings_2025,
        SUM(CASE WHEN r.booking_date < '2025-01-01' THEN 1 ELSE 0 END) AS bookings_before_2025
    FROM customers AS c
    LEFT JOIN fct_reservations AS r USING (customer_key)
    GROUP BY c.customer_key, c.customer_name
)
SELECT
    *,
    CASE
        WHEN bookings_2026 > 0 AND bookings_2025 = 0 AND bookings_before_2025 = 0 THEN 'New'
        WHEN bookings_2026 > 0 AND bookings_2025 > 0 THEN 'Loyal'
        WHEN bookings_2026 = 0 AND bookings_2025 + bookings_before_2025 = 1 THEN 'One-time'
        WHEN bookings_2026 = 0 AND bookings_2025 + bookings_before_2025 > 1 THEN 'Lapsed'
        WHEN bookings_2026 > 0 AND bookings_2025 = 0 AND bookings_before_2025 > 0 THEN 'Won back'
        ELSE 'Unclassified'
    END AS lifecycle_segment
FROM booking_windows;

CREATE VIEW customer_value_2026 AS
WITH customer_value AS (
    SELECT
        customer_key,
        MAX(customer_name) AS customer_name,
        MAX(booking_date) AS latest_booking_date,
        COUNT(DISTINCT reservation_no) AS booking_frequency,
        SUM(total_amount) AS lifetime_value,
        SUM(balance_amount) AS open_balance
    FROM fct_reservations
    WHERE booking_date < '2027-01-01'
    GROUP BY customer_key
)
SELECT
    *,
    CAST(julianday('2026-12-31') - julianday(latest_booking_date) AS INTEGER) AS recency_days,
    DENSE_RANK() OVER (ORDER BY lifetime_value DESC) AS value_rank
FROM customer_value;

CREATE VIEW segment_booking_kpis_2026 AS
SELECT
    lifecycle_segment,
    COUNT(*) AS customers,
    SUM(CASE WHEN booking_frequency >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(AVG(CASE WHEN booking_frequency >= 2 THEN 100.0 ELSE 0.0 END), 1) AS repeat_customer_rate_pct,
    ROUND(AVG(lifetime_value), 2) AS average_booked_value
FROM customer_lifecycle_2026
JOIN customer_value_2026 USING (customer_key)
GROUP BY lifecycle_segment;

CREATE VIEW monthly_booking_kpis AS
WITH monthly AS (
    SELECT
        strftime('%Y-%m', booking_date) AS booking_month,
        COUNT(DISTINCT reservation_no) AS bookings,
        COUNT(DISTINCT customer_key) AS customers,
        SUM(total_amount) AS booked_revenue,
        AVG(lead_days) AS average_lead_days
    FROM fct_reservations
    GROUP BY strftime('%Y-%m', booking_date)
),
with_previous AS (
    SELECT *,
        LAG(booking_month) OVER (ORDER BY booking_month) AS previous_booking_month,
        LAG(booked_revenue) OVER (ORDER BY booking_month) AS previous_month_revenue
    FROM monthly
)
SELECT
    booking_month,
    bookings,
    customers,
    ROUND(booked_revenue, 2) AS booked_revenue,
    ROUND(average_lead_days, 1) AS average_lead_days,
    CASE WHEN previous_booking_month = strftime('%Y-%m', booking_month || '-01', '-1 month')
        THEN ROUND(booked_revenue - previous_month_revenue, 2)
    END AS revenue_change_vs_previous_month
FROM with_previous;

CREATE VIEW hotel_recommendation_signals AS
WITH profile_hotel AS (
    SELECT
        CASE
            WHEN customer_age < 30 THEN 'Under 30'
            WHEN customer_age < 45 THEN '30-44'
            WHEN customer_age < 60 THEN '45-59'
            ELSE '60+'
        END AS age_band,
        city,
        hotel_name,
        COUNT(DISTINCT reservation_no) AS booking_count,
        SUM(total_amount) AS booked_revenue
    FROM fct_reservations
    GROUP BY age_band, city, hotel_name
)
SELECT
    *,
    DENSE_RANK() OVER (
        PARTITION BY age_band
        ORDER BY booking_count DESC, booked_revenue DESC
    ) AS preference_rank
FROM profile_hotel;

CREATE VIEW pipeline_reconciliation AS
SELECT
    (SELECT COUNT(*) FROM raw_reservations) AS raw_reservations,
    (SELECT COUNT(*) FROM stg_reservations) AS staged_reservations,
    (SELECT COUNT(*) FROM stg_reservations WHERE booking_status = 'accepted') AS accepted_reservations,
    (SELECT COUNT(*) FROM fct_reservations) AS matched_fact_rows,
    (SELECT COUNT(DISTINCT customer_key) FROM fct_reservations) AS customers,
    (SELECT COUNT(*) FROM stg_hotels) AS hotels,
    (SELECT COUNT(*) FROM stg_reservations WHERE booking_status IS NOT 'accepted') AS excluded_by_status,
    (SELECT COUNT(DISTINCT source_row_id) FROM reservation_rejection_reasons) AS rejected_reservations;

