-- Layer 2: Performance Management - Create PerformanceReview Table
-- Based on SCHEMA_DESIGN.md specifications
-- Depends on ALL Layer 1 patches (roles, salaries, leaves)

CREATE TABLE PerformanceReview (
    ReviewId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    ReviewDate DATE NOT NULL,
    PerformanceRating INT NOT NULL,
    Comments VARCHAR(255),
    PerformanceGoals TEXT,
    CONSTRAINT FK_PerformanceReview_EmployeeId
        FOREIGN KEY (EmployeeId) REFERENCES Employee(EmployeeId)
);
