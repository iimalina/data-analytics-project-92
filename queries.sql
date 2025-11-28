-- ОБЩЕЕ КОЛИЧЕСТВО КЛИЕНТОВ
SELECT COUNT(customers.customer_id) AS customers_count
FROM customers;

-- TOP_10_TOTAL_INCOME ТОП-10 ЛУЧШИХ ПРОДАВЦОВ ПО СУММАРНОЙ ВЫРУЧКЕ
SELECT
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
    FLOOR(COUNT(sales.quantity)) AS operations,
    FLOOR(SUM(sales.quantity * products.price)) AS income
FROM sales
JOIN products ON sales.product_id = products.product_id
JOIN employees ON sales.sales_person_id = employees.employee_id
GROUP BY employees.first_name, employees.last_name
ORDER BY income DESC
LIMIT 10;

-- LOWEST_AVERAGE_INCOME ПРОДАВЦЫ, ЧЬЯ СРЕДНЯЯ ВЫРУЧКА ЗА СДЕЛКУ МЕНЬШЕ СРЕДНЕЙ ПО ВСЕМ ПРОДАВЦАМ
WITH prod AS (
    SELECT
        sales.sales_person_id,
        AVG(sales.quantity * products.price) AS avg_amount
    FROM sales
    JOIN products ON sales.product_id = products.product_id
    GROUP BY sales.sales_person_id
),
overall AS (
    SELECT AVG(prod.avg_amount) AS overall_avg
    FROM prod
)
SELECT
    employees.first_name || ' ' || employees.last_name AS seller,
    FLOOR(prod.avg_amount) AS average_income
FROM prod
JOIN employees ON prod.sales_person_id = employees.employee_id
CROSS JOIN overall
WHERE prod.avg_amount < overall.overall_avg
ORDER BY prod.avg_amount;

-- DAY_OF_THE_WEEK_INCOME ВЫРУЧКА ПО ДНЯМ НЕДЕЛИ ДЛЯ КАЖДОГО ПРОДАВЦА
WITH a AS (
    SELECT
        sales.sales_person_id,
        sales.product_id,
        sales.sale_date,
        LOWER(TO_CHAR(sales.sale_date, 'FMDay')) AS day_of_week,
        EXTRACT(ISODOW FROM sales.sale_date) AS weekday_number,
        employees.first_name || ' ' || employees.last_name AS seller,
        sales.quantity * products.price AS income
    FROM sales
    JOIN products ON sales.product_id = products.product_id
    JOIN employees ON sales.sales_person_id = employees.employee_id
)
SELECT
    seller,
    day_of_week,
    FLOOR(SUM(income)) AS income
FROM a
GROUP BY seller, day_of_week, weekday_number
ORDER BY weekday_number, seller;

-- AGE_GROUPS ВОЗРАСТНЫЕ ГРУППЫ
WITH a AS (
    SELECT
        CASE
            WHEN customers.age BETWEEN 16 AND 25 THEN '16-25'
            WHEN customers.age BETWEEN 26 AND 40 THEN '26-40'
            ELSE '40+'
        END AS age_category
    FROM customers
    WHERE customers.age >= 16
)
SELECT
    age_category,
    COUNT(age_category) AS age_count
FROM a
GROUP BY age_category
ORDER BY age_category;

-- CUSTOMERS_BY_MONTH КОЛИЧЕСТВО УНИКАЛЬНЫХ ПОКУПАТЕЛЕЙ И ВЫРУЧКА
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(sales.quantity * products.price)) AS income
FROM sales
JOIN products ON sales.product_id = products.product_id
GROUP BY selling_month
ORDER BY selling_month;

-- SPECIAL_OFFER КЛИЕНТЫ, У КОТОРЫХ ПЕРВАЯ ПОКУПКА БЫЛА ПО АКЦИИ (PRICE = 0)
WITH a AS (
    SELECT
        sales.customer_id,
        sales.sales_person_id,
        sales.sale_date,
        sales.product_id,
        ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.sale_date) AS row_number
    FROM sales
)
SELECT
    customers.first_name || ' ' || customers.last_name AS customer,
    a.sale_date,
    employees.first_name || ' ' || employees.last_name AS seller
FROM a
JOIN products ON a.product_id = products.product_id
JOIN employees ON employees.employee_id = a.sales_person_id
JOIN customers ON customers.customer_id = a.customer_id
WHERE a.row_number = 1 AND products.price = 0
ORDER BY customers.customer_id;