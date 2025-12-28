CREATE DATABASE IF NOT EXISTS SQL_Case_Studies;

use sql_case_studies;

## Q1. List the top 10 customers by total sales amount. Show CustomerID, Full Name and Total Sales. #############################################################################

SELECT 
    c.ID AS CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS FullName,
    SUM((s.Price*s.quantity)) AS Total_Sales
FROM
    Customer c
        JOIN
    Sales s ON c.ID = s.CustomerID
GROUP BY CustomerID , FullName
ORDER BY Total_Sales DESC
LIMIT 10;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q2. Show total sales per month for the year 2023, ordered by month. ###########################################################################################################

SELECT 
    DATE_FORMAT(orderdate, '%Y-%m-01') AS Month_Start,
    SUM((s.quantity * s.price)) AS Total_Sales
FROM
    Sales s
WHERE
    YEAR(orderdate) = 2023
GROUP BY DATE_FORMAT(orderdate, '%Y-%m-01')
ORDER BY DATE_FORMAT(orderdate, '%Y-%m-01');

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q3. Find out the products that have never been sold ###########################################################################################################################

SELECT 
    p.ProductID, p.ProductName, p.Category
FROM
    products p
        LEFT JOIN
    sales s ON p.productid = s.productid
where s.ProductID is Null;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q4. Find how many new customers are acquired in 2022? #########################################################################################################################

SELECT 
    COUNT(*) AS NewCustomer2022
FROM
    (SELECT 
        customerid, MIN(orderdate) AS firstorderdate
    FROM
        sales
    GROUP BY customerid
    HAVING YEAR(MIN(orderdate)) = 2022) t;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q5. Calculate the Profit Margin (Profit/Sales) percentage for each category. ###################################################################################################

SELECT 
    p.category,
    ROUND(SUM(s.Profit) / SUM(s.quantity * s.price) * 100,
            2) AS Profit_Margin_Percentage
FROM
    products p
        JOIN
    sales s ON p.productid = s.productid
GROUP BY p.category;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q6. For each category, show date-wise sales and a running total of sales over time. ###########################################################################################
-- ------------------------------ With using CTE ---------------------------------------------------------------------------------------------------------------------------------
WITH CTE as(
	SELECT p.category, s.orderdate, sum(s.quantity*s.price) AS sales
		FROM products p 
			JOIN sales s ON p.productid = s.productid
	GROUP BY p.category, s.orderdate 
	ORDER BY s.orderdate)
