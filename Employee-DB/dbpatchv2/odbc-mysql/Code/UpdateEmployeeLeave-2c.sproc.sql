CREATE PROCEDURE UpdateEmployeeLeave (
    IN p_LeaveId INT,
    IN p_EmployeeId INT,
    IN p_StartDate DATE,
    IN p_EndDate DATE,
    IN p_LeaveType VARCHAR(50),
    IN p_LeaveBalance INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE EmployeeLeaves
    SET EmployeeId = p_EmployeeId, StartDate = p_StartDate, EndDate = p_EndDate, LeaveType = p_LeaveType, LeaveBalance = p_LeaveBalance
    WHERE LeaveId = p_LeaveId;
END;