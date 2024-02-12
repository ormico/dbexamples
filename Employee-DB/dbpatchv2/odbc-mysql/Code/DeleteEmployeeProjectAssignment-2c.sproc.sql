CREATE PROCEDURE DeleteEmployeeProjectAssignment (
    IN p_AssignmentId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM EmployeeProjectAssignment WHERE AssignmentId = p_AssignmentId;
END;