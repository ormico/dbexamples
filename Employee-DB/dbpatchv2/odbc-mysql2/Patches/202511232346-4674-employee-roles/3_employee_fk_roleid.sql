-- Layer 1a: Employee Roles - Add Foreign Key Constraint
-- Employee.RoleId references Role.RoleId

ALTER TABLE Employee
ADD CONSTRAINT FK_Employee_RoleId
FOREIGN KEY (RoleId) REFERENCES Role(RoleId);
