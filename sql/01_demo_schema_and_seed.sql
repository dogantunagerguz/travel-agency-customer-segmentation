-- Fully synthetic SQLite fixture for the travel-agency portfolio project.
-- It is intentionally small and does not reproduce private or operational data.

PRAGMA foreign_keys = ON;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    age_band      TEXT NOT NULL
);

CREATE TABLE hotels (
    hotel_id   INTEGER PRIMARY KEY,
    hotel_name TEXT NOT NULL UNIQUE,
    city       TEXT NOT NULL
);

CREATE TABLE reservations (
    reservation_id INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL REFERENCES customers(customer_id),
    hotel_id       INTEGER NOT NULL REFERENCES hotels(hotel_id),
    booking_date   TEXT NOT NULL,
    arrival_date   TEXT NOT NULL,
    nights         INTEGER NOT NULL CHECK (nights > 0),
    adults         INTEGER NOT NULL CHECK (adults > 0),
    children       INTEGER NOT NULL CHECK (children >= 0),
    total_amount   NUMERIC NOT NULL,
    paid_amount    NUMERIC NOT NULL,
    balance_amount NUMERIC NOT NULL,
    booking_status TEXT NOT NULL CHECK (booking_status IN ('accepted', 'refunded'))
);

INSERT INTO customers (customer_id, customer_name, age_band) VALUES
    (1, 'DEMO CUSTOMER 001', '25-34'),
    (2, 'DEMO CUSTOMER 002', '35-44'),
    (3, 'DEMO CUSTOMER 003', '45-54'),
    (4, 'DEMO CUSTOMER 004', '35-44'),
    (5, 'DEMO CUSTOMER 005', '25-34'),
    (6, 'DEMO CUSTOMER 006', '55+');

INSERT INTO hotels (hotel_id, hotel_name, city) VALUES
    (1, 'DEMO HOTEL COAST', 'Antalya'),
    (2, 'DEMO HOTEL BAY', 'Muğla'),
    (3, 'DEMO HOTEL GARDEN', 'İzmir');

INSERT INTO reservations (
    reservation_id, customer_id, hotel_id, booking_date, arrival_date,
    nights, adults, children, total_amount, paid_amount, balance_amount, booking_status
) VALUES
    (1,  1, 1, '2026-01-05', '2026-06-10', 5, 2, 0, 5000, 5000,    0, 'accepted'),
    (2,  2, 2, '2025-03-01', '2025-07-10', 4, 2, 1, 4000, 4000,    0, 'accepted'),
    (3,  2, 2, '2026-02-01', '2026-07-10', 5, 2, 1, 5500, 5000,  500, 'accepted'),
    (4,  3, 3, '2024-05-01', '2024-08-01', 3, 1, 0, 3000, 3000,    0, 'accepted'),
    (5,  4, 1, '2023-01-01', '2023-06-01', 4, 2, 0, 2500, 2500,    0, 'accepted'),
    (6,  4, 2, '2024-01-10', '2024-06-01', 5, 2, 0, 2800, 2800,    0, 'accepted'),
    (7,  5, 3, '2023-02-01', '2023-07-10', 6, 2, 2, 3200, 3200,    0, 'accepted'),
    (8,  5, 1, '2026-03-01', '2026-07-15', 7, 2, 2, 6000, 6000,    0, 'accepted'),
    (9,  6, 3, '2025-04-01', '2025-09-01', 4, 1, 0, 3800, 3800,    0, 'accepted'),
    (10, 6, 3, '2026-04-01', '2026-09-01', 5, 1, 0, 4800, 4800,    0, 'accepted'),
    (11, 1, 2, '2025-02-01', '2025-06-01', 4, 2, 0, -700, -700,    0, 'refunded');

