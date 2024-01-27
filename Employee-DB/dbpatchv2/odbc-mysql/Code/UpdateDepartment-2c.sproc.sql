CREATE PROCEDURE UpdateDepartment (
    IN p_DepartmentId INT,
    IN p_Name VARCHAR(100),
    IN p_Description VARCHAR(255),
    IN p_DepartmentHeadId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE Departments
    SET Name = p_Name, Description = p_Description, DepartmentHeadId = p_DepartmentHeadId
    WHERE DepartmentId = p_DepartmentId;
END;