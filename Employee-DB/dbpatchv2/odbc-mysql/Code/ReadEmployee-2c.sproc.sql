CREATE PROCEDURE ReadEmployee (
    IN p_EmployeeId INT
)
BEGIN
    SELECT EmployeeId, FirstName, LastName, DepartmentId, RoleId, HireDate, Email, StreetAddress, City, State, ZipCode, Country, Status
    FROM Employees 
    WHERE EmployeeId = p_EmployeeId;
END;