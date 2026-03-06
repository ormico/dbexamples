-- Layer 1a: Employee Roles - Add RoleId to Employee
-- Phase 1: Add as optional column (nullable)

ALTER TABLE Employee
ADD COLUMN RoleId INT;
