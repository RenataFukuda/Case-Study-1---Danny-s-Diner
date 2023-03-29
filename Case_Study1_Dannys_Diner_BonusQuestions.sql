USE dannys_diner;

-- Join All The Things
SELECT
	sales.customer_id,
    order_date,
    product_name,
    price,
    IF(order_date >= join_date, 'Y', 'N') as member
FROM sales
JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY customer_id, order_date;

-- Rank All The Things
WITH join_all as
(SELECT
	sales.customer_id,
    order_date,
    product_name,
    price,
    IF(order_date >= join_date, 'Y', 'N') as member
FROM sales
JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY customer_id, order_date)

SELECT *,
	IF(member='N', null, RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date ASC)) as ranking
FROM join_all;

