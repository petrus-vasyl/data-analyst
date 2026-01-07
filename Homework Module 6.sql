--- Q1 ---
select
user_id,
SUM(product_price*quantity) as total_amount
from(
	select
	o.user_id,
	p.product_price,
	oi.quantity as quantity
	from order_items_sql_project as oi
	join orders_sql_project as o
	on oi.order_id=o.order_id
	join products_sql_project as p
	on p.product_id=oi.product_id
	union all
	select
	so.user_id,
	p.product_price,
	soi.quantity as quantity
	from store_order_items as soi
	join store_orders as so
	on soi.store_order_id=so.store_order_id
	join products_sql_project as p
	on p.product_id=soi.product_id
	) t
where user_id is not null
group by user_id
order by total_amount desc;
--- Q2 ---
select
user_id, order_date, order_id
from orders_sql_project
where user_id is not NULL
union all
select
user_id, order_date, store_order_id as order_id
from store_orders
where user_id is not NULL
order by user_id asc, order_date asc, order_id asc;
--- Q3 ---
select
product_id
from  order_items_sql_project
intersect
select
product_id
from store_order_items
order by product_id asc;
--- Q4 ---
SELECT DISTINCT user_id
FROM (
    SELECT o.user_id
    FROM orders_sql_project o
    JOIN order_items_sql_project oi
        ON o.order_id = oi.order_id
    GROUP BY o.user_id, oi.product_id
    HAVING SUM(oi.quantity) > 2

    INTERSECT

    SELECT so.user_id
    FROM store_orders so
    JOIN store_order_items soi
        ON so.store_order_id = soi.store_order_id
    GROUP BY so.user_id, soi.product_id
    HAVING SUM(soi.quantity) > 2
) t
WHERE user_id IS NOT NULL
ORDER BY user_id;
--- Q5 ---
SELECT AVG(order_total) AS average_check
FROM (
    SELECT
        oi.order_id,
        SUM(p.product_price * oi.quantity) AS order_total
    FROM order_items_sql_project oi
    JOIN payments_sql_project pa
        ON oi.order_id = pa.order_id
    JOIN products_sql_project p
        ON oi.product_id = p.product_id
    WHERE pa.payment_status = 'Оплачено'
    GROUP BY oi.order_id
) t;
--- Q6 ---
select
'Online' as Channel_type,
sum(oi.quantity) as Total_number_of_goods,
count (distinct oi.order_id) as total_number_of_unique_orders
from order_items_sql_project as oi
union all
select
'Offline' as Channel_type,
sum(soi.quantity) as Total_number_of_goods,
count (distinct soi.store_order_id) as total_number_of_unique_orders
from store_order_items as soi
order by Channel_type, total_number_of_goods, total_number_of_unique_orders;
--- Q7 ---
SELECT
    product_id,
    COUNT(DISTINCT user_id) AS unique_buyers
FROM (
    SELECT
        oi.product_id,
        o.user_id
    FROM order_items_sql_project oi
    JOIN orders_sql_project o
        ON oi.order_id = o.order_id
    WHERE o.user_id IS NOT NULL
    UNION ALL
    SELECT
        soi.product_id,
        so.user_id
    FROM store_order_items soi
    JOIN store_orders so
        ON soi.store_order_id = so.store_order_id
    WHERE so.user_id IS NOT NULL
) t
GROUP BY product_id
ORDER BY unique_buyers DESC
LIMIT 3;
--- Q8 ---
SELECT AVG(order_total) AS average_check,
'Online' as channel_type
FROM (
    SELECT
        oi.order_id,
        SUM(p.product_price * oi.quantity) AS order_total
    FROM order_items_sql_project oi
    JOIN payments_sql_project pa
        ON oi.order_id = pa.order_id
    JOIN products_sql_project p
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id
) t
union all
SELECT AVG(order_total) AS average_check,
'Offline' as channel_type
FROM (
    SELECT
        soi.store_order_id as order_id,
        SUM(p.product_price * soi.quantity) AS order_total
    FROM store_order_items soi
    JOIN store_payments pas
        ON soi.store_order_id = pas.store_order_id
    JOIN products_sql_project p
        ON soi.product_id = p.product_id
    GROUP BY soi.store_order_id
) t
order by average_check asc;
--- Q9 ---
SELECT DISTINCT o.user_id
FROM orders_sql_project o
JOIN order_items_sql_project oi
  ON o.order_id = oi.order_id
JOIN products_sql_project p
  ON oi.product_id = p.product_id
WHERE o.user_id IS NOT NULL
  AND p.product_price >
      (SELECT AVG(p2.product_price)
       FROM store_order_items soi
       JOIN products_sql_project p2
         ON soi.product_id = p2.product_id)
ORDER BY o.user_id ASC;
--- Q10 ---
WITH combined_orders AS (
    SELECT
        o.user_id,
        o.order_id,
        o.order_date,
        SUM(p.product_price * oi.quantity) AS order_total
    FROM orders_sql_project o
    JOIN order_items_sql_project oi
        ON o.order_id = oi.order_id
    JOIN products_sql_project p
        ON oi.product_id = p.product_id
    GROUP BY o.user_id, o.order_id, o.order_date
    UNION ALL
    SELECT
        so.user_id,
        so.store_order_id AS order_id,
        so.order_date,
        SUM(p.product_price * soi.quantity) AS order_total
    FROM store_orders so
    JOIN store_order_items soi
        ON so.store_order_id = soi.store_order_id
    JOIN products_sql_project p
        ON soi.product_id = p.product_id
    GROUP BY so.user_id, so.store_order_id, so.order_date
),
avg_orders AS (
    SELECT AVG(order_total) AS avg_order_total
    FROM combined_orders
)
SELECT
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(DISTINCT user_id) AS unique_buyers
FROM combined_orders
WHERE order_total > (SELECT avg_order_total FROM avg_orders) and user_id is not null
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY month;