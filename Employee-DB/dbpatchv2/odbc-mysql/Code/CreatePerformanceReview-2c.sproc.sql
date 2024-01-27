CREATE PROCEDURE CreatePerformanceReview (
    IN p_EmployeeId INT,
    IN p_ReviewDate DATE,
    IN p_PerformanceRating INT,
    IN p_Comments VARCHAR(255),
    IN p_PerformanceGoals TEXT,
    IN p_EndUserName VARCHAR(100)
)
BEGIN
    INSERT INTO PerformanceReviews (EmployeeId, ReviewDate, PerformanceRating, Comments, PerformanceGoals)
    VALUES (p_EmployeeId, p_ReviewDate, p_PerformanceRating, p_Comments, p_PerformanceGoals);
END;