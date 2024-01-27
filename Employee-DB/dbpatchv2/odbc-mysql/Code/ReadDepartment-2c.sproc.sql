CREATE PROCEDURE ReadDepartment (
    IN p_DepartmentId INT
)
BEGIN
    SELECT DepartmentId, Name, Description, DepartmentHeadId
    FROM Departments 
    WHERE DepartmentId = p_DepartmentId;
END;