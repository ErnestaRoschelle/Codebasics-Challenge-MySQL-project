-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
select market
 from dim_customer
 where customer = 'Atliq exclusive' and region='APAC';
 
 --  What is the percentage of unique product increase in 2021 vs. 2020? 
 -- The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
 
select
       uniq2020.y as unique_products_2020,
       uniq2021.z as unique_products_2021,
       round ( (uniq2021.z-uniq2020.y) * 100 / uniq2020.y,2 ) as pct_change

from
(
(SELECT count(distinct product_code) as y FROM gdb0041.fact_sales_monthly where fiscal_year=2020 ) as uniq2020,
(SELECT count(distinct product_code) as z FROM gdb0041.fact_sales_monthly where fiscal_year=2021 ) as uniq2021
);

-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields, segment product_count

SELECT segment, count(distinct product_code) as product_count
FROM gdb0041.dim_product
group by segment
order by product_count desc;

-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, segment product_count_2020 product_count_2021 

with cte1 as (
select  p.segment,count(distinct(s.product_code)) as product_count_2020
from fact_sales_monthly s 
join dim_product p 
using (product_code)
where fiscal_year = 2020
group by p.segment
),
cte2 as  ( 
select p.segment,count(distinct(s.product_code)) as product_count_2021
from fact_sales_monthly s 
join dim_product p 
using (product_code)
where fiscal_year = 2021
group by p.segment
)
select distinct cte1.segment,
cte1.product_count_2020,
cte2.product_count_2021,
cte2.product_count_2021-cte1.product_count_2020 as difference
from cte1 join cte2 using (segment)
order by difference desc;

-- Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, product_code product manufacturing_cost
(select m.product_code,p.product,min(manufacturing_cost)  as manufacturing_cost
 from fact_manufacturing_cost m
 join dim_product p
 using (product_code)
 group by product_code,product
 order by manufacturing_cost
 limit 1)
 union all
 (select m.product_code,p.product,max(manufacturing_cost)  as manufacturing_cost
 from fact_manufacturing_cost m
 join dim_product p
 using (product_code)
 group by product_code,product
 order by manufacturing_cost desc
 limit 1);
 

 
 -- Generate a report which contains the top 5 customers 
 -- who received an average high pre_invoice_discount_pct 
 -- for the fiscal year 2021
 -- and in the Indian market. 
 -- The final output contains these fields, customer_code customer average_discount_percentage
SELECT customer_code,customer,round(avg(pre_invoice_discount_pct)*100,2) as avg_discount_percent
FROM gdb023.fact_pre_invoice_deductions i
join dim_customer c 
using (customer_code)
where fiscal_year = 2021 and market = 'india'
group by customer_code,customer
order by avg_discount_percent desc
limit 5;

-- Get the complete report of the Gross sales amount
-- for the customer “Atliq Exclusive” 
-- for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
--  The final report contains these columns: Month Year Gross sales Amount

select monthname(sm.date) as month_name,
       gp.fiscal_year,
       concat('$' , round(sum(( gp.gross_price * sm.sold_quantity)/1000000),2), ' M') as total_gross
from fact_gross_price gp
join fact_sales_monthly sm using (product_code,fiscal_year)
join dim_customer c using (customer_code)
where c.customer='Atliq Exclusive'
group by gp.fiscal_year,month_name;

-- In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

SELECT 
case 
		when month(date) in (9,10,11) then 'Q1'
		when month(date) in (12,1,2)  then 'Q2'
		when month(date) in (3,4,5)   then 'Q3'
		else 'Q4'
end  as quarters,
sum(sold_quantity) as total_qty
FROM gdb023.fact_sales_monthly
where fiscal_year=2020
group by quarters;

-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields, channel gross_sales_mln percentage

with total_gross_table as (
SELECT c.channel,
round(sum(gross_price * sold_quantity)/1000000,2) as total_gross
 FROM  fact_sales_monthly sm
 left join gdb023.fact_gross_price gp using (product_code,fiscal_year)
 left join dim_customer c using (customer_code)
 where gp.fiscal_year = 2021
 group by c.channel)
 select channel,
 concat('$',total_gross,'M') as gross_sales, 
 concat(round((total_gross / sum(total_gross) over() * 100),2),'%')as market_share
 from total_gross_table
 order by market_share desc;
 
 -- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 -- The final output contains these fields, division product_code
with cte1 as 
(
select p.division,
product_code,
product,
sum(sm.sold_quantity) as total_sold_quantity
from dim_product p
join  fact_sales_monthly sm 
using(product_code)
where fiscal_year=2021
group by p. division,product,product_code
),
cte2 as
 (
select division,
product_code,
product,
total_sold_quantity,
dense_rank() over(partition by division order by total_sold_quantity desc) as drk
from cte1
)
select * from cte2 where drk <=3;




 

