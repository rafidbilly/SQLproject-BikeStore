CREATE DATABASE bike_store;

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

# 2. SEASONALITY ANALYSIS
# average units sold for each month of the year, for each product category
-- orders --> order_date, order_id
-- order_items --> order_id, product_id, quantity
-- products --> product_id, category_id
-- categories --> category_id, category_name
SELECT
    MONTH(o.order_date) AS months,
   c.category_name,
   AVG(oi.quantity) AS avg_units_sold
FROM
	orders o
		JOIN
	order_items oi ON o.order_id = oi.order_id
		JOIN
    products p ON oi.product_id = p.product_id
		JOIN
    categories c ON p.category_id = c.category_id
GROUP BY 
    months,
    c.category_name
ORDER BY 
    months;
    
# 3. top 10 customers based on sales
-- orders --> order_id, customer_id
-- order_items --> order_id, (quantity * list_price * (1-discount))
-- customers --> customer_id, first_name, last_name

SELECT
    CONCAT(c.first_name, " ", c.last_name) AS full_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.list_price * (1 - oi.discount)) DESC) AS rank_num
FROM
	orders o
		JOIN
	order_items oi ON o.order_id = oi.order_id
		JOIN
	customers c ON o.customer_id = c.customer_id
GROUP BY 1
LIMIT 10;

#4. Time Intervals between Engagements
# Calculate average time between consecutive purchases for customers
SELECT
	customer_id,
    full_name,
    AVG(DATEDIFF(order_date, prev_order_date)) AS avg_order_interval
FROM
(SELECT
	c.customer_id,
    CONCAT(c.first_name, " ", c.last_name) AS full_name,
    o.order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
FROM
	orders o
		JOIN
	customers c ON o.customer_id = c.customer_id) a
GROUP BY 1, 2;