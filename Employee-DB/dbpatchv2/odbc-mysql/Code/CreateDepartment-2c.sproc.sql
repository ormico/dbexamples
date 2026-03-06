CREATE PROCEDURE CreateDepartment (
    IN p_Name VARCHAR(100),
    IN p_Description VARCHAR(255),
    IN p_DepartmentHeadId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    INSERT INTO Department (Name, Description, DepartmentHeadId)
    VALUES (p_Name, p_Description, p_DepartmentHeadId);
END;