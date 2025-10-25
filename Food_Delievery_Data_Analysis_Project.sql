CREATE TABLE restaurants (
    Restaurant_ID INT PRIMARY KEY,
    Restaurant_Name VARCHAR(100),
    Cuisine VARCHAR(50),
	zones varchar(50),
    Category VARCHAR(100)
);

CREATE TABLE orders (
    Order_ID varchar(20),
    Customer_Name VARCHAR(100),
    Restaurant_ID INT,
    Order_Date DATE,
    Quantity_of_Items INT,
    Order_Amount NUMERIC(10, 5),
    Payment_Mode VARCHAR(50),
    Delivery_Time_Taken_mins INT,
    Customer_Rating_Food INT,
    Customer_Rating_Delivery INT,
    FOREIGN KEY (Restaurant_ID) REFERENCES restaurants(Restaurant_ID)
);

select * from orders;
select * from restaurants;


--Find the top 3 restaurants by total sales amount.

select restaurant_name,sum(order_amount)
from orders o 
join restaurants r on o.restaurant_ID = r.restaurant_Id
group by restaurant_name 
order by sum(order_amount) desc
limit 3;

--For each restaurant, rank the orders by Order_Amount.

select 
restaurant_ID,
order_ID,
customer_name,
order_amount,
rank() over (partition by restaurant_ID order by order_amount desc) as order_rank
from orders;

--Find the cumulative total of sales per restaurant over time.

select *,
sum(order_Amount) over(partition by restaurant_ID order by order_date rows between unbounded preceding and current row) as running_total
from orders;

--List all orders along with the restaurant name and cuisine zone.

select *
from orders o
join restaurants r on o.restaurant_ID = r.restaurant_ID;

--Speed up queries on restaurant lookups and order dates.

create index idx_orders_restaurant_Id on orders(restaurant_Id);
create index idx_orders_order_date on orders(order_date);

select * from orders where restaurant_Id = 10;
select * from orders where order_date = '2022-01-01';

--Show restaurants that have no orders yet.

select r.*
from restaurants r 
left join orders o on r.restaurant_Id = o.restaurant_Id
where o.restaurant_ID is null;

--Show payment mode, defaulting to “Unknown” when missing.

select order_ID,
coalesce (payment_mode, 'Unknown') as payment_type
from orders;

--Find the top 5 customers by total spending

select customer_name, sum(order_amount) from orders
group by customer_name
order by sum(order_amount) desc 
limit 5;

--Calculate average delivery time per cuisine zone

select zones, cuisine, avg(delivery_time_taken_mins)
from orders o 
join restaurants r on o.restaurant_ID = r.restaurant_ID
group by cuisine, zones
order by avg(delivery_time_taken_mins) desc;

--Find the percentage contribution of each restaurant to total sales

select r.restaurant_ID,
r.restaurant_name,
sum(o.order_amount) as total_sales,
round((sum(o.order_amount)*100.0)/(select sum(order_amount)from orders),2)
as perc_contri
from orders o 
join restaurants r on o.restaurant_Id = r.restaurant_ID
group by r.restaurant_ID, r.restaurant_name
order by perc_contri desc;

--Determine which day of week gets most orders

select 
to_char(order_date, 'day') as day_of_week,
count(*) as total_orders
from orders
group by to_char(order_date, 'day')
order by total_orders desc;

--Identify the most common payment mode per restaurant

WITH payment_counts AS (
    SELECT
        r.restaurant_id,
        r.restaurant_name,
        o.payment_mode,
        COUNT(*) AS payment_count,
        RANK() OVER (
            PARTITION BY r.restaurant_id 
            ORDER BY COUNT(*) DESC
        ) AS payment_rank
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_id, r.restaurant_name, o.payment_mode
)
SELECT
    restaurant_id,
    restaurant_name,
    payment_mode,
    payment_count
FROM payment_counts
WHERE payment_rank = 1
ORDER BY payment_count DESC;


--Detect delivery delays if Delivery_Time_Taken_mins > 40

select order_Id, restaurant_ID, customer_name,
case  
when delivery_time_taken_mins > 40 then 'Delivery Delays'
else 'Delivery_on_Time'
end as delivery_status
from orders;

--Automatically delete orders older than 2 years

begin;
delete from orders
where order_date < now()-interval '2 years';
rollback;
commit;

--Use CASE to categorize order sizes (Small, Medium, Large)

select restaurant_ID, order_ID, customer_name, order_amount,
case
when order_amount<200 then 'Small'
when order_amount<500 and order_amount>200 then 'Medium'
else 'Large'
end as Order_Size
from orders;
