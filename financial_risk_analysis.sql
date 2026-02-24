-- 1. Create database and table
CREATE DATABASE FinancialRisk;
GO
USE FinancialRisk;
GO
CREATE TABLE loan_raw (
    ID INT,
    loan_amount FLOAT,
    income FLOAT,
    Credit_Score INT,
    LTV FLOAT,
    dtir1 FLOAT,
    Status INT,
    loan_type VARCHAR(50),
    loan_purpose VARCHAR(100),
    Region VARCHAR(50),
    Gender VARCHAR(10),
    age INT,
    Security_Type VARCHAR(50),
    Credit_Worthiness VARCHAR(50)
);
-- 2. Initial data exploration
SELECT TOP 10 * FROM Loan_Default;
SELECT COUNT(*) FROM Loan_Default;
SELECT COUNT(*) AS Total_Rows, COUNT(income) AS NonNull_Income FROM Loan_Default;
SELECT * INTO loan_cleaned FROM Loan_Default;
SELECT * FROM loan_cleaned WHERE income IS NULL OR LTV IS NULL OR Credit_Score IS NULL; 
SELECT MAX(loan_amount), MIN (loan_amount) FROM loan_cleaned;
SELECT MAX(dtir1), MIN(dtir1) FROM loan_cleaned;
SELECT income FROM loan_cleaned WHERE income < 0;
SELECT LTV FROM loan_cleaned WHERE LTV > 100;
-- 3. Data cleaning
DECLARE @MedianLTV FLOAT;
SELECT @MedianLTV = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY LTV) OVER () FROM loan_cleaned;
UPDATE loan_cleaned SET LTV = @MedianLTV WHERE LTV IS NULL;
-- 4. Feature engineering
ALTER TABLE loan_cleaned ADD High_DTI_Risk BIT;
UPDATE loan_cleaned SET High_DTI_Risk = CASE WHEN dtir1 > 43 THEN 1 ELSE 0 END;
ALTER TABLE loan_cleaned ADD High_LTV_Risk BIT;
UPDATE loan_cleaned SET High_LTV_Risk = CASE WHEN LTV > 80 THEN 1 ELSE 0 END;
-- 5. Analysis
SELECT COUNT(*) AS Total_Loans,SUM(CAST(Status AS INT)) AS Total_Defaults, CAST(SUM(CAST(Status AS INT)) AS FLOAT)/COUNT(*) AS Default_Rate FROM loan_cleaned;
SELECT 
    CASE 
        WHEN Credit_Score < 600 THEN 'Poor' 
        WHEN Credit_Score BETWEEN 600 AND 699 THEN 'Fair' 
        WHEN Credit_Score BETWEEN 700 AND 749 THEN 'Good' 
        ELSE 'Excellent' 
    END AS Credit_Band, 
    COUNT(*) AS Loans, 
    SUM(CAST(Status AS INT)) AS Defaults, 
    SUM(CAST(Status AS FLOAT)) / COUNT(*) AS Default_Rate 
FROM loan_cleaned 
GROUP BY 
    CASE 
        WHEN Credit_Score < 600 THEN 'Poor' 
        WHEN Credit_Score BETWEEN 600 AND 699 THEN 'Fair' 
        WHEN Credit_Score BETWEEN 700 AND 749 THEN 'Good' 
        ELSE 'Excellent' 
    END 
ORDER BY Default_Rate DESC;
SELECT * FROM loan_cleaned WHERE High_DTI_Risk = 1
  AND High_LTV_Risk = 1
  AND Credit_Score < 650;