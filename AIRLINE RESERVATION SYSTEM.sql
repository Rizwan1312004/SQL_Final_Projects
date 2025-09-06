/* ============================================================
   AIRLINE RESERVATION SYSTEM  — MySQL 8.x
-- Author: Rizwan M
-- ------------------------------------------------------------
-- Purpose: End-to-end SQL backend for basic warehouse inventory tracking
-- Components: schema, sample data, queries, triggers, procedure
-- Tested dialect: MySQL
-- ------------------------------------------------------------
   ============================================================ */

DROP DATABASE IF EXISTS airline_reservation;
CREATE DATABASE airline_reservation;
USE airline_reservation;

/* --------------------------
   1) LOOKUP / MASTER TABLES
   -------------------------- */

-- Airports (normalized origin/destination)
CREATE TABLE airports (
  airport_code CHAR(3) PRIMARY KEY,
  airport_name VARCHAR(100) NOT NULL,
  city VARCHAR(80) NOT NULL
);

INSERT INTO airports (airport_code, airport_name, city) VALUES
('DEL','Indira Gandhi Intl','Delhi'),
('BOM','Chhatrapati Shivaji Intl','Mumbai'),
('BLR','Kempegowda Intl','Bengaluru'),
('MAA','Chennai Intl','Chennai'),
('HYD','Rajiv Gandhi Intl','Hyderabad'),
('CCU','Netaji Subhas Chandra Bose Intl','Kolkata'),
('AMD','Sardar Vallabhbhai Patel Intl','Ahmedabad'),
('COK','Cochin Intl','Kochi'),
('PNQ','Pune Intl','Pune'),
('GOI','Manohar Intl','Goa');

-- Aircraft types (small capacities to keep demo seats compact)
CREATE TABLE aircraft (
  aircraft_id INT PRIMARY KEY AUTO_INCREMENT,
  model VARCHAR(50) NOT NULL,
  seats_business INT NOT NULL,
  seats_economy INT NOT NULL,
  CHECK (seats_business > 0 AND seats_economy > 0)
);

INSERT INTO aircraft (model, seats_business, seats_economy) VALUES
('A320-200', 8, 24),
('B737-800', 8, 24),
('A321neo', 12, 36);

/* -------------
   2) CORE TABLES
   ------------- */

-- Flights
CREATE TABLE flights (
  flight_id INT PRIMARY KEY AUTO_INCREMENT,
  flight_no VARCHAR(8) NOT NULL,              -- e.g., 6E123, AI404
  aircraft_id INT NOT NULL,
  origin CHAR(3) NOT NULL,
  destination CHAR(3) NOT NULL,
  dep_time DATETIME NOT NULL,
  arr_time DATETIME NOT NULL,
  base_fare DECIMAL(10,2) NOT NULL,           -- base fare (INR) for economy
  UNIQUE KEY uq_flight_instance (flight_no, dep_time),
  CONSTRAINT fk_flight_aircraft FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id),
  CONSTRAINT fk_flight_origin FOREIGN KEY (origin) REFERENCES airports(airport_code),
  CONSTRAINT fk_flight_dest FOREIGN KEY (destination) REFERENCES airports(airport_code),
  CHECK (origin <> destination),
  CHECK (arr_time > dep_time)
);

-- Customers
CREATE TABLE customers (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  phone VARCHAR(20)
);

-- Bookings (no seat_id FK yet)
CREATE TABLE bookings (
  booking_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  flight_id INT NOT NULL,
  passenger_name VARCHAR(120) NOT NULL,
  booking_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('CONFIRMED','CANCELLED') NOT NULL DEFAULT 'CONFIRMED',
  seat_id BIGINT NULL,  -- FK will be added later
  amount_paid DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_booking_flight FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
) ENGINE=InnoDB;

