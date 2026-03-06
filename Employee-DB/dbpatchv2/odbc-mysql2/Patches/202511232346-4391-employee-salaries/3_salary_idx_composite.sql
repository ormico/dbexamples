-- Layer 1b: Salary Tracking - Create Composite Index
-- Optimizes queries that filter by salary ID and check review dates

CREATE INDEX IX_Salary_SalaryId_NextReviewDate
ON Salary(SalaryId, NextReviewDate);
