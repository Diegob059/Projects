-- Prior treatment:
-- Creation of unique product IDs.
-- Create a sequence to generate the product IDs
CREATE SEQUENCE ProductIDSequence
    START WITH 1
    INCREMENT BY 1;
GO

-- Create a table to store the product name to ID mapping
CREATE TABLE ProductIDMapping 
(
ProductID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR ProductIDSequence),
ProductName NVARCHAR(255) UNIQUE
);
GO

-- Insert unique product names from superstore_dataset into the mapping table
INSERT INTO ProductIDMapping (ProductName)
SELECT 
DISTINCT product_name 
FROM superstore_dataset
WHERE product_name IS NOT NULL
AND product_name NOT IN (SELECT ProductName FROM ProductIDMapping);
GO

-- Joining the tables and adding a year, month and day number columns
SELECT 
s.*,DATEPART(YEAR, order_date) AS Year,
DATEPART(MONTH, order_date) AS Month,DATEPART(DAY, order_date) AS Day
,p.ProductID
FROM superstore_dataset s
LEFT JOIN ProductIDMapping p ON s.product_name = p.ProductName;




-- Additional information for future analysis:
-- Find the segment average
WITH [Segment Average] AS 
(
SELECT 
segment,
AVG(profit) OVER (PARTITION BY (segment)) AS [Average Profit by Segment]
FROM superstore_dataset
)
SELECT * FROM [Segment Average];


-- Find the products that are more profitable and order them by profit margin
SELECT
product_name,
sales,
profit,
profit_margin
FROM superstore_dataset
WHERE profit_margin > 0
ORDER BY profit_margin DESC;

-- Find the manufactory with that produces the products with the most sales
SELECT 
manufactory,product_name,
SUM(sales) OVER (PARTITION BY (manufactory)) AS [Sales per product by manufactory],
profit,
profit_margin
FROM superstore_dataset
ORDER BY sales DESC;






