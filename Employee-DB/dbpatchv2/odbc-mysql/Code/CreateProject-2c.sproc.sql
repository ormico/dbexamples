CREATE PROCEDURE CreateProject (
    IN p_Name VARCHAR(100),
    IN p_Description VARCHAR(255),
    IN p_StartDate DATE,
    IN p_EndDate DATE,
    IN p_Budget DECIMAL(18, 2),
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    INSERT INTO Project (Name, Description, StartDate, EndDate, Budget)
    VALUES (p_Name, p_Description, p_StartDate, p_EndDate, p_Budget);
END;