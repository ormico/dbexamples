-- PerformanceReviews Table
CREATE TABLE PerformanceReviews (
    ReviewId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT,
    ReviewDate DATE NOT NULL,
    PerformanceRating INT NOT NULL,
    Comments VARCHAR(255),
    PerformanceGoals TEXT,
    FOREIGN KEY (EmployeeId) REFERENCES Employees(EmployeeId)
);
