CREATE PROCEDURE DeleteProject (
    IN p_ProjectId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM Projects WHERE ProjectId = p_ProjectId;
END;