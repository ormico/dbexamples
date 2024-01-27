CREATE PROCEDURE DeleteDepartment (
    IN p_DepartmentId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM Departments WHERE DepartmentId = p_DepartmentId;
END;