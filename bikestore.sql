CREATE DATABASE bike_store;

SELECT * FROM brands;
SELECT * FROM categories;
SELECT * FROM customers;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM staffs;
SELECT * FROM stocks;
SELECT * FROM stores;

# 1. CUSTOMER SEGMENTATION
# segment customers based on order count, total spent, and recency
-- order count
/* SELECT
	customer_id,
    COUNT(order_id) AS order_count    --> NOTE this shows the correct result ONLY before joining orders and order_items because some customers orders different kind of items (different item_id)
FROM
	orders
GROUP BY
	customer_id;*/
SELECT
	o.customer_id,
    COUNT(DISTINCT o.order_id) AS order_count
FROM
	orders o
		JOIN
	order_items oi ON o.order_id = oi.order_id
GROUP BY
	customer_id;

-- total spent
SELECT
	customer_id,
    SUM(quantity * list_price * (1 - discount)) AS total_spent
FROM
	orders o
		JOIN
	order_items oi ON o.order_id = oi.order_id
GROUP BY customer_id;

-- recency
SELECT
    MAX(order_date)
FROM
	orders; # 2018-12-28

SELECT
	customer_id,
    DATEDIFF("2018-12-28", MAX(CAST(order_date AS date))) AS days_since_last_order
FROM
	orders
GROUP BY customer_id;

-- final customer segmentation
WITH customer_stats AS (
	SELECT
		o.customer_id,
		COUNT(DISTINCT o.order_id) AS order_count,
		SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent,
		DATEDIFF("2018-12-28", MAX(CAST(o.order_date AS date))) AS days_since_last_order
	FROM
		orders o
			JOIN
		order_items oi ON o.order_id = oi.order_id
	GROUP BY customer_id)
SELECT
	customer_id,
    CASE WHEN order_count > 1 THEN "Repeat Buyer"
		ELSE "One-time Buyer"
    END AS cust_order_freq,
    CASE WHEN total_spent / (SELECT MAX(total_spent) FROM customer_stats) >= .65 THEN "Big Spender"
		WHEN total_spent / (SELECT MAX(total_spent) FROM customer_stats) <= .30 THEN "Small Spender"
		ELSE "Average Spender"
    END AS buying_power,
    CASE WHEN days_since_last_order < 90 THEN "Recent Buyer"
		ELSE "Not Recent Buyer"
    END AS order_recency
FROM
customer_stats
ORDER BY customer_id;

