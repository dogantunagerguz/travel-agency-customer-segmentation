-- Raw landing tables mirror the public Power BI demo workbooks.
-- Business rules are deliberately deferred to staging and mart views.

CREATE TABLE raw_hotels (
    source_hotel_name TEXT,
    country           TEXT,
    city              TEXT,
    district          TEXT,
    hotel_class       TEXT,
    latitude          NUMERIC,
    longitude         NUMERIC
);

CREATE TABLE raw_reservations (
    source_row_no    INTEGER,
    reservation_no  INTEGER,
    acceptance_status TEXT,
    customer_name    TEXT,
    customer_age     INTEGER,
    hotel_name       TEXT,
    arrival_serial   INTEGER,
    departure_serial INTEGER,
    nights           INTEGER,
    transaction_date TEXT,
    total_amount     NUMERIC,
    paid_amount      NUMERIC,
    balance_amount   NUMERIC,
    adults           INTEGER,
    children         INTEGER,
    notes            TEXT
);

