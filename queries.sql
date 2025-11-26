select COUNT(customer_id) as customers_count
from customers c;

select 
	CONCAT(e.first_name, ' ', e.last_name) as seller,
	floor(SUM(s.quantity)) as operations,
	floor(SUM(s.quantity*p.price)) as income
from sales s
	left join products p on s.product_id = p.product_id
	left join employees e on s.sales_person_id = e.employee_id 
group by seller
order by income desc
limit 10;

WITH prod AS (
    SELECT 
        s.sales_person_id,
        AVG(s.quantity * p.price) AS avg_amount
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.sales_person_id
),
overall AS (
    SELECT AVG(avg_amount) AS overall_avg
    FROM prod
)
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    prod.avg_amount
FROM prod
JOIN employees e ON prod.sales_person_id = e.employee_id
CROSS JOIN overall
WHERE prod.avg_amount < overall.overall_avg
ORDER BY prod.avg_amount;

with a as (
	select
		s.quantity * p.price as income,
		s.product_id,
		s.sales_person_id,
		s.sale_date,
		TO_CHAR(sale_date, 'FMDay') as day_of_week,
		extract(ISODOW from sale_date) as weekday_number,
		e.first_name || ' ' || e.last_name AS seller
	from sales s
    join products p on s.product_id = p.product_id
    join employees e on s.sales_person_id = e.employee_id
)
select
	seller,
	day_of_week,
	floor(sum(income)) as income
from a
group by seller, day_of_week, weekday_number
order by seller, weekday_number;