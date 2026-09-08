-- Each row is an auditable control. A ready-to-share demo returns zero issues.
CREATE VIEW quality_check_results AS
SELECT 'orphan_customer_key' AS check_name, COUNT(*) AS issue_count
FROM reservations AS r
LEFT JOIN customers AS c ON c.customer_id = r.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orphan_hotel_key', COUNT(*)
FROM reservations AS r
LEFT JOIN hotels AS h ON h.hotel_id = r.hotel_id
WHERE h.hotel_id IS NULL
UNION ALL
SELECT 'accepted_booking_after_arrival', COUNT(*)
FROM reservations
WHERE booking_status = 'accepted' AND date(booking_date) > date(arrival_date)
UNION ALL
SELECT 'accepted_negative_amount', COUNT(*)
FROM reservations
WHERE booking_status = 'accepted'
  AND (total_amount < 0 OR paid_amount < 0 OR balance_amount < 0)
UNION ALL
SELECT 'balance_not_reconciled', COUNT(*)
FROM reservations
WHERE ABS((total_amount - paid_amount) - balance_amount) > 0.01
UNION ALL
SELECT 'empty_business_key', COUNT(*)
FROM customers
WHERE TRIM(customer_name) = ''
UNION ALL
SELECT 'unclassified_lifecycle', COUNT(*)
FROM customer_lifecycle_2026
WHERE lifecycle_segment = 'Unclassified';

