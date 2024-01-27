CREATE PROCEDURE CreateSalary (
    IN p_EmployeeId INT,
    IN p_Amount DECIMAL(10, 2),
    IN p_EffectiveDate DATE,
    IN p_NextReviewDate DATE,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    INSERT INTO Salaries (EmployeeId, Amount, EffectiveDate, NextReviewDate)
    VALUES (p_EmployeeId, p_Amount, p_EffectiveDate, p_NextReviewDate);
END;