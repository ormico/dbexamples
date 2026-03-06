CREATE TABLE EmployeeProjectAssignment (
    AssignmentId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    ProjectId INT NOT NULL,
    AssignedDate DATE NOT NULL,
    Role VARCHAR(100),
    FOREIGN KEY (EmployeeId) REFERENCES Employee(EmployeeId),
    FOREIGN KEY (ProjectId) REFERENCES Project(ProjectId)
);
