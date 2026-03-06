CREATE PROCEDURE DeleteDepartment (
    IN p_DepartmentId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM Department WHERE DepartmentId = p_DepartmentId;
END;