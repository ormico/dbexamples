CREATE PROCEDURE DeleteSalary (
    IN p_SalaryId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM Salaries WHERE SalaryId = p_SalaryId;
END;