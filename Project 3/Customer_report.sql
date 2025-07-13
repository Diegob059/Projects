--Customer Report
--1) Gather essential information susch as customer name, age 
--and transaction details.
--2) Segment customers into customer type (VIP, regular and new)
--and age groups
--3) Aggregate metrics such as total orders, total sales, total quantity,
--total products, and lifespan in months
--4) Calculate KPIs:
--	-Recency (months since last order)
--	-Avg order value
--	-Avg monthly spend

-- Encompass the whole query in a view for easy access
CREATE VIEW customer_report AS

-- CTE with the necessary columns and information for the report
WITH base_query AS
(
SELECT
-- Join the first and last names to get the complete customer name
CONCAT(C.first_name,' ',C.last_name) AS [Customer Name],
C.first_name AS [First Name],
C.last_name AS [Last Name],
-- Get the customer age based on the difference between the current date
-- And their birthdate in years
DATEDIFF(YEAR,C.birthdate,GETDATE()) AS [Customer Age],
C.customer_ID AS [Customer ID],
C.customer_number AS [Customer Number],
C.customer_key AS [Customer Key],
F.order_number AS [Order Number],
F.product_key AS [Product Key],
F.quantity,
F.sales_amount AS [Sales Amount],
F.order_date AS [Order Date]
FROM [gold.fact_sales] AS F
LEFT JOIN [gold.dim_customers] AS C 
ON F.customer_key = C.customer_key
WHERE order_date IS NOT NULL
), 
-- 2) CTE with aggregations summarizing key metrics
-- at the customer level
Aggregations AS
(
SELECT
[Customer Key],
[Customer Number],
[Customer Name],
[Customer Age],
COUNT(DISTINCT([Order Number])) AS [Total Orders],
SUM([Sales Amount]) AS [Total Sales],
SUM(quantity) AS [Total Quantity],
COUNT(DISTINCT([Product Key])) AS [Total Products],
MAX([Order Date]) AS [Last Order],
DATEDIFF(MONTH, MIN([Order Date]), MAX([Order Date])) AS Lifespan
FROM base_query
GROUP BY 
[Customer Key],
[Customer Number],
[Customer Name],
[Customer Age]
)

-- 3) Divide customers into categories and age group

SELECT
-- Customer information
[Customer Key],
[Customer Number],
[Customer Name],
[Customer Age],
-- Age groups
CASE WHEN [Customer Age] < 20 THEN 'Under 20'
	 WHEN [Customer Age] BETWEEN 20 AND 29 THEN '20-29'
	 WHEN [Customer Age] BETWEEN 30 AND 39 THEN '30-39'
	 WHEN [Customer Age] BETWEEN 40 AND 49 THEN '40-49'
	 WHEN [Customer Age] BETWEEN 50 AND 59 THEN '50-59'
	 WHEN [Customer Age] BETWEEN 60 AND 69 THEN '60-69'
	 ELSE '70 and above'
END AS [Age Group],
-- Customer type based on lifespan and total sales
CASE WHEN Lifespan >= 12 AND [Total Sales] > 5000 THEN 'VIP'
	 WHEN Lifespan >= 12 AND [Total Sales] <= 5000 THEN 'Regular'
	 ELSE 'New'
END AS  [Customer Status],
-- Transaction details
[Total Orders],
[Total Sales],
[Total Quantity],
[Total Products],
[Last Order],
Lifespan,
-- KPIs
-- Recency
DATEDIFF(MONTH, [Last Order], GETDATE()) AS Recency,
-- Avg order value. If the total orders are 0, the case when
-- prevents an error by dividing by 0
CASE WHEN [Total Orders] = 0 THEN 0
	 ELSE [Total Sales] / [Total Orders]
END AS [Avg Order Value],
-- Avg monthly spend. Use of case when for customers that have only made
-- one purchase and have therefore a lifespan of 0. This avoids an error 
-- by dividing by 0
CASE WHEN Lifespan = 0 THEN [Total Sales]
	 ELSE [Total Sales] / Lifespan
	END AS [Avg Monthly Spend]
FROM Aggregations

