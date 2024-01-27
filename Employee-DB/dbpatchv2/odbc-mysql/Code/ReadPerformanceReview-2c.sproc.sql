CREATE PROCEDURE ReadPerformanceReview (
    IN p_ReviewId INT
)
BEGIN
    SELECT ReviewId, EmployeeId, ReviewDate, PerformanceRating, Comments, PerformanceGoals
    FROM PerformanceReviews 
    WHERE ReviewId = p_ReviewId;
END;