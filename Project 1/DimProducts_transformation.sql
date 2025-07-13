SELECT [ProductKey]
      ,p.[ProductAlternateKey] AS [Product Item Code]
--      ,[ProductSubcategoryKey]
--      ,[WeightUnitMeasureCode]
--      ,[SizeUnitMeasureCode]
      ,p.[EnglishProductName] AS [Product Name]
      ,ps.EnglishProductSubcategoryName AS [Product Subcategory] -- Data from dbo.DimProductSubCategory table
      ,pc.EnglishProductCategoryName AS [Product Category] -- Data from dbo.DimProductCategory table
--      ,[SpanishProductName]
--      ,[FrenchProductName]
--      ,[StandardCost]
--      ,[FinishedGoodsFlag]
      ,p.[Color] AS [Product Color]
--      ,[SafetyStockLevel]
--      ,[ReorderPoint]
--      ,[ListPrice]
      ,p.[Size] AS [Product Size]
--      ,[SizeRange]
--      ,[Weight]
--      ,[DaysToManufacture]
      ,p.[ProductLine] AS [Product Line]
--      ,[DealerPrice]
--      ,[Class]
--      ,[Style]
      ,p.[ModelName] AS [Product Model Name]
--      ,[LargePhoto]
      ,p.[EnglishDescription] AS [Product Description]
--      ,[FrenchDescription]
--      ,[ChineseDescription]
--      ,[ArabicDescription]
--      ,[HebrewDescription]
--      ,[ThaiDescription]
--      ,[GermanDescription]
--      ,[JapaneseDescription]
--      ,[TurkishDescription]
--      ,[StartDate]
--      ,[EndDate]
--      ,[Status]
,ISNULL(p.Status, 'Outdated') AS [Product Status] -- Identify the product status. If the status is a null value, return Outdated
  FROM dbo.DimProduct p
-- Join DimProductSubcategory with DimProduct using the ProductSubcategoryKey
LEFT JOIN dbo.DimProductSubcategory AS ps ON ps.ProductSubcategoryKey = p.ProductSubcategoryKey
-- Join DimProductCategory using ProductCategoryKey found also on DimProductSubCategory
LEFT JOIN dbo.DimProductCategory AS pc ON pc.ProductCategoryKey = ps.ProductCategoryKey
ORDER BY p.ProductKey ASC;
