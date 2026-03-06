-- Layer 1a: Employee Roles - Create Role Table
-- Based on SCHEMA_DESIGN.md specifications

CREATE TABLE Role (
    RoleId INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    Description VARCHAR(255)
);
