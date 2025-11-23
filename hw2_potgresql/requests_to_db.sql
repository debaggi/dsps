-- Вывести все уникальные бренды, у которых есть хотя бы один продукт со стандартной стоимостью выше 1500 долларов, и суммарными продажами не менее 1000 единиц.
SELECT DISTINCT p.brand
FROM products__upd p
JOIN order__items oi ON p.index = oi.product_id
WHERE p.standard_cost > 1500
GROUP BY p.brand
HAVING SUM(oi.quantity) >= 1000;

-- Для каждого дня в диапазоне с 2017-04-01 по 2017-04-09 включительно вывести количество подтвержденных онлайн-заказов и количество уникальных клиентов, совершивших эти заказы.
SELECT 
    order_date,
    COUNT(*) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers
FROM order_20_customers_upd 
WHERE order_date BETWEEN '2017-04-01' AND '2017-04-09'
    AND online_order = True
    AND order_status = 'Approved'
GROUP BY order_date
ORDER BY order_date;

-- Вывести профессии клиентов:
-- из сферы IT, чья профессия начинается с Senior;
-- из сферы Financial Services, чья профессия начинается с Lead.
-- Для обеих групп учитывать только клиентов старше 35 лет. Объединить выборки с помощью UNION ALL.

SELECT 
    customer_id,
    first_name,
    last_name,
    job_title,
    job_industry_category
FROM customers_upd_20 
WHERE job_industry_category = 'IT' 
    AND job_title LIKE 'Senior%'
    AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, DOB)) > 35
    AND DOB IS NOT NULL

UNION ALL

SELECT 
    customer_id,
    first_name,
    last_name,
    job_title,
    job_industry_category
FROM customers_upd_20 
WHERE job_industry_category = 'Financial Services' 
    AND job_title LIKE 'Lead%'
    AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, DOB)) > 35
    AND DOB IS NOT NULL;

-- Вывести бренды, которые были куплены клиентами из сферы Financial Services, но не были куплены клиентами из сферы IT.
SELECT DISTINCT p.brand
FROM products__upd p
JOIN order__items oi ON p.index = oi.product_id
JOIN order_20_customers_upd oc ON oi.order_id = oc.order_id
JOIN customers_upd_20 c ON oc.customer_id = c.customer_id
WHERE c.job_industry_category = 'Financial Services'
    AND p.brand IS NOT NULL
    AND p.brand != ''

EXCEPT

SELECT DISTINCT p.brand
FROM products__upd p
JOIN order__items oi ON p.index = oi.product_id
JOIN order_20_customers_upd oc ON oi.order_id = oc.order_id
JOIN customers_upd_20 c ON oc.customer_id = c.customer_id
WHERE c.job_industry_category = 'IT'
    AND p.brand IS NOT NULL
    AND p.brand != '';

-- Вывести 10 клиентов (ID, имя, фамилия), которые совершили наибольшее количество онлайн-заказов (в штуках) брендов 
-- Giant Bicycles, Norco Bicycles, Trek Bicycles, при условии, что они активны и имеют оценку имущества (property_valuation) 
-- выше среднего среди клиентов из того же штата.
WITH state_avg_property AS (
    SELECT 
        state,
        AVG(property_valuation) as avg_property
    FROM customers_upd_20
    WHERE state IS NOT NULL
    GROUP BY state
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(*) as order_count
FROM customers_upd_20 c
JOIN order_20_customers_upd oc ON c.customer_id = oc.customer_id
JOIN order__items oi ON oc.order_id = oi.order_id
JOIN products__upd p ON oi.product_id = p.index
WHERE oc.online_order = True
    AND oc.order_status = 'Approved'
    AND p.brand IN ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
    AND c.deceased_indicator = 'N'
    AND c.property_valuation > (
        SELECT avg_property 
        FROM state_avg_property sap 
        WHERE sap.state = c.state
    )
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY order_count DESC
LIMIT 10;

-- Вывести всех клиентов (ID, имя, фамилия), у которых нет подтвержденных онлайн-заказов за последний год, но при этом они владеют автомобилем и их сегмент благосостояния не Mass Customer.
SELECT 
    customer_id,
    first_name,
    last_name
FROM customers_upd_20 c
WHERE NOT EXISTS (
    SELECT 1 
    FROM order_20_customers_upd oc 
    WHERE oc.customer_id = c.customer_id 
        AND oc.online_order = True 
        AND oc.order_status = 'Approved'
        AND oc.order_date >= CURRENT_DATE - INTERVAL '1 year'
)
    AND c.owns_car = True
    AND c.wealth_segment != 'Mass Customer'
    AND c.deceased_indicator = 'N';

-- Вывести всех клиентов из сферы 'IT' (ID, имя, фамилия), которые купили 2 из 5 продуктов с самой высокой list_price в продуктовой линейке Road.
WITH top_road_products AS (
    SELECT index as product_id
    FROM products__upd 
    WHERE product_line = 'Road'
    ORDER BY list_price DESC
    LIMIT 5
),
customer_road_purchases AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT p.index) as purchased_top_products
    FROM customers_upd_20 c
    JOIN order_20_customers_upd oc ON c.customer_id = oc.customer_id
    JOIN order__items oi ON oc.order_id = oi.order_id
    JOIN products__upd p ON oi.product_id = p.index
    WHERE c.job_industry_category = 'IT'
        AND p.index IN (SELECT product_id FROM top_road_products)
        AND oc.order_status = 'Approved'
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_id,
    first_name,
    last_name
FROM customer_road_purchases
WHERE purchased_top_products >= 2;

-- ывести клиентов (ID, имя, фамилия, сфера деятельности) из сфер IT или Health, 
-- которые совершили не менее 3 подтвержденных заказов в период 2017-01-01 по 2017-03-01, 
-- и при этом их общий доход от этих заказов превышает 10 000 долларов.
-- Разделить вывод на две группы (IT и Health) с помощью UNION.
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category,
    COUNT(DISTINCT oc.order_id) as order_count,
    SUM(oi.quantity * oi.item_list_price_at_sale) as total_revenue
FROM customers_upd_20 c
JOIN order_20_customers_upd oc ON c.customer_id = oc.customer_id
JOIN order__items oi ON oc.order_id = oi.order_id
WHERE c.job_industry_category = 'IT'
    AND oc.order_date BETWEEN '2017-01-01' AND '2017-03-01'
    AND oc.order_status = 'Approved'
GROUP BY c.customer_id, c.first_name, c.last_name, c.job_industry_category
HAVING COUNT(DISTINCT oc.order_id) >= 3
    AND SUM(oi.quantity * oi.item_list_price_at_sale) > 10000

UNION

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category,
    COUNT(DISTINCT oc.order_id) as order_count,
    SUM(oi.quantity * oi.item_list_price_at_sale) as total_revenue
FROM customers_upd_20 c
JOIN order_20_customers_upd oc ON c.customer_id = oc.customer_id
JOIN order__items oi ON oc.order_id = oi.order_id
WHERE c.job_industry_category = 'Health'
    AND oc.order_date BETWEEN '2017-01-01' AND '2017-03-01'
    AND oc.order_status = 'Approved'
GROUP BY c.customer_id, c.first_name, c.last_name, c.job_industry_category
HAVING COUNT(DISTINCT oc.order_id) >= 3
    AND SUM(oi.quantity * oi.item_list_price_at_sale) > 10000;
