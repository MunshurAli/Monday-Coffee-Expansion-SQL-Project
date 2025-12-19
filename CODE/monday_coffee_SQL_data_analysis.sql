-- Monday Coffee -- Data Analysis --------------------------------------


select * from city;
select * from products;
select * from customers;
select * from sales;


-- Analysis -------------------------------------------------------------


/* Q.1 
   Coffee Consumers Count,
   How many people in each city are estimated to consume coffee, given
   that 25% of the population does? */


select 
	city_name,
	round((population * .25),0) as coffee_consumers_in_millions,
	city_rank
from 
    city
order by population desc;




/* Q.2
   Total revenue from coffee sales,
   What is the total revenue generated from coffee sales across all 
   cities in the last quarter of 2023? */ 


select 
	ci.city_name,
	sum(s.total) as total_revenue
from 
	sales as s 
inner join 
	customers as c
on 
	s.customer_id = c.customer_id
inner join 
	city as ci
on 
	ci.city_id = c.city_id
where 
	extract (year from s.sale_date) = 2023
	and
	extract (quarter from s.sale_date) = 4
group by ci.city_name
order by total_revenue desc;




/* Q.3
   Sales Count for Each Product,
   How many units of each coffee product have been sold? */


select 
	p.product_name,
	count (s.sale_id) as sold_units
from 
	sales as s
inner join 
	products as p
on 
	s.product_id = p.product_id
group by product_name
order by sold_units desc;




/* Q.4
   Average Sales Amount per City,
   What is the average sales amount per customer in each city? */


select 
	ci.city_name,
	sum(s.total) as total_revenue,
	count(distinct s.customer_id) as total_customer,
	round(
		  sum(s.total) :: numeric / count(distinct s.customer_id):: numeric ,2) 
		                          as avg_sales_per_customer

from 
	sales as s
inner join 
	customers as c
on 
	s.customer_id = c.customer_id
inner join
	city as ci
on
	ci.city_id = c.city_id
group by ci.city_name
order by avg_sales_per_customer desc;
-- ---------------------------------------------------------------------------
SELECT 
    ci.city_name,
    
    -- Context: How many people and how many orders?
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    COUNT(s.sale_id) AS total_orders,
    
    -- Metric 1: Average Transaction Value (AOV)
    -- How much is the average receipt worth?
    ROUND(AVG(s.total)::numeric, 2) AS avg_transaction_value,
    
    -- Metric 2: Average Sales per Customer (ARPU)
    -- How much total revenue do we get from a single person on average?
    ROUND(
        (SUM(s.total) / COUNT(DISTINCT s.customer_id))::numeric, 
        2
    ) AS avg_spend_per_customer

FROM sales as s
JOIN customers as c 
    ON s.customer_id = c.customer_id
JOIN city as ci 
    ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY avg_spend_per_customer DESC;
----------------------------------------------------------------------------------


/* Q.5
   City Population and Coffee Consumers (25%)
   Provide a list of cities along with their populations and 
   estimated coffee consumers. */


select 
	city_id,
	city_name,
	coalesce(population,0) as population,
	round(coalesce(population,0)*.25) as estimated_coffee_consumers
from city
order by estimated_coffee_consumers desc;




/* Q.6
   Top Selling Products by City
   What are the top 3 selling products in each city based on sales volume? */


with product_city_sales as (
    select
        ci.city_name,
        p.product_name,
        sum(s.total) as total_sales
    from sales as s
    inner join customers as c on s.customer_id = c.customer_id
    inner join city as ci on c.city_id = ci.city_id
    inner join products as p on s.product_id = p.product_id
    group by ci.city_name, p.product_name
),
ranked_products as (
    select
        city_name,
        product_name,
        total_sales,
        rank() over (
            partition by city_name
            order by total_sales desc
        ) as sales_rank
    from product_city_sales
)
select
    city_name,
    product_name,
    total_sales,
    sales_rank
from ranked_products
where sales_rank <= 3
order by city_name, sales_rank;




/* Q.7
   Customer Segmentation by City
   How many unique customers are there in each city who have purchased coffee products? */


select 
	ci.city_name,
	count(distinct c.customer_id) as unique_customers
from sales as s
inner join customers as c
on s.customer_id = c.customer_id
inner join city as ci
on c.city_id = ci.city_id
group by ci.city_name
order by  unique_customers desc;




/* Q.8
   Average Sale vs Rent
   Find each city and their average sale per customer and avg rent per customer */


with city_sales as (
    select
        ci.city_id,
        ci.city_name,
        ci.estimated_rent,
        count(distinct c.customer_id) as total_customers,
        sum(s.total) as total_sales
    from sales s
    inner join customers c on s.customer_id = c.customer_id
    inner join city ci on c.city_id = ci.city_id
    group by ci.city_id, ci.city_name, ci.estimated_rent
)
select
    city_name,
    total_customers,
    round(total_sales ::numeric  / total_customers, 2) as avg_sale_per_customer,
    round(estimated_rent ::numeric / total_customers, 2) as avg_rent_per_customer
from city_sales
order by avg_sale_per_customer desc;




/* Q.9
   Monthly Sales Growth
   Sales growth rate: Calculate the percentage growth (or decline) 
   in sales over different time periods (monthly). */


with monthly_sales as (
    select
        DATE_TRUNC('month', sale_date) as month,
        sum (total) as total_sales
    from sales
    group by DATE_TRUNC('month', sale_date)
),
growth_calc as (
    select
        month,
        total_sales,
        lag (total_sales) over (order by month) as previous_month_sales
    from monthly_sales
)
select
    month,
    total_sales,
    previous_month_sales,
    ROUND(
        ((total_sales - previous_month_sales)
        / previous_month_sales * 100)::NUMERIC, 2
    ) as sales_growth_percentage
from growth_calc
order by month;




/* Q.10
   Market Potential Analysis
   Identify top 3 city based on highest sales, return city name, total sale,
   total rent, total customers, estimated coffee consumer */


with city_level_data as (
    select
        ci.city_id,
        ci.city_name,
        sum(s.total) as total_sale,
        ci.estimated_rent as total_rent,
        count(distinct c.customer_id) as total_customers,
        round(coalesce(ci.population, 0) * 0.25) as estimated_coffee_consumer
    from sales s
    join customers c on s.customer_id = c.customer_id
    join city ci on c.city_id = ci.city_id
    group by
        ci.city_id,
        ci.city_name,
        ci.estimated_rent,
        ci.population
)
select
    city_name,
    total_sale,
    total_rent,
    total_customers,
    estimated_coffee_consumer
from city_level_data
order by total_sale desc
limit 3;





/*  Recomendation
City 1: Pune
	 *.Average rent per customer is very low.
	 *.Highest total revenue.
	 *.Average sales per customer is also high.

City 2: Delhi
	 *.Highest estimated coffee consumers at 7750000 million.
	 *.Highest total number of customers, which is 68.
	 *.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	 *.Highest number of customers, which is 69.
	 *.Average rent per customer is very low at 156.
	 *.Average sales per customer is better at 11644k. */



















   

   