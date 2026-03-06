-- Layer 1b: Salary Tracking - Create Salary Table
-- Based on SCHEMA_DESIGN.md specifications
-- Maintains historical salary records for each employee

CREATE TABLE Salary (
    SalaryId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    EffectiveDate DATE NOT NULL,
    NextReviewDate DATE,
    CONSTRAINT FK_Salary_EmployeeId
        FOREIGN KEY (EmployeeId) REFERENCES Employee(EmployeeId)
);
