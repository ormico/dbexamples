CREATE PROCEDURE DeleteEmployee (
    IN p_EmployeeId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM Employee WHERE EmployeeId = p_EmployeeId;
END;