CREATE PROCEDURE ReadProject (
    IN p_ProjectId INT
)
BEGIN
    SELECT ProjectId, Name, Description, StartDate, EndDate, Budget
    FROM Projects 
    WHERE ProjectId = p_ProjectId;
END;