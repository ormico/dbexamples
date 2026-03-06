-- Layer 3: Project Management - Create Project Table
-- Based on SCHEMA_DESIGN.md specifications
-- Represents projects or initiatives within the organization

CREATE TABLE Project (
    ProjectId INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    StartDate DATE,
    EndDate DATE,
    Budget DECIMAL(18, 2)
);
