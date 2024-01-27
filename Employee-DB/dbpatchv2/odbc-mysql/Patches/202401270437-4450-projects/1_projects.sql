CREATE TABLE Projects (
    ProjectId INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    StartDate DATE,
    EndDate DATE,
    Budget DECIMAL(18, 2)
);
