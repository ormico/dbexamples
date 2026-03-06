-- Layer 0: Foundation - Add Employee Foreign Key
-- Employee.DepartmentId references Department.DepartmentId
-- This FK is added after both tables and Department FK exist to resolve circular dependency

ALTER TABLE Employee
ADD CONSTRAINT FK_Employee_DepartmentId
FOREIGN KEY (DepartmentId) REFERENCES Department(DepartmentId);