-- Seats (now bookings already exists, so booking_id FK is safe)
CREATE TABLE seats (
  seat_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  flight_id INT NOT NULL,
  seat_no VARCHAR(5) NOT NULL,
  cabin ENUM('BUSINESS','ECONOMY') NOT NULL,
  is_booked BOOLEAN NOT NULL DEFAULT 0,
  booking_id INT NULL,
  UNIQUE KEY uq_flight_seat (flight_id, seat_no),
  CONSTRAINT fk_seat_flight FOREIGN KEY (flight_id) REFERENCES flights(flight_id),
  CONSTRAINT fk_seat_booking FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Finally, add the seat_id FK back into bookings
ALTER TABLE bookings
  ADD CONSTRAINT fk_booking_seat FOREIGN KEY (seat_id) REFERENCES seats(seat_id);

/* -----------------------------------
   3) SAMPLE DATA (Flights, Customers)
   ----------------------------------- */

-- 20 realistic flight instances between Sep 10–15, 2025
INSERT INTO flights (flight_no, aircraft_id, origin, destination, dep_time, arr_time, base_fare) VALUES
('6E201', 1, 'DEL','BOM','2025-09-10 07:00','2025-09-10 09:10', 4200.00),
('AI404',  2, 'BOM','DEL','2025-09-10 10:00','2025-09-10 12:15', 4500.00),
('SG515',  1, 'BLR','MAA','2025-09-10 08:30','2025-09-10 09:35', 2200.00),
('UK712',  3, 'HYD','BLR','2025-09-10 18:00','2025-09-10 19:05', 2400.00),
('6E333',  1, 'DEL','BLR','2025-09-11 06:45','2025-09-11 09:30', 5200.00),
('AI101',  2, 'BLR','DEL','2025-09-11 11:30','2025-09-11 14:10', 5100.00),
('SG207',  1, 'BOM','GOI','2025-09-11 16:00','2025-09-11 17:10', 2600.00),
('UK999',  3, 'GOI','BOM','2025-09-11 20:30','2025-09-11 21:45', 2700.00),
('6E777',  1, 'DEL','PNQ','2025-09-12 07:15','2025-09-12 09:10', 4100.00),
('AI222',  2, 'PNQ','DEL','2025-09-12 12:00','2025-09-12 13:55', 4200.00),
('SG808',  1, 'MAA','COK','2025-09-12 14:45','2025-09-12 15:45', 2100.00),
('UK123',  3, 'COK','MAA','2025-09-12 18:30','2025-09-12 19:30', 2050.00),
('6E909',  1, 'DEL','HYD','2025-09-13 06:50','2025-09-13 09:00', 4700.00),
('AI303',  2, 'HYD','DEL','2025-09-13 19:00','2025-09-13 21:10', 4800.00),
('SG121',  1, 'CCU','DEL','2025-09-14 07:25','2025-09-14 10:05', 4600.00),
('UK321',  3, 'DEL','CCU','2025-09-14 17:10','2025-09-14 19:45', 4550.00),
('6E654',  1, 'AMD','DEL','2025-09-15 08:30','2025-09-15 10:10', 3500.00),
('AI444',  2, 'DEL','AMD','2025-09-15 12:00','2025-09-15 13:40', 3600.00),
('SG343',  1, 'BLR','BOM','2025-09-15 06:00','2025-09-15 07:25', 3000.00),
('UK454',  3, 'BOM','BLR','2025-09-15 20:00','2025-09-15 21:25', 3050.00);

-- Customers (25)
INSERT INTO customers (full_name, email, phone) VALUES
('Riya Menon','riya.menon@example.com','9811111111'),
('Arjun Verma','arjun.verma@example.com','9822222222'),
('Karthik Rao','karthik.rao@example.com','9833333333'),
('Neha Kapoor','neha.kapoor@example.com','9844444444'),
('Sanjay Gupta','sanjay.gupta@example.com','9855555555'),
('Priya Iyer','priya.iyer@example.com','9866666666'),
('Vivek Sharma','vivek.sharma@example.com','9877777777'),
('Ananya Das','ananya.das@example.com','9888888888'),
('Rahul Jain','rahul.jain@example.com','9899999999'),
('Meera Nair','meera.nair@example.com','9900000001'),
('Nitin Khanna','nitin.khanna@example.com','9900000002'),
('Aisha Khan','aisha.khan@example.com','9900000003'),
('Varun Sethi','varun.sethi@example.com','9900000004'),
('Ishita Roy','ishita.roy@example.com','9900000005'),
('Rohan Bhat','rohan.bhat@example.com','9900000006'),
('Sneha Kulkarni','sneha.kulkarni@example.com','9900000007'),
('Harsh Patel','harsh.patel@example.com','9900000008'),
('Gayatri Joshi','gayatri.joshi@example.com','9900000009'),
('Manish Tiwari','manish.tiwari@example.com','9900000010'),
('Divya Singh','divya.singh@example.com','9900000011'),
('Akash Yadav','akash.yadav@example.com','9900000012'),
('Pooja Chawla','pooja.chawla@example.com','9900000013'),
('Aman Arora','aman.arora@example.com','9900000014'),
('Kavya Pillai','kavya.pillai@example.com','9900000015'),
('Ritika Bose','ritika.bose@example.com','9900000016');

/* ---------------------------------------------------
   4) SEAT BLUEPRINT + GENERATION FOR ALL FLIGHTS
   --------------------------------------------------- */

-- Seat map template for a 32-seat layout: 8 Business (rows 1–2, A-D) and 24 Economy (rows 3–8, A-D)
CREATE TABLE seat_map (
  seat_no VARCHAR(5) PRIMARY KEY,
  cabin ENUM('BUSINESS','ECONOMY') NOT NULL
);

INSERT INTO seat_map (seat_no, cabin) VALUES
('1A','BUSINESS'),('1B','BUSINESS'),('1C','BUSINESS'),('1D','BUSINESS'),
('2A','BUSINESS'),('2B','BUSINESS'),('2C','BUSINESS'),('2D','BUSINESS'),
('3A','ECONOMY'),('3B','ECONOMY'),('3C','ECONOMY'),('3D','ECONOMY'),
('4A','ECONOMY'),('4B','ECONOMY'),('4C','ECONOMY'),('4D','ECONOMY'),
('5A','ECONOMY'),('5B','ECONOMY'),('5C','ECONOMY'),('5D','ECONOMY'),
('6A','ECONOMY'),('6B','ECONOMY'),('6C','ECONOMY'),('6D','ECONOMY'),
('7A','ECONOMY'),('7B','ECONOMY'),('7C','ECONOMY'),('7D','ECONOMY'),
('8A','ECONOMY'),('8B','ECONOMY'),('8C','ECONOMY'),('8D','ECONOMY');

-- Generate seats for every flight from seat_map
INSERT INTO seats (flight_id, seat_no, cabin)
SELECT f.flight_id, sm.seat_no, sm.cabin
FROM flights f
JOIN seat_map sm ON 1=1;

/* ------------------------------------------
   5) TRIGGERS FOR BOOKINGS & CANCELLATIONS
   ------------------------------------------ */

DELIMITER $$

-- BEFORE INSERT: auto-assign the first available seat (Business if amount >= 2x base fare, else Economy)
CREATE TRIGGER trg_booking_before_insert
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
  DECLARE chosen_seat BIGINT;

  -- Prefer BUSINESS if passenger pays at least 2x base_fare, else ECONOMY
  IF NEW.amount_paid >= 2 * (SELECT base_fare FROM flights WHERE flight_id = NEW.flight_id) THEN
    SELECT s.seat_id INTO chosen_seat
    FROM seats s
    WHERE s.flight_id = NEW.flight_id AND s.cabin = 'BUSINESS' AND s.is_booked = 0
    ORDER BY s.seat_no
    LIMIT 1;
  END IF;

  IF chosen_seat IS NULL THEN
    SELECT s.seat_id INTO chosen_seat
    FROM seats s
    WHERE s.flight_id = NEW.flight_id AND s.cabin = 'ECONOMY' AND s.is_booked = 0
    ORDER BY s.seat_no
    LIMIT 1;
  END IF;

  IF chosen_seat IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No seats available on this flight';
  ELSE
    SET NEW.seat_id = chosen_seat;
  END IF;
END$$

-- AFTER INSERT: mark the assigned seat as booked & link back to booking
CREATE TRIGGER trg_booking_after_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
  UPDATE seats
    SET is_booked = 1,
        booking_id = NEW.booking_id
  WHERE seat_id = NEW.seat_id;
END$$

-- BEFORE UPDATE: if changing seat on a confirmed booking, validate availability
CREATE TRIGGER trg_booking_before_update
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
  IF NEW.seat_id <> OLD.seat_id AND NEW.status = 'CONFIRMED' THEN
    IF NEW.seat_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat cannot be NULL on a confirmed booking';
    END IF;
    -- Must be same flight, unbooked
    IF NOT EXISTS (
      SELECT 1 FROM seats s
      WHERE s.seat_id = NEW.seat_id
        AND s.flight_id = OLD.flight_id
        AND s.is_booked = 0
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Requested new seat is not available or not on this flight';
    END IF;
  END IF;
END$$

-- AFTER UPDATE: on cancellation, free the seat
CREATE TRIGGER trg_booking_after_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
  IF NEW.status = 'CANCELLED' AND OLD.status <> 'CANCELLED' THEN
    UPDATE seats
       SET is_booked = 0,
           booking_id = NULL
     WHERE seat_id = OLD.seat_id;
  END IF;

  -- If seat changed on a confirmed booking, mark new seat booked and old seat free
  IF NEW.status = 'CONFIRMED' AND NEW.seat_id <> OLD.seat_id THEN
    -- free old
    UPDATE seats SET is_booked = 0, booking_id = NULL WHERE seat_id = OLD.seat_id;
    -- book new
    UPDATE seats SET is_booked = 1, booking_id = NEW.booking_id WHERE seat_id = NEW.seat_id;
  END IF;
END$$

DELIMITER ;

/* -------------------------------------------
   6) SAMPLE BOOKINGS (40+, realistic spread)
   ------------------------------------------- */

-- Helper: pick some flights & book several seats on each, with varied fares
-- Note: amounts >= 2x base_fare will try for BUSINESS seats.

-- For readability, we’ll insert ~45 bookings across different flights.
INSERT INTO bookings (customer_id, flight_id, passenger_name, amount_paid)
VALUES
(1,  1, 'Riya Menon',           4200.00),
(2,  1, 'Arjun Verma',           8400.00),  -- should take Business
(3,  1, 'Karthik Rao',           4300.00),
(4,  2, 'Neha Kapoor',           9000.00),  -- Business
(5,  2, 'Sanjay Gupta',          4600.00),
(6,  3, 'Priya Iyer',            2200.00),
(7,  3, 'Vivek Sharma',          2300.00),
(8,  4, 'Ananya Das',            4800.00),  -- >2x? base 2400 → Business
(9,  4, 'Rahul Jain',            2400.00),
(10, 5, 'Meera Nair',            5200.00),
(11, 5, 'Nitin Khanna',         10400.00),  -- Business
(12, 6, 'Aisha Khan',            5100.00),
(13, 6, 'Varun Sethi',           5200.00),
(14, 7, 'Ishita Roy',            5200.00),  -- >2x base 2600 → Business
(15, 7, 'Rohan Bhat',            2700.00),
(16, 8, 'Sneha Kulkarni',        2700.00),
(17, 8, 'Harsh Patel',           5400.00),  -- Business
(18, 9, 'Gayatri Joshi',         4100.00),
(19, 9, 'Manish Tiwari',         8200.00),  -- Business
(20,10, 'Divya Singh',           4200.00),
(21,10, 'Akash Yadav',           4300.00),
(22,11, 'Pooja Chawla',          2100.00),
(23,11, 'Aman Arora',            4200.00),  -- Business (2x)
(24,12, 'Kavya Pillai',          2050.00),
(25,12, 'Ritika Bose',           4100.00),  -- Business (≈2x)
(1, 13, 'Riya Menon',            4700.00),
(2, 13, 'Arjun Verma',           9400.00),  -- Business
(3, 14, 'Karthik Rao',           4800.00),
(4, 14, 'Neha Kapoor',           9600.00),  -- Business
(5, 15, 'Sanjay Gupta',          4600.00),
(6, 15, 'Priya Iyer',            9200.00),  -- Business
(7, 16, 'Vivek Sharma',          4550.00),
(8, 16, 'Ananya Das',            9100.00),  -- Business
(9, 17, 'Rahul Jain',            3500.00),
(10,17, 'Meera Nair',            7000.00),  -- Business
(11,18, 'Nitin Khanna',          3600.00),
(12,18, 'Aisha Khan',            7200.00),  -- Business
(13,19, 'Varun Sethi',           3000.00),
(14,19, 'Ishita Roy',            6000.00),  -- Business
(15,20, 'Rohan Bhat',            3050.00),
(16,20, 'Sneha Kulkarni',        6100.00),  -- Business
(17, 1, 'Harsh Patel',           4300.00),
(18, 5, 'Gayatri Joshi',        10400.00),  -- Business
(19, 6, 'Manish Tiwari',         5100.00),
(20, 7, 'Divya Singh',           2600.00),
(21, 8, 'Akash Yadav',           2700.00),
(22, 9, 'Pooja Chawla',          8200.00);  -- Business

-- Demonstrate a cancellation (will free the seat via trigger)
UPDATE bookings
   SET status = 'CANCELLED'
 WHERE booking_id IN (5);  -- cancel one booking as example

/* ------------------------------------------
   7) VIEWS & QUERIES (availability & reports)
   ------------------------------------------ */

-- View: per-flight seat availability by cabin
CREATE OR REPLACE VIEW vw_flight_availability AS
SELECT
  f.flight_id,
  f.flight_no,
  f.origin,
  f.destination,
  f.dep_time,
  f.arr_time,
  s.cabin,
  COUNT(*)                AS total_seats,
  SUM(CASE WHEN s.is_booked=0 THEN 1 ELSE 0 END) AS seats_available,
  SUM(CASE WHEN s.is_booked=1 THEN 1 ELSE 0 END) AS seats_booked
FROM flights f
JOIN seats s ON s.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_no, f.origin, f.destination, f.dep_time, f.arr_time, s.cabin;

-- Quick check: availability for upcoming flights
-- SELECT * FROM vw_flight_availability ORDER BY dep_time, cabin;

-- View: simple searchable flights (with total remaining seats)
CREATE OR REPLACE VIEW vw_flights_search AS
SELECT
  f.flight_id, f.flight_no, f.origin, f.destination, f.dep_time, f.arr_time,
  f.base_fare,
  SUM(CASE WHEN s.is_booked=0 THEN 1 ELSE 0 END) AS total_seats_available
FROM flights f
JOIN seats s ON s.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_no, f.origin, f.destination, f.dep_time, f.arr_time, f.base_fare;

-- Example FLIGHT SEARCH query (by O/D, date, and minimum seats):
-- (Parameterize as needed in app code)
-- Find flights DEL -> BOM on 2025-09-10 with at least 2 seats:
SELECT * FROM vw_flights_search
 WHERE origin='DEL' AND destination='BOM'
   AND DATE(dep_time)='2025-09-10'
   AND total_seats_available >= 2
   ORDER BY dep_time;

-- Query: available seats on a particular flight (list free seat numbers)
SELECT seat_no, cabin FROM seats WHERE flight_id = 1 AND is_booked = 0 ORDER BY cabin, seat_no;

-- Booking Summary Report per flight (bookings, revenue, load factor)
CREATE OR REPLACE VIEW vw_booking_summary AS
SELECT
  f.flight_id,
  f.flight_no,
  f.origin,
  f.destination,
  f.dep_time,
  COUNT(b.booking_id)                           AS total_bookings,
  SUM(CASE WHEN b.status='CONFIRMED' THEN 1 ELSE 0 END) AS confirmed_bookings,
  SUM(CASE WHEN b.status='CANCELLED' THEN 1 ELSE 0 END) AS cancelled_bookings,
  SUM(CASE WHEN b.status='CONFIRMED' THEN b.amount_paid ELSE 0 END) AS revenue_confirmed,
  ROUND(
    100.0 * SUM(CASE WHEN s.is_booked=1 THEN 1 ELSE 0 END) / COUNT(s.seat_id)
  ,2) AS load_factor_pct
FROM flights f
LEFT JOIN seats s     ON s.flight_id = f.flight_id
LEFT JOIN bookings b  ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_no, f.origin, f.destination, f.dep_time;

-- Quick check:
SELECT * FROM vw_booking_summary ORDER BY dep_time;

-- Convenience indexes
CREATE INDEX idx_flights_odt ON flights(origin, destination, dep_time);
CREATE INDEX idx_seats_flight ON seats(flight_id, is_booked);
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_flight ON bookings(flight_id, status);

/* ------------------------------------------
   8) EXAMPLE OPS (seat change & validation)
   ------------------------------------------ */

-- Example: change a confirmed booking to a specific free seat on same flight
-- (will fail if seat taken/not same flight)
UPDATE bookings SET seat_id = (
  SELECT seat_id FROM seats WHERE flight_id = 1 AND seat_no = '3D' AND is_booked=0
  ) WHERE booking_id = 1;

-- Example: cancel a booking (frees the seat)
UPDATE bookings SET status='CANCELLED' WHERE booking_id = 2;