SELECT category, orderdate, sales, 
sum(sales) OVER(PARTITION BY category ORDER BY orderdate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Total_Sales
from CTE;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------ Without using CTE ------------------------------------------------------------------------------------------------------------------------------
SELECT p.category, 
	s.orderdate, 
		sum(s.quantity*s.price) AS sales,
		sum(sum(s.quantity*s.price)) over(partition by category order by orderdate 
        rows between unbounded preceding and current row) as Total_Sales
	FROM products p 
		JOIN sales s ON p.productid = s.productid
GROUP BY p.category, s.orderdate 
ORDER BY p.category, s.orderdate;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q7. Get the most recent order (by OrderDate) for every customer ###############################################################################################################
-- ----------------------------------------- Using RANK() Function ---------------------------------------------------------------------------------------------------------------
select 
	distinct t.ID as Customer_ID, t.OrderID, t.OrderDate
		from(
	select c.ID,s.OrderID, s.OrderDate, 
		rank() over(partition by c.ID order by s.OrderDate desc) as rnk
		from customer c 
			left join Sales s on c.ID = s.CustomerID) t
where t.rnk = 1;
-- ----------------------------------------- Using Group BY and Joining and no window function -----------------------------------------------------------------------------------
SELECT 
    CustomerID,OrderID, MAX(OrderDate) AS most_recent_sales
FROM
    sales
GROUP BY CustomerID, OrderID
ORDER BY CustomerID;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    s.orderid, s.customerid, s.orderdate
FROM
    sales s
        JOIN
    (SELECT 
        customerid, MAX(orderdate) AS most_recentdate
    FROM
        sales
    GROUP BY customerid) t ON s.customerid = t.customerid
        AND s.orderdate = t.most_recentdate
ORDER BY s.customerid;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Q8. Classify customers based on their total sales. Show customerID, Name and Total Sales: #####################################################################################
## ----- Platinum: Total Sales >= 15000
## ----- Gold: Total Sales 10000 to 15000
## ----- Silver: Total Sales: 5000-10000
## ----- Bronze: Total Sales < 5000

SELECT 
    c.ID AS CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(s.Quantity * s.Price) AS Total_Sales,
    CASE
        WHEN (SUM(s.Quantity * s.Price)) >= 15000 THEN 'Premium'
        WHEN
            (SUM(s.Quantity * s.Price)) >= 10000
                AND (SUM(s.Quantity * s.Price)) < 15000
        THEN
            'Gold'
        WHEN
            (SUM(s.Quantity * s.Price)) >= 5000
                AND (SUM(s.Quantity * s.Price)) < 10000
        THEN
            'Silver'
        ELSE 'Bronze'
    END AS Sales_Category
FROM
    customer C
        JOIN
    sales s ON c.ID = s.CustomerID
GROUP BY C.ID , CustomerName
order by Total_Sales DESC;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Q9. For each category, find the product with the highest total sales. If Ties exist then show all tied products. ##############################################################

with cte as (
	Select p.Category, p.ProductName, 
		sum(s.quantity * s.Price) as Total_Sales,
		rank() over(partition by p.Category order by sum(s.quantity * s.Price) desc) as product_rank 
	from Products p
			join 
		sales s on p.ProductID = s.ProductID
	group by p.Category, p.ProductName)
select Category, ProductName, Total_Sales from cte where product_rank=1;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Q10. Actual and Target Price by category and year. ############################################################################################################################

select * from TargetSales;
select * from Sales;
-- -------------------------------------------- Finding the actual sales of 2020, 2021, 2022 and 2023 ----------------------------------------------------------------------------
SELECT 
    p.category,
    SUM(CASE
        WHEN YEAR(s.OrderDate) = 2020 THEN (s.quantity * s.price)
        ELSE 0
    END) AS '2020_Actual_Sales',
    SUM(CASE
        WHEN YEAR(s.OrderDate) = 2021 THEN (s.quantity * s.price)
        ELSE 0
    END) AS '2021_Actual_Sales',
    SUM(CASE
        WHEN YEAR(s.OrderDate) = 2022 THEN (s.quantity * s.price)
        ELSE 0
    END) AS '2022_Actual_Sales',
    SUM(CASE
        WHEN YEAR(s.OrderDate) = 2023 THEN (s.quantity * s.price)
        ELSE 0
    END) AS '2023_Actual_Sales'
FROM
    products p
        JOIN
    sales s ON p.productID = s.ProductID
GROUP BY p.category;

-- -------------------------------------------- Comparing Actual Sales and Target Sales of 2020, 2021, 2022 and 2023 -------------------------------------------------------------
-- -------------------------------------------- Here instead of multiplying price and quantity, only price as been considered ----------------------------------------------------
With cte_Actual_sales as
(select p.category,
sum(case when year(s.OrderDate) = 2020 then (s.price) else 0 END) as '2020_Actual_Sales',
sum(case when year(s.OrderDate) = 2021 then (s.price) else 0 END) as '2021_Actual_Sales',
sum(case when year(s.OrderDate) = 2022 then (s.price) else 0 END) as '2022_Actual_Sales',
sum(case when year(s.OrderDate) = 2023 then (s.price) else 0 END) as '2023_Actual_Sales'

from products p
	join
	sales s
on p.productID = s.ProductID
group by p.category)
select c.Category, 
c.2020_Actual_Sales,
t.2020_Sales as 2020_Target_Sales,
case when c.2020_Actual_Sales < t.2020_Sales then 'Target not reached'
	 when c.2020_Actual_Sales = t.2020_Sales then 'Target reached'
     else 'Target exceeded'
		end as '2020_Sales_Status',
c.2021_Actual_Sales,
t.2021_Sales as 2021_Target_Sales,
case when c.2021_Actual_Sales < t.2021_Sales then 'Target not reached'
	 when c.2021_Actual_Sales = t.2021_Sales then 'Target reached'
     else 'Target exceeded'
		end as '2021_Sales_Status',
c.2022_Actual_Sales,
t.2022_Sales as 2022_Target_Sales,
case when c.2022_Actual_Sales < t.2022_Sales then 'Target not reached'
	 when c.2022_Actual_Sales = t.2022_Sales then 'Target reached'
     else 'Target exceeded'
		end as '2022_Sales_Status',
c.2023_Actual_Sales,
t.2023_Sales as 2023_Target_Sales,
case when c.2023_Actual_Sales < t.2023_Sales then 'Target not reached'
	 when c.2023_Actual_Sales = t.2023_Sales then 'Target reached'
     else 'Target exceeded'
		end as '2023_Sales_Status'
 from cte_Actual_Sales c
join 
TargetSales t on c.Category = t.Category;
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------ Another Approach for the same answer -----------------------------------------------------------------------------------------------
WITH actual_sales AS (
    SELECT 
        p.Category,
        YEAR(s.OrderDate) AS Sales_Year,
        SUM(s.Price) AS Actual_Sales
    FROM products p
    JOIN sales s
        ON p.ProductID = s.ProductID
    GROUP BY 
        p.Category,
        YEAR(s.OrderDate)
),
target_sales AS (
    SELECT Category, 2020 AS Sales_Year, 2020_Sales AS Target_Sales FROM TargetSales
    UNION ALL
    SELECT Category, 2021 AS Sales_Year, 2021_Sales AS Target_Sales FROM TargetSales
    UNION ALL
    SELECT Category, 2022 AS Sales_Year, 2022_Sales AS Target_Sales FROM TargetSales
    UNION ALL
    SELECT Category, 2023 AS Sales_Year, 2023_Sales AS Target_Sales FROM TargetSales
)
SELECT 
    a.Category,
    a.Sales_Year AS Year,
    a.Actual_Sales,
    t.Target_Sales,
    CASE 
        WHEN a.Actual_Sales < t.Target_Sales THEN 'Target not reached'
        WHEN a.Actual_Sales = t.Target_Sales THEN 'Target reached'
        ELSE 'Target exceeded'
    END AS Sales_Status
FROM actual_sales a
JOIN target_sales t
    ON a.Category = t.Category
   AND a.Sales_Year = t.Sales_Year
ORDER BY 
    a.Category,
    a.Sales_Year;
-- --------------------------------- This last question can also be solved using unpivot() in MS SQL Server ----------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
