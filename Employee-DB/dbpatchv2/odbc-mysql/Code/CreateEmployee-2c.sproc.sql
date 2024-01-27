CREATE PROCEDURE CreateEmployee (
    IN p_FirstName VARCHAR(50),
    IN p_LastName VARCHAR(50),
    IN p_DepartmentId INT,
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
    INSERT INTO Employees (FirstName, LastName, DepartmentId, HireDate, Email, StreetAddress, City, State, ZipCode, Country, Status)
    VALUES (p_FirstName, p_LastName, p_DepartmentId, p_HireDate, p_Email, p_StreetAddress, p_City, p_State, p_ZipCode, p_Country, p_Status);
END;