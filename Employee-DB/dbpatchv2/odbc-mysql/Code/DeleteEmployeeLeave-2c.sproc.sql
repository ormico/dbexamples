CREATE PROCEDURE DeleteEmployeeLeave (
    IN p_LeaveId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM EmployeeLeaves WHERE LeaveId = p_LeaveId;
END;