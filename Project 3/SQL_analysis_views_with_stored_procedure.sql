-- Use of a stored procedure to create multiple views for each one of the analysis to optimize the use
-- of the information and esasy accces.
CREATE OR ALTER PROCEDURE dbo.CreateAnalysisViews
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Change over time analysis view
    IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Change_Over_Time_Analysis' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('
        CREATE VIEW dbo.Change_Over_Time_Analysis AS
        SELECT
-- Select only the year and month of order_date
        DATETRUNC(MONTH, order_date) AS [Order Date],
        SUM(sales_amount) AS [Total Sales],
        COUNT(DISTINCT(customer_key)) AS [Number of Customers],
        SUM(quantity) AS [Total Quantity]
        FROM dbo.[gold.fact_sales]
        WHERE order_date IS NOT NULL
        GROUP BY DATETRUNC(MONTH, order_date)
        ORDER BY DATETRUNC(MONTH, order_date)
        OFFSET 0 ROWS');
-- This analysis helps visualize the total sales, customers
-- and quantity per month over time.
-- Useful to determine which months are the most
-- profitable
        PRINT 'Created view: Change_Over_Time_Analysis';
    END
    ELSE
        PRINT 'View already exists: Change_Over_Time_Analysis';
    
    -- 2. Cumulative analysis view
    -- moving average of the price
    -- Running total of sales per year and
    IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Cumulative_Analysis' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('
        CREATE VIEW dbo.Cumulative_Analysis AS
        SELECT
        [Order Date],
        [Total Sales],
-- Create a running total using a window function
        SUM([Total Sales]) OVER (PARTITION BY YEAR([Order Date]) ORDER BY [Order Date]) AS [Running Total Sales],
        AVG([Average Price]) OVER (PARTITION BY YEAR([Order Date]) ORDER BY [Order Date]) AS [Moving Average Price]
        FROM
-- Subquery for total sales and average price per month
        (
            SELECT
            DATETRUNC(MONTH,order_date) AS [Order Date],
            SUM(sales_amount) AS [Total Sales],
            AVG(price) AS [Average Price]
            FROM dbo.[gold.fact_sales]
            WHERE order_date IS NOT NULL
            GROUP BY DATETRUNC(MONTH,order_date)
        ) t');
        PRINT 'Created view: Cumulative_Analysis';
    END
    ELSE
        PRINT 'View already exists: Cumulative_Analysis';
    
    -- 3. Performance analysis view
    --Analyze realry performance of products
    --by comparing each product's sales to its average
    --sales performance and previous year's sales
    IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Product_Performance_Analysis' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('
        CREATE VIEW dbo.Product_Performance_Analysis AS
-- CTE with the total sales per product per year
        WITH yearly_product_sales AS
        (
            SELECT
            YEAR(F.order_date) AS [Order Year],
            P.product_name AS [Product Name],
            SUM(F.sales_amount) AS [Current Sales]
            FROM [gold.fact_sales] AS F
            LEFT JOIN [gold.dim_products] AS P ON F.product_key = P.product_key
            WHERE order_date IS NOT NULL
            GROUP BY YEAR(F.order_date), P.product_name
        )
        SELECT 
        [Order Year],
        [Product Name],
        [Current Sales],
        AVG([Current Sales]) OVER(PARTITION BY [Product Name]) AS [Average Sales],
        [Current Sales] - AVG([Current Sales]) OVER (PARTITION BY [Product Name]) AS [Diff in Average],
-- Indicator for the difference
-- between current sales and average sales
            CASE WHEN [Current Sales] - AVG([Current Sales]) OVER (PARTITION BY [Product Name]) > 0 THEN ''Above avg''
                 WHEN [Current Sales] - AVG([Current Sales]) OVER (PARTITION BY [Product Name]) < 0 THEN ''Below avg''
                 ELSE ''avg''
            END [Average Change],
            LAG([Current Sales]) OVER(PARTITION BY [Product Name] ORDER BY [Order Year]) AS [Previous Year Sales],
            [Current Sales] - LAG([Current Sales]) OVER(PARTITION BY [Product Name] ORDER BY [Order Year]) AS [Diff Previous Year],
-- Year over year analysis
            CASE WHEN [Current Sales] - LAG([Current Sales]) OVER(PARTITION BY [Product Name] ORDER BY [Order Year]) > 0 THEN ''Increasing''
                 WHEN [Current Sales] - LAG([Current Sales]) OVER(PARTITION BY [Product Name] ORDER BY [Order Year]) < 0 THEN ''Decreasing''
                 ELSE ''Equal''
            END [Previous Year Change]
        FROM yearly_product_sales');
