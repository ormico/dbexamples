CREATE TABLE Salaries (
    SalaryId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT,
    Amount DECIMAL(10, 2) NOT NULL,
    EffectiveDate DATE NOT NULL,
    NextReviewDate DATE,
    FOREIGN KEY (EmployeeId) REFERENCES Employees(EmployeeId)
);
