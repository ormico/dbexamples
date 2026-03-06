-- Layer 0: Foundation - Create Employee Table
-- Based on SCHEMA_DESIGN.md specifications
-- Table must be created without foreign key to Department (circular reference)

CREATE TABLE Employee (
    EmployeeId INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100),
    HireDate DATE NOT NULL,
    Status VARCHAR(50),
    StreetAddress VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(100),
    ZipCode VARCHAR(20),
    Country VARCHAR(100),
    DepartmentId INT  -- FK constraint added later
);
