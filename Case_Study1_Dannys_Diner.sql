-- Study Questions
-- Each of the following case study questions can be answered using a single SQL statement:

USE dannys_diner;

-- 1.What is the total amount each customer spent at the restaurant?

SELECT
customer_id AS customer,
SUM(price) AS total_spent
FROM sales
JOIN menu ON sales.product_id = menu.product_id
GROUP BY customer;

-- 2. How many days has each customer visited the restaurant?

SELECT
customer_id AS customer,
COUNT(DISTINCT order_date) AS count_visit
FROM sales
GROUP BY customer;

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT
	customer_id,
	product_name as item
FROM(SELECT
    customer_id,
    product_name,
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as date_rank
    FROM sales
    JOIN menu ON sales.product_id = menu.product_id
    ) as x
WHERE date_rank=1;

SELECT
    customer_id,
    product_name,
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as date_rank
    FROM sales
    JOIN menu ON sales.product_id = menu.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	item,
    total_sales
FROM(
	SELECT
		product_name as item,
		COUNT(product_name) as total_sales,
        DENSE_RANK () over(ORDER BY COUNT(product_name) DESC) AS sales_rank
	FROM sales
	JOIN menu ON sales.product_id = menu.product_id
	GROUP BY product_name) AS item_sales
WHERE sales_rank = 1;

SELECT
		product_name as item,
		COUNT(product_name) as total_sales
	FROM sales
	JOIN menu ON sales.product_id = menu.product_id
	GROUP BY product_name;
    
-- 5. Which item was the most popular for each customer?
 
SELECT
	customer_id,
    item,
    total_sales
FROM(
	SELECT *,
		DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY total_sales DESC)  as pop_rank
	FROM(
		SELECT DISTINCT
		  customer_id,
		  product_name as item,
		  COUNT(*) OVER (PARTITION BY customer_id, product_name) as total_sales
		FROM sales
		JOIN menu ON sales.product_id = menu.product_id) as customer_item) as customer_item_rank
WHERE pop_rank = 1;

SELECT DISTINCT
	customer_id,
	product_name as item,
	COUNT(*) OVER (PARTITION BY customer_id, product_name) as total_sales
FROM sales
JOIN menu ON sales.product_id = menu.product_id;

-- 6. Which item was purchased first by the customer after they became a member?
 WITH member_sales as
(SELECT
	sales.customer_id,
    product_name as item,
    order_date,
    join_date,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as first_order 
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date >= join_date)

SELECT
	customer_id,
    item as first_order
FROM member_sales
WHERE first_order = 1;

SELECT
	sales.customer_id,
    product_name as item,
    order_date,
    join_date,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as first_order
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date >= join_date;
    
-- 7. Which item was purchased just before the customer became a member?
WITH no_member_sales as
(SELECT
	sales.customer_id,
    product_name as item,
    order_date,
    join_date,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as last_order 
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date < join_date)

SELECT
	customer_id,
    item as last_order
FROM no_member_sales
WHERE last_order = 1;

SELECT
	sales.customer_id,
    product_name as item,
    order_date,
    join_date,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as last_order
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date < join_date;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT distinct
    sales.customer_id,
	COUNT(sales.product_id) OVER (PARTITION BY sales.customer_id) as total_items,
    SUM(price) OVER (PARTITION BY sales.customer_id) as total_spent
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date < join_date;

SELECT distinct
    sales.customer_id,
    menu.product_name as item,
	COUNT(sales.product_id) OVER (PARTITION BY sales.customer_id, sales.product_id),
    SUM(price) OVER (PARTITION BY sales.customer_id, sales.product_id)
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date < join_date;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
WITH points as
(SELECT 
	customer_id,
	IF(product_name='sushi', price*20, price*10) as points
FROM sales
JOIN menu ON sales.product_id = menu.product_id)

SELECT
	customer_id,
    SUM(points) as total_points
FROM points
GROUP BY customer_id;

SELECT 
	*,
	IF(product_name='sushi', price*20, price*10) as points
FROM sales
JOIN menu ON sales.product_id = menu.product_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

WITH members_points_until_jan as
(SELECT
	sales.customer_id,
	IF(order_date >= join_date AND order_date < DATE_ADD(join_date, INTERVAL 1 WEEK), price*20, IF(product_name='sushi', price*20, price*10)) as points
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date <= '2021-01-31')

SELECT
	customer_id,
    SUM(points) as jan_points
FROM members_points_until_jan
GROUP BY customer_id
ORDER BY customer_id;

SELECT*,
	IF(order_date >= join_date AND order_date < DATE_ADD(join_date, INTERVAL 1 WEEK), price*20, IF(product_name='sushi', price*20, price*10)) as points
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date <= '2021-01-31'
ORDER BY sales.customer_id;

