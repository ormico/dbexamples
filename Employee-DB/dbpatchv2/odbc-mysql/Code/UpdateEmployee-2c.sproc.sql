CREATE PROCEDURE UpdateEmployee (
    IN p_EmployeeId INT,
    IN p_FirstName VARCHAR(50),
    IN p_LastName VARCHAR(50),
    IN p_DepartmentId INT,
    IN p_RoleId INT,
    IN p_HireDate DATE,
    IN p_Email VARCHAR(100),
    IN p_StreetAddress VARCHAR(255),
    IN p_City VARCHAR(100),
    IN p_State VARCHAR(100),
    IN p_ZipCode VARCHAR(20),
    IN p_Country VARCHAR(100),
    IN p_Status VARCHAR(50),
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE Employees
    SET FirstName = p_FirstName, LastName = p_LastName, DepartmentId = p_DepartmentId, RoleId = p_RoleId, HireDate = p_HireDate, Email = p_Email, 
        StreetAddress = p_StreetAddress, City = p_City, State = p_State, ZipCode = p_ZipCode, Country = p_Country, Status = p_Status
    WHERE EmployeeId = p_EmployeeId;
END;