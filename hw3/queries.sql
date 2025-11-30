
-- 1
-- Вывести распределение (количество) клиентов по сферам деятельности
-- отсортировав результат по убыванию количества.

SELECT 
    c.job_industry_category,
    COUNT(*) AS cust_count
FROM customer as c
GROUP BY job_industry_category
ORDER BY cust_count DESC;

-- 2
-- Найти общую сумму дохода (list_price*quantity) по всем подтвержденным заказам за каждый месяц по сферам деятельности клиентов. 
-- Отсортировать результат по году, месяцу и сфере деятельности.
SELECT 
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month,
    c.job_industry_category,
    SUM(oi.item_list_price_at_sale * oi.quantity) AS total_revenue
FROM "order" as o
JOIN customer c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Approved'
GROUP BY 
    EXTRACT(YEAR FROM o.order_date),
    EXTRACT(MONTH FROM o.order_date),
    c.job_industry_category
ORDER BY year ASC, month ASC, job_industry_category ASC;

-- 3
-- Вывести количество уникальных онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT. 
-- Включить бренды, у которых нет онлайн-заказов от IT-клиентов, — для них должно быть указано количество 0. 
-- Найти по всем клиентам: сумму всех заказов (общего дохода), максимум, минимум и количество заказов, а также среднюю сумму заказа по каждому клиенту. 
-- Отсортировать результат по убыванию суммы всех заказов и количества заказов. 
-- Выполнить двумя способами: используя только GROUP BY и используя только оконные функции. Сравнить результат.
-- Считаем уникальные order_id, где заказ онлайн и клиент из IT, затем left join ко всем брендам

SELECT 
    p.brand,
    COUNT(DISTINCT CASE 
        WHEN c.job_industry_category = 'IT' 
             AND o.online_order = TRUE 
             AND o.order_status = 'Approved'
        THEN o.order_id 
    END) AS online_orders_count
FROM "product" as p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN "order" o ON oi.order_id = o.order_id
LEFT JOIN customer c ON o.customer_id = c.customer_id
GROUP BY p.brand
ORDER BY online_orders_count DESC;


-- 4
-- Найти по всем клиентам: сумму всех заказов (общего дохода), максимум, минимум и количество заказов, а также среднюю сумму заказа по каждому клиенту. Отсортировать результат по убыванию суммы всех заказов и количества заказов. 
-- Выполнить двумя способами: используя только GROUP BY и используя только оконные функции. Сравнить результат.

                                                 -- МЕТОД через оконку

WITH order_amounts AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        o.order_id,
        oi.item_list_price_at_sale * oi.quantity AS order_amount
    FROM "customer" as c
    LEFT JOIN "order" o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
)
SELECT DISTINCT
    customer_id,
    first_name,
    last_name,
    COALESCE(SUM(order_amount) OVER (PARTITION BY customer_id), 0) AS total_revenue,
    COALESCE(MAX(order_amount) OVER (PARTITION BY customer_id), 0) AS max_order,
    COALESCE(MIN(order_amount) OVER (PARTITION BY customer_id), 0) AS min_order,
    COUNT(DISTINCT order_id) OVER (PARTITION BY customer_id) AS order_count,
    COALESCE(AVG(order_amount) OVER (PARTITION BY customer_id), 0) AS avg_order
FROM order_amounts
ORDER BY total_revenue DESC, order_count DESC;

                                                 -- МЕТОД через группировку

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COALESCE(SUM(oi.item_list_price_at_sale * oi.quantity), 0) AS total_revenue,
    COALESCE(MAX(oi.item_list_price_at_sale * oi.quantity), 0) AS max_order,
    COALESCE(MIN(oi.item_list_price_at_sale * oi.quantity), 0) AS min_order,
    COUNT(DISTINCT o.order_id) AS order_count,
    COALESCE(AVG(oi.item_list_price_at_sale * oi.quantity), 0) AS avg_order
FROM "customer" as c
LEFT JOIN "order" o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC, order_count DESC;

-- вывод: и оконка и группировка возращают единый результат 

-- 5
-- Найти имена и фамилии клиентов с топ-3 минимальной и топ-3 максимальной суммой транзакций за весь период 
-- (учесть клиентов, у которых нет заказов, приняв их сумму транзакций за 0).
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        COALESCE(SUM(oi.item_list_price_at_sale * oi.quantity), 0) AS total_revenue
    FROM "customer" as c
    LEFT JOIN "order" o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue ASC) AS rank_asc,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank_desc
    FROM customer_revenue
)
SELECT first_name, last_name, total_revenue
FROM "ranked"
WHERE rank_asc <= 3 OR rank_desc <= 3
ORDER BY total_revenue ASC;

-- 6
-- Вывести только вторые транзакции клиентов (если они есть) с помощью оконных функций. 
-- Если у клиента меньше двух транзакций, он не должен попасть в результат.
WITH ranked_orders AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        o.order_id,
        o.order_date,
        oi.item_list_price_at_sale * oi.quantity AS order_amount,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS order_rank
    FROM "customer" as c
    JOIN "order" o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
)
SELECT 
    customer_id,
    first_name,
    last_name,
    order_id,
    order_date,
    order_amount
FROM "ranked_orders" as rank_ord
WHERE order_rank = 2;

-- 7
-- Вывести имена, фамилии и профессии клиентов, а также длительность максимального интервала (в днях) между двумя последовательными заказами. 
-- Исключить клиентов, у которых только один или меньше заказов.
WITH order_dates AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.job_title,
        o.order_date,
        LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS prev_order_date
    FROM "customer" as c
    JOIN "order" o ON c.customer_id = o.customer_id
),
intervals AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        job_title,
        order_date - prev_order_date AS interval_days
    FROM "order_dates" as ord_dt
    WHERE prev_order_date IS NOT NULL
)
SELECT 
    customer_id,
    first_name,
    last_name,
    job_title,
    MAX(interval_days) AS max_interval_days
FROM "intervals"
GROUP BY customer_id, first_name, last_name, job_title
HAVING COUNT(*) >= 1
ORDER BY max_interval_days DESC;



-- 8
-- Найти топ-5 клиентов (по общему доходу) в каждом сегменте благосостояния (wealth_segment). 
-- Вывести имя, фамилию, сегмент и общий доход. Если в сегменте менее 5 клиентов, вывести всех.

WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.wealth_segment,
        COALESCE(SUM(oi.item_list_price_at_sale * oi.quantity), 0) AS total_revenue
    FROM "customer" as c
    LEFT JOIN "order" o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.wealth_segment
),
ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY wealth_segment ORDER BY total_revenue DESC) AS rank
    FROM customer_revenue
)
SELECT 
    first_name,
    last_name,
    wealth_segment,
    total_revenue
FROM "ranked"
WHERE rank <= 5
ORDER BY wealth_segment ASC, rank ASC;
