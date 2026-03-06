CREATE PROCEDURE DeletePerformanceReview (
    IN p_ReviewId INT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    DELETE FROM PerformanceReview WHERE ReviewId = p_ReviewId;
END;