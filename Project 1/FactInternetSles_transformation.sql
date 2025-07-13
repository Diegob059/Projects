SELECT [ProductKey]
      ,[OrderDateKey]
      ,[DueDateKey]
      ,[ShipDateKey]
      ,[CustomerKey]
      --,[PromotionKey]
      --,[CurrencyKey]
      --,[SalesTerritoryKey]
      ,[SalesOrderNumber]
      --,[SalesOrderLineNumber]
      --,[RevisionNumber]
      --,[OrderQuantity]
      --,[UnitPrice]
      --,[ExtendedAmount]
      --,[UnitPriceDiscountPct]
      --,[DiscountAmount]
      --,[ProductStandardCost]
      --,[TotalProductCost]
      ,[SalesAmount]
      --,[TaxAmt]
      --,[Freight]
      --,[CarrierTrackingNumber]
      --,[CustomerPONumber]
      --,[OrderDate]
      --,[DueDate]
      --,[ShipDate]
  FROM [dbo].[FactInternetSales]
  -- Ensures that only 2 years of date are extracted
  WHERE LEFT(OrderDateKey,4) >= YEAR(GETDATE()) -2
  ORDER BY OrderDateKey ASC;

  SELECT SUM(SalesAmount) AS [Sales Amount per month] FROM dbo.FactInternetSales WHERE OrderDateKey 
  BETWEEN 20230101 AND 20231231;

  SELECT SUM(SalesAmount) AS [Sales Amount per month] FROM dbo.FactInternetSales WHERE OrderDateKey 
  BETWEEN 20230101 AND 20230131;
