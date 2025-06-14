Create Table Sales (
transaction_id VARCHAR(50),
customer_id	VARCHAR(50),
customer_name VARCHAR(50),
customer_age INT,	
gender NVARCHAR(50),
product_id NVARCHAR(50),
product_name NVARCHAR(50),	
product_category NVARCHAR(50),	
quantiy	INT,
prce float,
payment_mode NVARCHAR(50),
purchase_date DATE,
time_of_purchase TIME,	
status NVARCHAR(50));

DROP TABLE Sales;
SELECT * FROM Sales;

--IMPORT DATA WITH USING BULK INSERT METHOD
SET DATEFORMAT dmy
BULK INSERT Sales
from 'C:\Users\ADMIN\OneDrive - Alard Charitable Trust\Desktop\data analysis\archive\sales.csv'
 with (
   FIELDTERMINATOR=',',
  ROWTERMINATOR='\n',
  firstrow=2
  );

  --data Cleaning
  select * from Sales;  --Copy Data for data cleaning

  select * into Salesdata1 from Sales;

 select * from Sales;
 select * from Salesdata1;

 --step 1: check for duplicate
 select transaction_id from Salesdata1 group by transaction_id having count(transaction_id) >1;

 with cte as (
 select *,
   ROW_NUMBER() OVER (PARTITION BY transaction_id order by transaction_id) as Row_num from Salesdata1)
  
 -- DELETE FROM cte
  --where row_num=2
  
  select * from cte
   where row_num >2

   --step2: Correction of Header

   EXEC sp_rename'Salesdata1.quantiy','quantity','column';
   EXEC sp_rename'Salesdata1.prce','price','column';

   --step 3 : - To check datatype 
   select column_name,data_type 
   from information_schema.columns
   where table_name='salesdata1';

   --step 4:-To Check Null Values
   --check null count

   DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql += '
SELECT ''' + name + ''' AS ColumnName, COUNT(*) AS NullCount
FROM salesdata1
WHERE ' + QUOTENAME(name) + ' IS NULL
UNION ALL
'
FROM sys.columns
WHERE object_id = OBJECT_ID('salesdata1');

-- Remove last UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 10);

EXEC sp_executesql @sql;



--2
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql += STRING_AGG(
'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, COUNT(*) AS NullCount
FROM ' + QUOTENAME(TABLE_SCHEMA) +'.Salesdata1
WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
'UNION ALL'
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFROMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Salesdata1';


--Execute the dynamic sql
EXEC sp_executesql @sql;




DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += '
SELECT ''' + name + ''' AS ColumnName, COUNT(*) AS NullCount
FROM salesdata1
WHERE ' + QUOTENAME(name) + ' IS NULL
UNION ALL
'
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.salesdata1');  -- Use schema-qualified name

-- Only trim if @sql has content
IF LEN(@sql) >= 10
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - 10); -- Remove last UNION ALL
    EXEC sp_executesql @sql;
END
ELSE
BEGIN
    PRINT 'No columns found for table salesdata1.';
END


--Treating Null Value
select * from salesdata1 where transaction_id is null or customer_id is null or customer_age is null or gender is null or product_id is null
or product_name is null or product_category is null or quantity is null or price is null or payment_mode is null or purchase_date is null
or time_of_purchase is null or status is null;

--deleting the outlire
delete from Salesdata1 where transaction_id is null;

--1 update
select * from Salesdata1 where customer_name = 'Ehsaan Ram';
update salesdata1
set customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900';
--2 update
select * from Salesdata1 where customer_name = 'Damini Raju';
update salesdata1
set customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663';

--3 update
select * from Salesdata1 where customer_id = 'CUST1003';
update salesdata1
set customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
WHERE transaction_id = 'TXN432798';


--step 5:-Data cleaning

select distinct gender from salesdata1;

update salesdata1 
set gender = 'M'
where gender = 'Male'

update salesdata1
set gender = 'F'
Where gender = 'Female'

select * from salesdata1;

select distinct payment_mode from salesdata1;

update salesdata1
set payment_mode = 'Credit Card'
where payment_mode = 'CC'


--SOLVING Business Insight Questions
--DATA ANALYSIS

--WHAT ARE THE TOP 5 MOST SELLING PRODUCTS BY QUANTITY
SELECT top 5 product_name, sum(quantity) as Total_Quantity_sold
from Salesdata1
where status = 'delivered'
group by product_name
order by Total_Quantity_sold desc;


--2 . which product are most frequently canceled?

SELECT top 5 product_name, count(*) as Total_canceled
from Salesdata1
where status = 'cancelled'
group by product_name
order by Total_canceled desc;

--3. what time of the day has highest number pr purchases?
select
CASE
when DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
when DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
when DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
when DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END AS TIME_OF_DAY,
COUNT(*) AS Total_order
from salesdata1
GROUP BY CASE
when DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
when DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
when DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
when DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END
ORDER BY Total_order desc

--4. which prodcut categories the hight revenue?

SELECT * FROM Salesdata1

select product_category,
FORMAT(SUM(price*quantity),'C0','en-IN')AS Revenue
from salesdata1
group by product_category
order by SUM(price*quantity) DESC;


--5.what is the Return/Cancellation rate per product category?

select * from Salesdata1;

--Cancellation

select product_category,
FORMAT(
count(case when status = 'Cancelled' then 1 end)*100.0/count(*),'N')+' %'
AS CANCELLED_PERCENTAGE
FROM salesdata1
group by product_category
order by CANCELLED_PERCENTAGE DESC

--Return

select product_category,
FORMAT(
count(case when status = 'returned' then 1 end)*100.0/count(*),'N')+' %'
AS CANCELLED_PERCENTAGE
FROM salesdata1
group by product_category
order by CANCELLED_PERCENTAGE DESC