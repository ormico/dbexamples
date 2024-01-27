CREATE TABLE EmployeeLeaves (
    LeaveId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    LeaveType VARCHAR(50) NOT NULL,
    LeaveBalance INT,
    FOREIGN KEY (EmployeeId) REFERENCES Employees(EmployeeId)
);