-- This analysis allows for insights on the performance
-- of each product over the years, making it easy
-- to determine which product are increasing in sales 
-- and providing more revenue, and which ones are making the
-- company loose revenue
        PRINT 'Created view: Product_Performance_Analysis';
    END
    ELSE
        PRINT 'View already exists: Product_Performance_Analysis';
    
    -- 4. Part to whole analysis view
    IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Category_Contribution_Analysis' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('
        CREATE VIEW dbo.Category_Contribution_Analysis AS
-- CTE with the total sales by category
        WITH category_sales AS
        (
            SELECT 
            P.category AS Category,
            SUM(F.sales_amount) AS [Total Sales by Category]
            FROM [gold.fact_sales] AS F
            LEFT JOIN [gold.dim_products] AS P ON F.product_key = P.product_key
            GROUP BY category
        )
        SELECT 
        Category,
        [Total Sales by Category],
-- Window function to get the sum of the total
-- sales by category
        SUM([Total Sales by Category]) OVER() AS [Overall Sales],
-- Percentage of the total calculation for each category.
-- Total Sales by Category needs to be converted into a 
-- FLOAT data type in order for the calculation to work.
-- The result is rounded to 2 decimals
        CONCAT(ROUND((CAST([Total Sales by Category] AS FLOAT) / SUM([Total Sales by Category]) OVER()) * 100,2), ''%'') AS [Percentage of Total]
        FROM category_sales');
-- Results show that the company relies heavily on
-- bikes sales, which is dangerous as a decrease on
-- bikes revenue would be catastrophic to the company
        PRINT 'Created view: Category_Contribution_Analysis';
    END
    ELSE
        PRINT 'View already exists: Category_Contribution_Analysis';
    
    -- 5. Data segmentation views
    -- 5a. Product cost segmentation
    -- Segmentation of products into cost ranges and
    -- count how many products fall into each segment
    IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Product_Cost_Segmentation' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('
        CREATE VIEW dbo.Product_Cost_Segmentation AS
        WITH product_segments AS 
        (
            SELECT
            product_key AS [Product Key],
            product_name AS [Product Name],
            CASE WHEN cost < 100 THEN ''Below 100''
                 WHEN cost BETWEEN 100 AND 500 THEN ''100-500''
                 WHEN cost BETWEEN 500 AND 1000 THEN ''500-1000''
                 WHEN cost BETWEEN 1000 AND 1500 THEN ''1000-1500''
                 ELSE ''Above 1500''
            END [Cost Range]
            FROM [gold.dim_products]
        )
        SELECT
        [Cost Range],
        COUNT([Product Key]) AS [Total Products]
        FROM product_segments
        GROUP BY [Cost Range]');
        PRINT 'Created view: Product_Cost_Segmentation';
    END
    ELSE
        PRINT 'View already exists: Product_Cost_Segmentation';
    
    -- 5b. Customer segmentation
    -- Segmentation of customers based on spending behaviour:
    -- VIP: at least 12 months of history and spent more than 5,000
    -- Regular: at least 12 months of history but spent 5,000 or less
    -- New: less than 12 months
    -- Count the total customers per segment
    IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'Customer_Segmentation' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('
        CREATE VIEW dbo.Customer_Segmentation AS
 -- CTE with customer spending and lifespan
        WITH customer_spending AS
        (
            SELECT
            C.customer_key AS [Customer Key],
            SUM(F.sales_amount) AS [Total Spending],
            MIN(F.order_date) AS [First Order],
            MAX(F.order_date) AS [Last Order],
            DATEDIFF(MONTH,MIN(F.order_date),MAX(F.order_date)) AS Lifespan
            FROM [gold.fact_sales] AS F
            LEFT JOIN [gold.dim_customers] C ON F.customer_key = C.customer_key
            GROUP BY C.customer_key
        )
        SELECT 
        [Customer Status],
        COUNT([Customer Key]) AS [Total Customers]
        FROM
-- Nested query to avoid using the entire CASE WHEN code in
-- the GROUP BY clause. Alternate way would be by creating
-- a CTE with the customer status segments code 
        (
            SELECT 
             [Customer Key],
-- Creation of the customer status segments
             CASE WHEN Lifespan >= 12 AND [Total Spending] > 5000 THEN ''VIP''
                  WHEN Lifespan >= 12 AND [Total Spending] <= 5000 THEN ''Regular''
                  ELSE ''New''
             END [Customer Status]
             FROM customer_spending
        ) t
        GROUP BY [Customer Status]');
-- This segmentation allows the visualization on the number
-- of customers by status, providing insights on customer retention
-- and customer growth
        PRINT 'Created view: Customer_Segmentation';
    END
    ELSE
        PRINT 'View already exists: Customer_Segmentation';
END;
GO

EXEC dbo.CreateAnalysisViews;
