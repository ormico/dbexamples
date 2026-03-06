CREATE PROCEDURE CreateEmployeeProjectAssignment (
    IN p_EmployeeId INT,
    IN p_ProjectId INT,
    IN p_AssignedDate DATE,
    IN p_Role VARCHAR(100),
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    INSERT INTO EmployeeProjectAssignment (EmployeeId, ProjectId, AssignedDate, Role)
    VALUES (p_EmployeeId, p_ProjectId, p_AssignedDate, p_Role);
END;