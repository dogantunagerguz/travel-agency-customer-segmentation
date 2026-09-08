-- Standardize workbook fields while preserving one row per reservation.
CREATE VIEW stg_hotels AS
SELECT
    UPPER(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(source_hotel_name),
            'İ', 'I'), 'ı', 'i'), 'Ş', 'S'), 'ş', 's'),
            'Ğ', 'G'), 'ğ', 'g'), 'Ü', 'U'), 'ü', 'u'),
            'Ö', 'O'), 'ö', 'o'), 'Ç', 'C'), 'ç', 'c')
    ) AS hotel_key,
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
    CAST(source_row_no AS INTEGER) AS source_row_no,
    CAST(reservation_no AS INTEGER) AS reservation_no,
    LOWER(TRIM(acceptance_status)) AS booking_status,
    UPPER(TRIM(customer_name)) AS customer_key,
    TRIM(customer_name) AS customer_name,
    CAST(customer_age AS INTEGER) AS customer_age,
    UPPER(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(hotel_name),
            'İ', 'I'), 'ı', 'i'), 'Ş', 'S'), 'ş', 's'),
            'Ğ', 'G'), 'ğ', 'g'), 'Ü', 'U'), 'ü', 'u'),
            'Ö', 'O'), 'ö', 'o'), 'Ç', 'C'), 'ç', 'c')
    ) AS hotel_key,
    TRIM(hotel_name) AS hotel_name,
    date('1899-12-30', '+' || CAST(arrival_serial AS INTEGER) || ' days') AS arrival_date,
    date('1899-12-30', '+' || CAST(departure_serial AS INTEGER) || ' days') AS departure_date,
    CAST(nights AS INTEGER) AS nights,
    date(transaction_date) AS booking_date,
    CAST(total_amount AS REAL) AS total_amount,
    CAST(paid_amount AS REAL) AS paid_amount,
    CAST(balance_amount AS REAL) AS balance_amount,
    CAST(adults AS INTEGER) AS adults,
    CAST(children AS INTEGER) AS children
FROM raw_reservations;

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
WHERE r.booking_status = 'accepted';
