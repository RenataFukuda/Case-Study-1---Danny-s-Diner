# Case Study #1 - Danny's Diner
## 8 Week SQL Challenge
If you want to try it yourself, you can find the case [here](https://8weeksqlchallenge.com/case-study-1/).

<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Image" width="200" height="208">

### 1. What is the total amount each customer spent at the restaurant?
````sql
SELECT
customer_id AS customer,
SUM(price) AS total_spent
FROM sales
JOIN menu ON sales.product_id = menu.product_id
GROUP BY customer;
````

#### Answer:
| customer | total_spent |
| -------- | ----------- |
| A        | 76          |
| B        | 74          |
| C        | 36          |

### 2. How many days has each customer visited the restaurant?
````sql
SELECT
customer_id AS customer,
COUNT(DISTINCT order_date) AS count_visit
FROM sales
GROUP BY customer;
````

#### Answer:
| customer | count_visit |
| -------- | ----------- |
| A        | 4           |
| B        | 6           |
| C        | 2           |

### 3. What was the first item from the menu purchased by each customer? 
````sql
SELECT
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
````

#### Answer:
| customer | item  |
| -------- | ----- |
| A        | sushi |
| A        | curry |
| B        | curry |
| C        | ramen |
| C        | ramen |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
````sql
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
````

#### Answer:
| item  | total_sales |
| ----  | ----------- |
| ramen | 8           |

### 5. Which item was the most popular for each customer?
````sql
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
````

#### Answer:
| customer | item  | total_sales |
| -------- | ----- | ----------- |
| A        | ramen | 3           |
| B        | curry | 2           |
| B        | ramen | 2           |
| B        | sushi | 2           |
| C        | ramen | 3           |

### 6. Which item was purchased first by the customer after they became a member?
````sql
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
````

#### Answer:
| customer_id | first_order |
| ----------- | ----------- |
| A           | curry       |
| B           | sushi       |

### 7. Which item was purchased just before the customer became a member?
````sql
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
````

#### Answer:
| customer_id | last_order |
| ----------- | ---------- |
| A           | curry      |
| A           | sushi      |
| B           | sushi      |

### 8. What is the total items and amount spent for each member before they became a member?
````sql
SELECT distinct
    sales.customer_id,
	COUNT(sales.product_id) OVER (PARTITION BY sales.customer_id) as total_items,
    SUM(price) OVER (PARTITION BY sales.customer_id) as total_spent
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date < join_date;
````

#### Answer:
| customer | total_items  | total_spent |
| -------- | ------------ | ----------- |
| A        | 2            | 25          |
| B        | 3            | 40          |

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
````sql
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
````

#### Answer:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
````sql
(SELECT
	sales.customer_id,
	IF(order_date >= join_date AND order_date < DATE_ADD(join_date, INTERVAL 1 WEEK), price*20, IF(product_name='sushi', price*20, price*10)) as points
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id = members.customer_id
WHERE order_date <= '2021-01-31')

SELECT
	customer_id,
    SUM(points)
FROM members_points_until_jan
GROUP BY customer_id
ORDER BY customer_id;
````

#### Answer:
| customer_id | jan_points |
| ----------- | ---------- |
| A           | 1370       |
| B           | 820        |