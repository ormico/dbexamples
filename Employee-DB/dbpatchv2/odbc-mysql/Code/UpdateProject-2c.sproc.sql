CREATE PROCEDURE UpdateProject (
    IN p_ProjectId INT,
    IN p_Name VARCHAR(100),
    IN p_Description VARCHAR(255),
    IN p_StartDate DATE,
    IN p_EndDate DATE,
    IN p_Budget DECIMAL(18, 2),
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE Project
    SET Name = p_Name, Description = p_Description, StartDate = p_StartDate, EndDate = p_EndDate, Budget = p_Budget
    WHERE ProjectId = p_ProjectId;
END;