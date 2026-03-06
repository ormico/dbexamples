-- Layer 3: Project Management - Create EmployeeProjectAssignment Table
-- Based on SCHEMA_DESIGN.md specifications
-- Junction table creating many-to-many relationship between employees and projects

CREATE TABLE EmployeeProjectAssignment (
    AssignmentId INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeId INT NOT NULL,
    ProjectId INT NOT NULL,
    AssignedDate DATE NOT NULL,
    Role VARCHAR(100),
    CONSTRAINT FK_EmployeeProjectAssignment_EmployeeId
        FOREIGN KEY (EmployeeId) REFERENCES Employee(EmployeeId),
    CONSTRAINT FK_EmployeeProjectAssignment_ProjectId
        FOREIGN KEY (ProjectId) REFERENCES Project(ProjectId)
);
