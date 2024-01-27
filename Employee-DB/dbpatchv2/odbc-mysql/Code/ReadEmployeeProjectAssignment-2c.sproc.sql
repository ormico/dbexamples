CREATE PROCEDURE ReadEmployeeProjectAssignment (
    IN p_AssignmentId INT
)
BEGIN
    SELECT AssignmentId, EmployeeId, ProjectId, AssignedDate, Role
    FROM EmployeeProjectAssignments 
    WHERE AssignmentId = p_AssignmentId;
END;