-- общее количество клиетнов
select COUNT(customer_id) as customers_count
from customers c;

-- top_10_total_income топ-10 лучших продавцов по суммарной выручке
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

--  lowest_average_income информация о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
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
    floor(prod.avg_amount) as average_income
FROM prod
JOIN employees e ON prod.sales_person_id = e.employee_id
CROSS JOIN overall
WHERE prod.avg_amount < overall.overall_avg
ORDER BY prod.avg_amount;

-- day_of_the_week_income выручка по дням недели для каждого продавца
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
order by weekday_number, seller;

-- age_groups возрастные группы
with a as (
	select
		case 
			when age between 16 and 25 then '16-25'
			when age between 26 and 40 then '26-40'
			else '40+'
		end
		as age_category
	from customers c 
	where age >= 16
)
select 
	age_category,
	count(age_category) as age_count
from a 
group by age_category
order by age_category;

-- customers_by_month количество уникальных покупателей и выручка, которую они принесли

select
    TO_CHAR(sale_date, 'YYYY-MM') as selling_month,
    COUNT(distinct customer_id) as total_customers,
    floor(SUM(quantity * price)) as income
from sales s
join products p on s.product_id = p.product_id
group by selling_month
order by selling_month;

-- special_offer Клиенты, у который первая покупка была по акции (price = 0)
with a as (
	select
		customer_id,
		sales_person_id,
		sale_date,
		product_id,
		row_number() over (partition by customer_id order by sale_date) as row_number
	from sales s 
)
select 
	c.first_name || ' ' || c.last_name AS customer,
	a.sale_date,
	e.first_name || ' ' || e.last_name AS seller
from a 	
	join products p on a.product_id = p.product_id
	join employees e on e.employee_id = a.sales_person_id 
	join customers c on c.customer_id = a.customer_id
where row_number = 1 and p.price = 0
order by c.customer_id;