-- Layer 0: Foundation - Create Department Table
-- Based on SCHEMA_DESIGN.md specifications
-- Table must be created without foreign key to Employee (circular reference)

CREATE TABLE Department (
    DepartmentId INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    DepartmentHeadId INT  -- FK constraint added later
);
