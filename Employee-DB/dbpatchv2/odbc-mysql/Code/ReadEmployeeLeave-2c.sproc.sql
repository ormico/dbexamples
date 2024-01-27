CREATE PROCEDURE ReadEmployeeLeave (
    IN p_LeaveId INT
)
BEGIN
    SELECT LeaveId, EmployeeId, StartDate, EndDate, LeaveType, LeaveBalance
    FROM EmployeeLeaves 
    WHERE LeaveId = p_LeaveId;
END;