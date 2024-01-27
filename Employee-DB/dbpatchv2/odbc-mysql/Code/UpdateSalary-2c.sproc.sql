CREATE PROCEDURE UpdateSalary (
    IN p_SalaryId INT,
    IN p_EmployeeId INT,
    IN p_Amount DECIMAL(10, 2),
    IN p_EffectiveDate DATE,
    IN p_NextReviewDate DATE,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE Salaries
    SET EmployeeId = p_EmployeeId, Amount = p_Amount, EffectiveDate = p_EffectiveDate, NextReviewDate = p_NextReviewDate
    WHERE SalaryId = p_SalaryId;
END;