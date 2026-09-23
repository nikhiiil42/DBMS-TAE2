-- TAE-2 DBMS PROJECT
-- Luxury Automotive Dealership & Test Drive Management System
-- Database: MySQL
-- File: queries.sql

USE luxury_auto;

-- 1. DATABASE VERIFICATION
-- Display all tables.
SHOW TABLES;

-- Check table structures.
DESCRIBE Customer;
DESCRIBE VIPMembership;
DESCRIBE Showroom;
DESCRIBE Manager;
DESCRIBE Vehicle;
DESCRIBE TestDrive;
DESCRIBE Feedback;

-- 2. RECORD COUNT VERIFICATION
-- Verify the number of records in all core tables.
SELECT 'Customer' AS TableName, COUNT(*) AS TotalRecords FROM Customer
UNION ALL
SELECT 'VIPMembership', COUNT(*) FROM VIPMembership
UNION ALL
SELECT 'Showroom', COUNT(*) FROM Showroom
UNION ALL
SELECT 'Manager', COUNT(*) FROM Manager
UNION ALL
SELECT 'Vehicle', COUNT(*) FROM Vehicle
UNION ALL
SELECT 'TestDrive', COUNT(*) FROM TestDrive
UNION ALL
SELECT 'Feedback', COUNT(*) FROM Feedback;

-- 3. MULTI-TABLE INNER JOIN
-- Combine customer, test-drive, vehicle and showroom information.
SELECT
    c.FullName,
    c.City,
    v.Brand,
    v.Model,
    s.LocationName,
    td.BookingDate,
    td.Status,
    td.DriveStatus
FROM Customer c
INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
INNER JOIN Showroom s ON v.ShowroomID = s.ShowroomID;

-- 4. OUTER JOIN
-- Show every showroom and its total number of test-drive bookings.
-- LEFT JOIN keeps showrooms even when they have no bookings.
SELECT
    s.LocationName,
    s.BrandSpecialty,
    COUNT(td.BookingID) AS TotalBookings
FROM Showroom s
LEFT JOIN Vehicle v ON s.ShowroomID = v.ShowroomID
LEFT JOIN TestDrive td ON v.VehicleID = td.VehicleID
GROUP BY s.ShowroomID, s.LocationName, s.BrandSpecialty
ORDER BY TotalBookings DESC;

-- 5. SELF JOIN
-- Find pairs of customers from the same city.
-- CustomerID < CustomerID avoids duplicate/reverse pairs.
SELECT
    c1.FullName AS Customer1,
    c2.FullName AS Customer2,
    c1.City
FROM Customer c1
INNER JOIN Customer c2
    ON c1.City = c2.City
   AND c1.CustomerID < c2.CustomerID;

-- 6. GROUP BY + HAVING
-- Count bookings for each vehicle and show vehicles with at least 2 bookings.
SELECT
    v.Brand,
    v.Model,
    COUNT(td.BookingID) AS TotalBookings
FROM Vehicle v
INNER JOIN TestDrive td ON v.VehicleID = td.VehicleID
GROUP BY v.Brand, v.Model
HAVING COUNT(td.BookingID) >= 2
ORDER BY TotalBookings DESC;

-- 7. CORRELATED SUBQUERY
-- Find customers who have completed a test drive.
-- The inner query refers to the current outer CustomerID.
SELECT
    c.CustomerID,
    c.FullName,
    c.Email
FROM Customer c
WHERE EXISTS (
    SELECT 1
    FROM TestDrive td
    WHERE td.CustomerID = c.CustomerID
      AND td.DriveStatus = 'Completed'
);

-- 8. AGGREGATE FUNCTIONS
-- Show booking count and average rating for each vehicle.
SELECT
    v.VehicleID,
    v.Brand,
    v.Model,
    COUNT(DISTINCT td.BookingID) AS TotalBookings,
    ROUND(AVG(f.Rating), 2) AS AverageRating
FROM Vehicle v
LEFT JOIN TestDrive td ON v.VehicleID = td.VehicleID
LEFT JOIN Feedback f ON v.VehicleID = f.VehicleID
GROUP BY v.VehicleID, v.Brand, v.Model;

-- 9. STORED PROCEDURE
-- Remove old procedure if present, then create a parameterized procedure.
-- It accepts CustomerID and returns that customer's bookings.
DROP PROCEDURE IF EXISTS GetCustomerBookings;

DELIMITER //
CREATE PROCEDURE GetCustomerBookings(IN p_CustomerID INT)
BEGIN
    SELECT
        c.FullName,
        c.Email,
        v.Brand,
        v.Model,
        td.BookingDate,
        td.Status,
        td.DriveStatus
    FROM Customer c
    INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
    INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
    WHERE c.CustomerID = p_CustomerID;
END //
DELIMITER ;

-- Execute the procedure with sample customer IDs.
CALL GetCustomerBookings(1);
CALL GetCustomerBookings(10);

-- 10. TRIGGER
-- Allow feedback only when the customer has a confirmed,
-- completed test drive for the selected vehicle.
DROP TRIGGER IF EXISTS trg_feedback_completed_drive;

DELIMITER //
CREATE TRIGGER trg_feedback_completed_drive
BEFORE INSERT ON Feedback
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM TestDrive
        WHERE CustomerID = NEW.CustomerID
          AND VehicleID = NEW.VehicleID
          AND DriveStatus = 'Completed'
          AND Status = 'Confirmed'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Feedback allowed only after a completed confirmed test drive';
    END IF;
END //
DELIMITER ;

