-- Layer 1b: Salary Tracking - Create Index on NextReviewDate
-- Enables fast queries for upcoming salary reviews

CREATE INDEX IX_Salary_NextReviewDate
ON Salary(NextReviewDate);
