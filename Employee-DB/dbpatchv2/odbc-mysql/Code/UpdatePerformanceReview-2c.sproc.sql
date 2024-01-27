CREATE PROCEDURE UpdatePerformanceReview (
    IN p_ReviewId INT,
    IN p_EmployeeId INT,
    IN p_ReviewDate DATE,
    IN p_PerformanceRating INT,
    IN p_Comments VARCHAR(255),
    IN p_PerformanceGoals TEXT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    UPDATE PerformanceReviews
    SET EmployeeId = p_EmployeeId, ReviewDate = p_ReviewDate, PerformanceRating = p_PerformanceRating, Comments = p_Comments, PerformanceGoals = p_PerformanceGoals
    WHERE ReviewId = p_ReviewId;
END;