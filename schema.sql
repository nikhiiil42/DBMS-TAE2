-- TAE 2 DBMS
-- Luxury Automotive Dealership & Test Drive Management System
-- Target RDBMS: MySQL 8.0

CREATE DATABASE IF NOT EXISTS luxury_auto;
USE luxury_auto;

DROP VIEW IF EXISTS vw_vehicle_popularity;
DROP VIEW IF EXISTS vw_customer_testdrive_report;
DROP TRIGGER IF EXISTS trg_feedback_after_testdrive;
DROP PROCEDURE IF EXISTS sp_book_test_drive;

DROP TABLE IF EXISTS Feedback;
DROP TABLE IF EXISTS TestDrive;
DROP TABLE IF EXISTS Vehicle;
DROP TABLE IF EXISTS VIPMembership;
DROP TABLE IF EXISTS Showroom;
DROP TABLE IF EXISTS Manager;
DROP TABLE IF EXISTS Customer;

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(15) NOT NULL,
    City VARCHAR(50) NOT NULL,
    Profession VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Manager (
    ManagerID INT PRIMARY KEY,
    ManagerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(15) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Showroom (
    ShowroomID INT PRIMARY KEY,
    LocationName VARCHAR(100) NOT NULL UNIQUE,
    BrandSpecialty VARCHAR(50) NOT NULL,
    ManagerID INT NOT NULL,
    CONSTRAINT fk_showroom_manager
        FOREIGN KEY (ManagerID) REFERENCES Manager(ManagerID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE VIPMembership (
    MembershipID INT PRIMARY KEY,
    CustomerID INT NOT NULL UNIQUE,
    TierLevel VARCHAR(30) NOT NULL,
    StartDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_vip_tier CHECK (TierLevel IN ('Gold','Platinum','Black')),
    CONSTRAINT chk_vip_status CHECK (Status IN ('Active','Expired')),
    CONSTRAINT chk_vip_dates CHECK (ExpiryDate >= StartDate),
    CONSTRAINT fk_vip_customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Vehicle (
    VehicleID INT PRIMARY KEY,
    ShowroomID INT NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    Model VARCHAR(100) NOT NULL,
    BodyType VARCHAR(50) NOT NULL,
    DemoPrice DECIMAL(15,2) NOT NULL,
    CONSTRAINT chk_vehicle_price CHECK (DemoPrice > 0),
    CONSTRAINT chk_body_type CHECK (BodyType IN ('SUV','Coupe','Sedan')),
    CONSTRAINT fk_vehicle_showroom
        FOREIGN KEY (ShowroomID) REFERENCES Showroom(ShowroomID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE TestDrive (
    BookingID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    VehicleID INT NOT NULL,
    BookingDate DATE NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Confirmed',
    DriveStatus VARCHAR(20) NOT NULL DEFAULT 'No-Show',
    CONSTRAINT chk_booking_status CHECK (Status IN ('Confirmed','Cancelled')),
    CONSTRAINT chk_drive_status CHECK (DriveStatus IN ('Completed','No-Show')),
    CONSTRAINT fk_testdrive_customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_testdrive_vehicle
        FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Feedback (
    FeedbackID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    VehicleID INT NOT NULL,
    Rating INT NOT NULL,
    Comments TEXT,
    CONSTRAINT chk_feedback_rating CHECK (Rating BETWEEN 1 AND 5),
    CONSTRAINT fk_feedback_customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_feedback_vehicle
        FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Supporting indexes for common joins/filtering
CREATE INDEX idx_testdrive_customer ON TestDrive(CustomerID);
CREATE INDEX idx_testdrive_vehicle ON TestDrive(VehicleID);
CREATE INDEX idx_testdrive_bookingdate ON TestDrive(BookingDate);
CREATE INDEX idx_vehicle_brand_model ON Vehicle(Brand, Model);
CREATE INDEX idx_feedback_vehicle ON Feedback(VehicleID);
