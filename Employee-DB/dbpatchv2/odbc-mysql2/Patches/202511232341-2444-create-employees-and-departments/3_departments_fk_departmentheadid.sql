-- Layer 0: Foundation - Add Department Foreign Key
-- Department.DepartmentHeadId references Employee.EmployeeId
-- This FK is added after both tables exist to resolve circular dependency

ALTER TABLE Department
ADD CONSTRAINT FK_Department_DepartmentHeadId
FOREIGN KEY (DepartmentHeadId) REFERENCES Employee(EmployeeId);
