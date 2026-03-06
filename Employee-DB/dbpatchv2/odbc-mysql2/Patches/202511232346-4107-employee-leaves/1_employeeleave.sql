-- Layer 1c: Leave Management - Create EmployeeLeave Table
-- Based on SCHEMA_DESIGN.md specifications
-- Tracks employee leave requests and time off

CREATE TABLE EmployeeLeave (
    LeaveId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    LeaveType VARCHAR(50) NOT NULL,
    LeaveBalance INT,
    CONSTRAINT FK_EmployeeLeave_EmployeeId
        FOREIGN KEY (EmployeeId) REFERENCES Employee(EmployeeId)
);