-- Verify the trigger.
SHOW TRIGGERS;

-- 11. VIEW 1
-- Reusable view containing customer test-drive details.
DROP VIEW IF EXISTS vw_customer_testdrive_details;

CREATE VIEW vw_customer_testdrive_details AS
SELECT
    c.CustomerID,
    c.FullName,
    c.City,
    v.Brand,
    v.Model,
    s.LocationName,
    td.BookingDate,
    td.Status,
    td.DriveStatus
FROM Customer c
INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
INNER JOIN Showroom s ON v.ShowroomID = s.ShowroomID;

-- Test View 1.
SELECT * FROM vw_customer_testdrive_details LIMIT 10;

-- 12. VIEW 2
-- Summarize total bookings and average rating for every vehicle.
-- Separate derived tables avoid multiplying booking and feedback rows.
DROP VIEW IF EXISTS vw_vehicle_booking_summary;

CREATE VIEW vw_vehicle_booking_summary AS
SELECT
    v.VehicleID,
    v.Brand,
    v.Model,
    v.BodyType,
    COALESCE(b.TotalBookings, 0) AS TotalBookings,
    COALESCE(f.AvgRating, 0) AS AvgRating
FROM Vehicle v
LEFT JOIN (
    SELECT VehicleID, COUNT(*) AS TotalBookings
    FROM TestDrive
    GROUP BY VehicleID
) b ON v.VehicleID = b.VehicleID
LEFT JOIN (
    SELECT VehicleID, ROUND(AVG(Rating), 2) AS AvgRating
    FROM Feedback
    GROUP BY VehicleID
) f ON v.VehicleID = f.VehicleID;

-- Test View 2.
SELECT *
FROM vw_vehicle_booking_summary
ORDER BY TotalBookings DESC
LIMIT 10;

-- Verify both views.
SHOW FULL TABLES IN luxury_auto
WHERE TABLE_TYPE = 'VIEW';

-- 13. INDEX VERIFICATION
-- Display existing indexes used by the project.
SHOW INDEX FROM TestDrive;
SHOW INDEX FROM Vehicle;
SHOW INDEX FROM Feedback;

-- 14. EXPLAIN - QUERY 1
-- Inspect the execution plan for filtering by CustomerID and Status.
EXPLAIN
SELECT *
FROM TestDrive
WHERE CustomerID = 75
  AND Status = 'Confirmed';

-- 15. COMPOSITE INDEX - QUERY 1
-- Composite index for CustomerID + Status.
-- Run CREATE INDEX only if this index does not already exist.
CREATE INDEX idx_testdrive_customer_status
ON TestDrive(CustomerID, Status);

-- Check the execution plan after indexing.
EXPLAIN
SELECT *
FROM TestDrive
WHERE CustomerID = 75
  AND Status = 'Confirmed';

-- Show actual execution information.
EXPLAIN ANALYZE
SELECT *
FROM TestDrive
WHERE CustomerID = 75
  AND Status = 'Confirmed';

-- 16. EXPLAIN - QUERY 2
-- Complex multi-table query filtered by date and booking status.
EXPLAIN
SELECT
    c.FullName,
    v.Brand,
    v.Model,
    s.LocationName
FROM Customer c
INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
INNER JOIN Showroom s ON v.ShowroomID = s.ShowroomID
WHERE td.BookingDate BETWEEN '2026-07-01' AND '2026-09-30'
  AND td.Status = 'Confirmed';

-- 17. EXPLAIN ANALYZE - QUERY 2
-- Show actual execution behaviour of the complex query.
EXPLAIN ANALYZE
SELECT
    c.FullName,
    v.Brand,
    v.Model,
    s.LocationName
FROM Customer c
INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
INNER JOIN Showroom s ON v.ShowroomID = s.ShowroomID
WHERE td.BookingDate BETWEEN '2026-07-01' AND '2026-09-30'
  AND td.Status = 'Confirmed';

-- 18. COMPOSITE INDEX - QUERY 2
-- Composite index for Status + BookingDate.
-- Run CREATE INDEX only if this index does not already exist.
CREATE INDEX idx_testdrive_status_bookingdate
ON TestDrive(Status, BookingDate);

-- Check the execution plan after adding the second composite index.
EXPLAIN
SELECT
    c.FullName,
    v.Brand,
    v.Model,
    s.LocationName
FROM Customer c
INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
INNER JOIN Showroom s ON v.ShowroomID = s.ShowroomID
WHERE td.BookingDate BETWEEN '2026-07-01' AND '2026-09-30'
  AND td.Status = 'Confirmed';

-- Actual execution analysis after indexing.
EXPLAIN ANALYZE
SELECT
    c.FullName,
    v.Brand,
    v.Model,
    s.LocationName
FROM Customer c
INNER JOIN TestDrive td ON c.CustomerID = td.CustomerID
INNER JOIN Vehicle v ON td.VehicleID = v.VehicleID
INNER JOIN Showroom s ON v.ShowroomID = s.ShowroomID
WHERE td.BookingDate BETWEEN '2026-07-01' AND '2026-09-30'
  AND td.Status = 'Confirmed';

-- 19. FINAL VERIFICATION
-- Verify final database objects.
SHOW TABLES;

SHOW PROCEDURE STATUS
WHERE Db = 'luxury_auto';

SHOW TRIGGERS;

SHOW FULL TABLES IN luxury_auto
WHERE TABLE_TYPE = 'VIEW';

SHOW INDEX FROM TestDrive;

-- ============================================================
-- END OF queries.sql
-- ============================================================
