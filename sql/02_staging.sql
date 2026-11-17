-- Standardize workbook fields while preserving one row per reservation.
CREATE VIEW stg_hotels AS
SELECT
    NULLIF(UPPER(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(source_hotel_name),
            'İ', 'I'), 'ı', 'i'), 'Ş', 'S'), 'ş', 's'),
            'Ğ', 'G'), 'ğ', 'g'), 'Ü', 'U'), 'ü', 'u'),
            'Ö', 'O'), 'ö', 'o'), 'Ç', 'C'), 'ç', 'c')
    ), '') AS hotel_key,
    TRIM(source_hotel_name) AS hotel_name,
    TRIM(country) AS country,
    TRIM(city) AS city,
    TRIM(district) AS district,
    TRIM(hotel_class) AS hotel_class,
    CAST(latitude AS REAL) AS latitude,
    CAST(longitude AS REAL) AS longitude
FROM raw_hotels;

CREATE VIEW stg_reservations AS
SELECT
    source_row_id,
    source_row_no,
    NULLIF(TRIM(reservation_no), '') AS reservation_no,
    LOWER(TRIM(acceptance_status)) AS booking_status,
    NULLIF(UPPER(TRIM(customer_name)), '') AS customer_key,
    TRIM(customer_name) AS customer_name,
    CAST(customer_age AS INTEGER) AS customer_age,
    NULLIF(UPPER(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(hotel_name),
            'İ', 'I'), 'ı', 'i'), 'Ş', 'S'), 'ş', 's'),
            'Ğ', 'G'), 'ğ', 'g'), 'Ü', 'U'), 'ü', 'u'),
            'Ö', 'O'), 'ö', 'o'), 'Ç', 'C'), 'ç', 'c')
    ), '') AS hotel_key,
    TRIM(hotel_name) AS hotel_name,
    CASE WHEN typeof(arrival_serial) = 'integer' AND arrival_serial >= 61
        THEN date('1899-12-30', arrival_serial || ' days') END AS arrival_date,
    CASE WHEN typeof(departure_serial) = 'integer' AND departure_serial >= 61
        THEN date('1899-12-30', departure_serial || ' days') END AS departure_date,
    CASE WHEN typeof(nights) = 'integer' AND nights >= 0 THEN nights END AS nights,
    -- SQLite may normalize dates such as February 30. Require an exact round trip.
    CASE WHEN date(transaction_date, '+0 days') = transaction_date
        THEN transaction_date END AS booking_date,
    -- Invalid text must not become zero. Subtracting a value from itself also rejects infinity.
    CASE WHEN typeof(total_amount) IN ('integer', 'real') AND total_amount - total_amount = 0
        THEN CAST(total_amount AS REAL) END AS total_amount,
    CASE WHEN typeof(paid_amount) IN ('integer', 'real') AND paid_amount - paid_amount = 0
        THEN CAST(paid_amount AS REAL) END AS paid_amount,
    CASE WHEN typeof(balance_amount) IN ('integer', 'real') AND balance_amount - balance_amount = 0
        THEN CAST(balance_amount AS REAL) END AS balance_amount,
    CAST(adults AS INTEGER) AS adults,
    CAST(children AS INTEGER) AS children
FROM raw_reservations;

CREATE VIEW hotel_key_counts AS
SELECT hotel_key, COUNT(*) AS hotel_matches
FROM stg_hotels
WHERE hotel_key IS NOT NULL
GROUP BY hotel_key;

CREATE VIEW duplicate_reservation_numbers AS
SELECT reservation_no
FROM stg_reservations
WHERE booking_status = 'accepted' AND reservation_no IS NOT NULL
GROUP BY reservation_no
HAVING COUNT(*) > 1;

-- Each accepted source row can have several reasons to stay out of the KPIs.
CREATE VIEW reservation_rejection_reasons AS
WITH candidates AS (
    SELECT r.*, COALESCE(h.hotel_matches, 0) AS hotel_matches,
           d.reservation_no IS NOT NULL AS is_duplicate
    FROM stg_reservations AS r
    LEFT JOIN hotel_key_counts AS h USING (hotel_key)
    LEFT JOIN duplicate_reservation_numbers AS d USING (reservation_no)
    WHERE r.booking_status = 'accepted'
),
issues AS (
    SELECT source_row_id, 'missing_reservation_number' AS reason
    FROM candidates WHERE reservation_no IS NULL
    UNION ALL
    SELECT source_row_id, 'duplicate_reservation_number'
    FROM candidates WHERE is_duplicate
    UNION ALL
    SELECT source_row_id, 'missing_customer_or_hotel_key'
    FROM candidates WHERE customer_key IS NULL OR hotel_key IS NULL
    UNION ALL
    SELECT source_row_id, 'accepted_hotel_not_matched'
    FROM candidates WHERE hotel_key IS NOT NULL AND hotel_matches = 0
    UNION ALL
    SELECT source_row_id, 'ambiguous_hotel_match'
    FROM candidates WHERE hotel_matches > 1
    UNION ALL
    SELECT source_row_id, 'invalid_date'
    FROM candidates WHERE booking_date IS NULL OR arrival_date IS NULL OR departure_date IS NULL
    UNION ALL
    SELECT source_row_id, 'booking_after_arrival'
    FROM candidates WHERE booking_date > arrival_date
    UNION ALL
    SELECT source_row_id, 'stay_length_not_reconciled'
    FROM candidates
    WHERE nights IS NULL OR julianday(departure_date) - julianday(arrival_date) <> nights
    UNION ALL
    SELECT source_row_id, 'invalid_amount'
    FROM candidates WHERE total_amount IS NULL OR paid_amount IS NULL OR balance_amount IS NULL
    UNION ALL
    SELECT source_row_id, 'balance_not_reconciled'
    FROM candidates WHERE ABS(ROUND(total_amount - paid_amount - balance_amount, 2)) > 0.01
)
SELECT r.source_row_id, r.source_row_no, r.reservation_no, i.reason
FROM issues AS i
JOIN stg_reservations AS r USING (source_row_id);

CREATE VIEW fct_reservations AS
SELECT
    r.*,
    h.city,
    h.district,
    h.hotel_class,
    h.latitude,
    h.longitude,
    CAST(julianday(r.arrival_date) - julianday(r.booking_date) AS INTEGER) AS lead_days
FROM stg_reservations AS r
JOIN stg_hotels AS h USING (hotel_key)
LEFT JOIN (SELECT DISTINCT source_row_id FROM reservation_rejection_reasons) AS rejected
    USING (source_row_id)
WHERE r.booking_status = 'accepted' AND rejected.source_row_id IS NULL;
