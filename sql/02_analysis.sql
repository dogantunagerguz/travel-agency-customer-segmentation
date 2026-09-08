-- Portfolio companion queries: SQLite 3.25+.
-- The published Power BI lifecycle model uses a fixed 2026 reference year;
-- the same explicit windows are used here so a run date cannot change results.

CREATE VIEW customer_lifecycle_2026 AS
WITH accepted_bookings AS (
    SELECT customer_id, booking_date
    FROM reservations
    WHERE booking_status = 'accepted'
),
booking_windows AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(CASE WHEN b.booking_date >= '2026-01-01'
                      AND b.booking_date <  '2027-01-01' THEN 1 ELSE 0 END) AS bookings_2026,
        SUM(CASE WHEN b.booking_date >= '2025-01-01'
                      AND b.booking_date <  '2026-01-01' THEN 1 ELSE 0 END) AS bookings_2025,
        SUM(CASE WHEN b.booking_date <  '2025-01-01' THEN 1 ELSE 0 END) AS bookings_before_2025
    FROM customers AS c
    LEFT JOIN accepted_bookings AS b
        ON b.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    bookings_2026,
    bookings_2025,
    bookings_before_2025,
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
WITH accepted_value AS (
    SELECT
        c.customer_id,
        c.customer_name,
        MAX(r.booking_date) AS latest_booking_date,
        COUNT(r.reservation_id) AS booking_frequency,
        COALESCE(SUM(r.total_amount), 0) AS lifetime_value,
        COALESCE(SUM(r.balance_amount), 0) AS open_balance
    FROM customers AS c
    LEFT JOIN reservations AS r
        ON r.customer_id = c.customer_id
       AND r.booking_status = 'accepted'
       AND r.booking_date < '2027-01-01'
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    latest_booking_date,
    CAST(julianday('2026-12-31') - julianday(latest_booking_date) AS INTEGER) AS recency_days,
    booking_frequency,
    lifetime_value,
    open_balance,
    DENSE_RANK() OVER (ORDER BY lifetime_value DESC) AS value_rank
FROM accepted_value;

CREATE VIEW monthly_booking_kpis AS
WITH monthly AS (
    SELECT
        strftime('%Y-%m', booking_date) AS booking_month,
        COUNT(*) AS bookings,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(total_amount) AS booked_revenue,
        AVG(julianday(arrival_date) - julianday(booking_date)) AS average_lead_days
    FROM reservations
    WHERE booking_status = 'accepted'
    GROUP BY strftime('%Y-%m', booking_date)
),
with_previous AS (
    SELECT
        monthly.*,
        LAG(booked_revenue) OVER (ORDER BY booking_month) AS previous_month_revenue
    FROM monthly
)
SELECT
    booking_month,
    bookings,
    customers,
    ROUND(booked_revenue, 2) AS booked_revenue,
    ROUND(average_lead_days, 1) AS average_lead_days,
    ROUND(booked_revenue - previous_month_revenue, 2) AS revenue_change_vs_previous_month
FROM with_previous;

CREATE VIEW hotel_recommendation_signals AS
WITH profile_hotel AS (
    SELECT
        c.age_band,
        h.city,
        h.hotel_name,
        COUNT(*) AS booking_count,
        SUM(r.total_amount) AS booked_revenue
    FROM reservations AS r
    JOIN customers AS c ON c.customer_id = r.customer_id
    JOIN hotels AS h ON h.hotel_id = r.hotel_id
    WHERE r.booking_status = 'accepted'
    GROUP BY c.age_band, h.city, h.hotel_name
)
SELECT
    age_band,
    city,
    hotel_name,
    booking_count,
    booked_revenue,
    DENSE_RANK() OVER (
        PARTITION BY age_band
        ORDER BY booking_count DESC, booked_revenue DESC
    ) AS preference_rank
FROM profile_hotel;

