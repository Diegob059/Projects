-- Index creation for query optimization (optional)
-- CREATE NONCLUSTERED INDEX customer_id_index ON Customer_bank_info_final (customer_id)
-- CREATE NONCLUSTERED INDEX transaction_value_index ON Customer_bank_info_final (transaction_value)

-- Stored procedure to create the views of the analysis performed.
-- The analysis are the following:
-- 1) dbo.bank_information_cleaned_data is a view with only the data from customers that have transactions.
-- 2) dbo.customers_by_age is a view with a segmentation of customers by age group.
-- 3) dbo.transaction_pattern_analysis contains a patter analysis with the total transactions, balance, 
-- total deposits and total withdrawals per customer.
-- 4) dbo.suspicious_activity_analysis identifies customers where total withdrawals are greater than 50% of the account balance.
-- 5) dbo.customer_job_segmentation contains a customer segmentation by jobs.

CREATE OR ALTER PROCEDURE dbo.bank_analysis_views
AS
BEGIN
SET NOCOUNT ON;
-- View with only the customers that have transactions
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'dbo.cleaned_bank_info' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('CREATE VIEW dbo.cleaned_bank_info AS 
SELECT
customer_id,
name,
age,
job,
education,
marital,
balance,
housing,
loan,
transaction_number_last_month,
transaction_id,
transaction_value,
transaction_date
FROM Customer_bank_info_final 
WHERE transaction_id IS NOT NULL');
        PRINT 'Created view: dbo.cleaned_bank_info';
    END
    ELSE
        PRINT 'View already exists';

-- View with a customer segmentation by age
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'dbo.customers_by_age' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('CREATE VIEW dbo.customers_by_age AS
WITH age_groups AS
(
SELECT
customer_id,
name,
age,
CASE WHEN age BETWEEN 21 AND 30 THEN ''21-30''
	 WHEN age BETWEEN 31 AND 40 THEN ''31-40''
	 WHEN age BETWEEN 41 AND 50 THEN ''41-50''
	 ELSE ''50+''
	 END AS customer_age
FROM Customer_bank_info_final
)
SELECT COUNT(customer_id) AS total_customers, customer_age FROM age_groups
GROUP BY customer_age');
        PRINT 'Created view: dbo.customers_by_age';
    END
    ELSE
        PRINT 'View already exists';

-- View wit the transaction pattern analysis
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'dbo.transaction_pattern_analysis' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('CREATE VIEW dbo.transaction_pattern_analysis AS
SELECT
customer_id,
SUM(balance) AS balance,
COUNT(transaction_id) AS total_transactions,
ROUND(SUM(CASE WHEN transaction_value > 0 THEN transaction_value ELSE 0 END),2) AS deposit_total,
ROUND(SUM(CASE WHEN transaction_value < 0 THEN transaction_value ELSE 0 END),2) AS withdrawal_total
FROM Customer_bank_info_final
WHERE transaction_id IS NOT NULL
GROUP BY customer_id');
        PRINT 'Created view: dbo.transaction_pattern_analysis';
    END
    ELSE
        PRINT 'View already exists';

-- View with the suspicious activity analysis
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'dbo.suspicious_activity_analysis' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('CREATE VIEW dbo.suspicious_activity_analysis AS
WITH susp_act AS
(
SELECT 
customer_id,
name,
transaction_date,
transaction_id,
ABS(transaction_value) AS total_withdrawn,
balance AS current_balance,
ABS(transaction_value)/balance * 100 AS withdrawal_percentage
FROM Customer_bank_info_final
WHERE transaction_value < 0
)
SELECT * FROM susp_act
WHERE withdrawal_percentage >= 50.0');

        PRINT 'Created view: dbo.suspicious_activity_analysis';
    END
    ELSE
        PRINT 'View already exists';

-- View with the customer job segmentation
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'dbo.customer_job_segmentation' AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        EXEC('CREATE VIEW dbo.customer_job_segmentation AS
SELECT
job,
COUNT(DISTINCT(customer_id)) AS total_customers,
AVG(transaction_number_last_month) AS avg_monthly_transactions,
AVG(transaction_value) AS avg_transaction_value
FROM Customer_bank_info_final
GROUP BY job');

        PRINT 'Created view: dbo.customer_job_segmentation';
    END
    ELSE
        PRINT 'View already exists';
END;
GO

EXEC dbo.bank_analysis_views;
