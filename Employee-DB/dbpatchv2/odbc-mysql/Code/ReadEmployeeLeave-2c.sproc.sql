CREATE PROCEDURE ReadEmployeeLeave (
    IN p_LeaveId INT
)
BEGIN
    SELECT LeaveId, EmployeeId, StartDate, EndDate, LeaveType, LeaveBalance
    FROM EmployeeLeave 
    WHERE LeaveId = p_LeaveId;
END;