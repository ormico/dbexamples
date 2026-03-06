CREATE PROCEDURE ReadSalary (
    IN p_SalaryId INT
)
BEGIN
    SELECT SalaryId, EmployeeId, Amount, EffectiveDate, NextReviewDate
    FROM Salary 
    WHERE SalaryId = p_SalaryId;
END;