-- ОБЩЕЕ КОЛИЧЕСТВО КЛИЕНТОВ
SELECT COUNT(c.customer_id) AS customers_count
FROM customers AS c;


-- ТОП-10 ЛУЧШИХ ПРОДАВЦОВ ПО ВЫРУЧКЕ
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(COUNT(s.quantity)) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN products AS p
    ON s.product_id = p.product_id
JOIN employees AS e
    ON s.sales_person_id = e.employee_id
GROUP BY e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;


-- ПРОДАВЦЫ С НИЗКОЙ СРЕДНЕЙ ВЫРУЧКОЙ
WITH prod AS (
    SELECT
        s.sales_person_id,
        AVG(s.quantity * p.price) AS avg_amount
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY s.sales_person_id
),

overall AS (
    SELECT AVG(prod.avg_amount) AS overall_avg
    FROM prod
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(prod.avg_amount) AS average_income
FROM prod
JOIN employees AS e
    ON prod.sales_person_id = e.employee_id
CROSS JOIN overall AS o
WHERE prod.avg_amount < o.overall_avg
ORDER BY prod.avg_amount;


-- ВЫРУЧКА ПО ДНЯМ НЕДЕЛИ
WITH a AS (
    SELECT
        s.sales_person_id,
        s.product_id,
        s.sale_date,
        LOWER(TO_CHAR(s.sale_date, 'FMDay')) AS day_of_week,
        EXTRACT(ISODOW FROM s.sale_date) AS weekday_number,
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        s.quantity * p.price AS income
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN employees AS e
        ON s.sales_person_id = e.employee_id
)

SELECT
    seller,
    day_of_week,
    FLOOR(SUM(income)) AS income
FROM a
GROUP BY seller, day_of_week, weekday_number
ORDER BY weekday_number, seller;


-- ВОЗРАСТНЫЕ ГРУППЫ
WITH a AS (
    SELECT
        CASE
            WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
            WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
            ELSE '40+'
        END AS age_category
    FROM customers AS c
    WHERE c.age >= 16
)

SELECT
    age_category,
    COUNT(age_category) AS age_count
FROM a
GROUP BY age_category
ORDER BY age_category;


-- КОЛИЧЕСТВО УНИКАЛЬНЫХ КЛИЕНТОВ И ВЫРУЧКА ПО МЕСЯЦАМ
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;


-- КЛИЕНТЫ С ПЕРВОЙ ПОКУПКОЙ ПО АКЦИИ
WITH a AS (
    SELECT
        s.customer_id,
        s.sales_person_id,
        s.sale_date,
        s.product_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date
        ) AS row_number
    FROM sales AS s
)

SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    a.sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM a
JOIN products AS p
    ON a.product_id = p.product_id
JOIN employees AS e
    ON a.sales_person_id = e.employee_id
JOIN customers AS c
    ON a.customer_id = c.customer_id
WHERE a.row_number = 1
  AND p.price = 0
ORDER BY c.customer_id;
