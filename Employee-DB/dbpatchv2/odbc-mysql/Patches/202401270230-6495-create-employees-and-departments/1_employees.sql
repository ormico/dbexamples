CREATE TABLE Employees (
    EmployeeId INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DepartmentId INT,
    HireDate DATE NOT NULL,
    Email VARCHAR(100),
    StreetAddress VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(100),
    ZipCode VARCHAR(20),
    Country VARCHAR(100),
    Status VARCHAR(50)
);
