CREATE PROCEDURE ReadDepartment (
    IN p_DepartmentId INT
)
BEGIN
    SELECT DepartmentId, Name, Description, DepartmentHeadId
    FROM Department 
    WHERE DepartmentId = p_DepartmentId;
END;