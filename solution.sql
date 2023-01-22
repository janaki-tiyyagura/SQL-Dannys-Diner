-- What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) AS total_spent FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS visited_times FROM sales
GROUP BY customer_id;

-- What was the first item from the menu purchased by each customer?

WITH CTE AS
(
SELECT customer_id, order_date, product_name,
RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS item_order_rank FROM sales
JOIN menu
ON sales.product_id = menu.product_id
)
SELECT customer_id,  product_name  FROM CTE
WHERE item_order_rank = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(product_name) AS no_of_times_purchased FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY no_of_times_purchased DESC
LIMIT 1;

-- Which item was the most popular for each customer?
WITH CTE AS
(
SELECT customer_id, product_name, COUNT(product_name) AS no_of_times_ordered,
RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS ranks  FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id, product_name
)

SELECT customer_id, product_name, no_of_times_ordered FROM CTE 
WHERE ranks = 1;

-- Which item was purchased first by the customer after they became a member?
WITH CTE AS
(
SELECT sales.customer_id, sales.product_id,product_name, order_date,
RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS dates FROM sales
JOIN members
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date >= join_date
ORDER BY order_date
)
SELECT customer_id, order_date, product_name FROM CTE
WHERE dates = 1;

-- Which item was purchased just before the customer became a member?

WITH CTE AS
(
SELECT sales.customer_id, sales.product_id,product_name, order_date,
RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS dates FROM sales
JOIN members
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date < join_date
ORDER BY order_date
)
SELECT customer_id, order_date, product_name FROM CTE
WHERE dates = 1;

-- What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id, COUNT(sales.product_id) AS total_items, SUM(price) AS amount_spent
FROM sales
JOIN members
ON sales.customer_id = members.customer_id
JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date < join_date
GROUP BY sales.customer_id
ORDER BY amount_spent;
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


 SELECT customer_id,
 SUM(CASE WHEN product_name = 'sushi' THEN price*10*2 ELSE price*10 END) AS points FROM menu 
 JOIN sales
 ON menu.product_id = sales.product_id
 GROUP BY customer_id;
 
 -- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


SELECT sales.customer_id, 
SUM( CASE WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 7 DAY) THEN price*20 
	 WHEN product_name = 'sushi' THEN price*20 ELSE price *10 END) AS points
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
JOIN members
ON sales.customer_id = members.customer_id
WHERE order_date >= join_date AND MONTH(order_date) = 1
GROUP BY sales.customer_id;

-- Join All The Things
SELECT sales.customer_id, order_date, product_name, price,
CASE WHEN order_date>=join_date THEN 'Y' 
     ELSE 'N' 
END AS member 
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id;

-- Rank All The Things

WITH CTE AS
(
SELECT sales.customer_id, order_date, product_name, price,
CASE WHEN order_date>=join_date THEN 'Y' 
     ELSE 'N' 
END AS member
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
)
SELECT *, 
CASE WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY sales.customer_id, member ORDER BY order_date)
	 ELSE NULL
END AS ranking
FROM CTE;
