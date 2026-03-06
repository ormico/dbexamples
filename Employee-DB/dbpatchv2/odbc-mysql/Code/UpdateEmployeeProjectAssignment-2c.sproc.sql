CREATE PROCEDURE UpdateEmployeeProjectAssignment (
    IN p_AssignmentId INT,
    IN p_EmployeeId INT,
    IN p_ProjectId INT,
    IN p_AssignedDate DATE,
    IN p_Role VARCHAR(100),
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE EmployeeProjectAssignment
    SET EmployeeId = p_EmployeeId, ProjectId = p_ProjectId, AssignedDate = p_AssignedDate, Role = p_Role
    WHERE AssignmentId = p_AssignmentId;
END;