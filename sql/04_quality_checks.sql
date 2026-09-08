-- Every control is tied to a concrete row-loss, key, date or amount risk.
CREATE VIEW quality_check_results AS
SELECT 'normalized_hotel_key_collision' AS check_name, COUNT(*) AS issue_count
FROM (SELECT hotel_key FROM stg_hotels GROUP BY hotel_key HAVING COUNT(*) > 1)
UNION ALL
SELECT 'duplicate_reservation_number' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT reservation_no FROM stg_reservations
    GROUP BY reservation_no HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'missing_customer_or_hotel_key', COUNT(*)
FROM stg_reservations
WHERE customer_key IS NULL OR TRIM(customer_key) = ''
   OR hotel_key IS NULL OR TRIM(hotel_key) = ''
UNION ALL
SELECT 'accepted_hotel_not_matched', COUNT(*)
FROM stg_reservations AS r
LEFT JOIN stg_hotels AS h USING (hotel_key)
WHERE r.booking_status = 'accepted' AND h.hotel_key IS NULL
UNION ALL
SELECT 'accepted_row_lost_or_multiplied', ABS(
    (SELECT COUNT(*) FROM stg_reservations WHERE booking_status = 'accepted')
    - (SELECT COUNT(*) FROM fct_reservations)
)
UNION ALL
SELECT 'booking_after_arrival', COUNT(*)
FROM fct_reservations
WHERE date(booking_date) > date(arrival_date)
UNION ALL
SELECT 'stay_length_not_reconciled', COUNT(*)
FROM fct_reservations
WHERE CAST(julianday(departure_date) - julianday(arrival_date) AS INTEGER) <> nights
UNION ALL
SELECT 'balance_not_reconciled', COUNT(*)
FROM fct_reservations
WHERE ABS((total_amount - paid_amount) - balance_amount) > 0.01
UNION ALL
SELECT 'customer_not_classified', COUNT(*)
FROM customer_lifecycle_2026
WHERE lifecycle_segment = 'Unclassified';
