CREATE PROCEDURE CreateEmployeeLeave (
    IN p_EmployeeId INT,
    IN p_StartDate DATE,
    IN p_EndDate DATE,
    IN p_LeaveType VARCHAR(50),
    IN p_LeaveBalance INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    INSERT INTO EmployeeLeave (EmployeeId, StartDate, EndDate, LeaveType, LeaveBalance)
    VALUES (p_EmployeeId, p_StartDate, p_EndDate, p_LeaveType, p_LeaveBalance);
END;