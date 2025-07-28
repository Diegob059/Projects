-- Product report
-- 1) Gather essential fields such as product name, category, subcategory,
-- and cost.
-- 2) Segment products by revenue (High performers, Mid rage and Low performers)
-- 3) Aggregate: total orders, total sales, total quantity, total customers and lifespan
-- 4) KPIs: Recency, avg order revenue,avg monthly revenue


CREATE VIEW product_report AS

-- CTE with the required information
WITH base_query AS 
(
SELECT
P.product_name AS [Product Name],
P.product_key AS [Product Key],
P.product_id AS [Product ID],
P.product_number AS [Product Number],
P.category,
P.subcategory,
P.cost,
C.customer_key AS [Customer Key],
C.customer_id AS [Customer ID],
F.quantity,
F.sales_amount AS [Sales Amount],
F.order_number AS [Order Number],
F.order_date AS [Order Date]
FROM [gold.fact_sales] AS F
LEFT JOIN [gold.dim_products] AS P ON F.product_key = P.product_key
LEFT JOIN [gold.dim_customers] AS C ON F.customer_key = C.customer_key
WHERE order_date IS NOT NULL
),
-- CTE with the required aggregations
Aggregates AS
(
SELECT 
[Product Name],
[Product Key],
[Product ID],
[Product Number],
category,
subcategory,
cost,
MAX([Order Date]) AS [Last Order],
COUNT(DISTINCT([Order Number])) AS [Total Orders],
SUM ([Sales Amount]) AS [Total Product Sales],
SUM(quantity) AS [Total Quantity],
COUNT(DISTINCT([Customer Key])) AS [Total Customers],
DATEDIFF(MONTH, MIN([Order Date]), MAX([Order Date])) AS lifespan,
ROUND(AVG(CAST ([Sales Amount] AS FLOAT) / NULLIF(quantity,0)),1) AS [Avg Selling Price]
FROM base_query
GROUP BY
[Product Name],
[Product Key],
[Product ID],
[Product Number],
category,
subcategory,
cost
)

-- Final query and computation of the required KPIs, as well as segmentations
SELECT
[Product Name],
[Product Key],
[Product ID],
[Product Number],
category,
subcategory,
[Avg Selling Price],
lifespan,
-- Segmentation
CASE WHEN [Total Product Sales] > 50000  THEN 'High Performer'
	 WHEN [Total Product Sales] >= 10000 THEN 'Mid Range'
	 ELSE 'Low performer'
END AS [Product Performance],
[Total Product Sales],
[Total Orders],
[Total Quantity],
[Total Customers],
-- KPIs
DATEDIFF(MONTH, [Last Order], GETDATE()) AS Recency,

CASE WHEN [Total Orders] = 0 THEN 0
	 ELSE [Total Product Sales] / [Total Orders]
END AS [Avg Order Revenue],

CASE WHEN Lifespan = 0 THEN [Total Product Sales]
	 ELSE [Total Product Sales] / lifespan
END AS [Avg Monthly Revenue]
FROM Aggregates

