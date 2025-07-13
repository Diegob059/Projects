SELECT c.CustomerKey AS CustomerKey
--      ,[GeographyKey]
--      ,[CustomerAlternateKey]
--     ,[Title]
      ,c.FirstName AS [First Name]
--      ,c.MiddleName AS [Middle Name]
      ,c.LastName AS [Last Name]
      ,c.FirstName + ' ' + c.LastName AS [Full Name]

--      ,[NameStyle]
--      ,[BirthDate]
--      ,[MaritalStatus]
--      ,[Suffix]
      ,CASE c.Gender WHEN 'M' THEN 
      'MALE' WHEN 'F' THEN 'FEMALE' 
      END AS Gender
--      ,[EmailAddress]
--      ,[YearlyIncome]
--      ,[TotalChildren]
--      ,[NumberChildrenAtHome]
--      ,[EnglishEducation]
--      ,[SpanishEducation]
--      ,[FrenchEducation]
--      ,[EnglishOccupation]
--      ,[SpanishOccupation]
--      ,[FrenchOccupation]
--      ,[HouseOwnerFlag]
--      ,[NumberCarsOwned]
--      ,[AddressLine1]
--      ,[AddressLine2]
--      ,[Phone]
      ,c.DateFirstPurchase
--      ,[CommuteDistance]
       ,g.city AS [Customer City]

  FROM dbo.DimCustomer c
  LEFT JOIN dbo.DimGeography AS g ON g.geographykey = c.geographykey -- Join dbo.DimCustomer with dbo.DimGeography using geography key
  ORDER BY CustomerKey ASC;