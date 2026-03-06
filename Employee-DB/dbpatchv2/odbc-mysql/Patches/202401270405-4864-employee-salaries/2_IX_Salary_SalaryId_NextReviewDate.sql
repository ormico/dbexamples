
CREATE INDEX IX_Salary_SalaryId_NextReviewDate
ON Salary 
(
	SalaryId,
	NextReviewDate
);
