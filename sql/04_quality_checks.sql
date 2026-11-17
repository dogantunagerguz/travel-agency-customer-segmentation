-- Check each source row as well as the business number carried into the fact.
CREATE VIEW reservation_reconciliation AS
WITH expected AS (
    SELECT
        r.source_row_id, r.source_row_no,
        NULLIF(TRIM(r.reservation_no), '') AS source_reservation_no,
        CASE
            WHEN LOWER(TRIM(r.acceptance_status)) IS NOT 'accepted' THEN 'excluded_by_status'
            WHEN rejected.source_row_id IS NOT NULL THEN 'rejected'
            ELSE 'included'
        END AS expected_outcome
    FROM raw_reservations AS r
    LEFT JOIN (SELECT DISTINCT source_row_id FROM reservation_rejection_reasons) AS rejected
        USING (source_row_id)
),
actual AS (
    SELECT source_row_id, COUNT(*) AS fact_rows, MIN(reservation_no) AS fact_reservation_no
    FROM fct_reservations
    GROUP BY source_row_id
)
SELECT
    e.source_row_id, e.source_row_no, e.source_reservation_no, e.expected_outcome,
    COALESCE(a.fact_rows, 0) AS fact_rows, a.fact_reservation_no,
    CASE
        WHEN e.expected_outcome = 'included'
            THEN COALESCE(a.fact_rows = 1 AND a.fact_reservation_no = e.source_reservation_no, 0)
        ELSE COALESCE(a.fact_rows, 0) = 0
    END AS is_consistent
FROM expected AS e
LEFT JOIN actual AS a USING (source_row_id)
UNION ALL
SELECT a.source_row_id, NULL, NULL, 'orphan_output', a.fact_rows, a.fact_reservation_no, 0
FROM actual AS a
WHERE NOT EXISTS (
    SELECT 1 FROM expected AS e WHERE e.source_row_id = a.source_row_id
);

CREATE VIEW quality_check_results AS
WITH row_checks AS (
    SELECT 'missing_reservation_number' AS check_name
    UNION ALL SELECT 'missing_customer_or_hotel_key'
    UNION ALL SELECT 'accepted_hotel_not_matched'
    UNION ALL SELECT 'invalid_date'
    UNION ALL SELECT 'booking_after_arrival'
    UNION ALL SELECT 'stay_length_not_reconciled'
    UNION ALL SELECT 'invalid_amount'
    UNION ALL SELECT 'balance_not_reconciled'
)
SELECT c.check_name, COUNT(r.reason) AS issue_count
FROM row_checks AS c
LEFT JOIN reservation_rejection_reasons AS r ON r.reason = c.check_name
GROUP BY c.check_name
UNION ALL
SELECT 'normalized_hotel_key_collision', COUNT(*)
FROM hotel_key_counts WHERE hotel_matches > 1
UNION ALL
SELECT 'duplicate_reservation_number', COUNT(*)
FROM duplicate_reservation_numbers
UNION ALL
SELECT 'reservation_lineage_mismatch', COUNT(*)
FROM reservation_reconciliation WHERE is_consistent = 0
UNION ALL
SELECT 'customer_not_classified', COUNT(*)
FROM customer_lifecycle_2026 WHERE lifecycle_segment = 'Unclassified';
