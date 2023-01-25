-- What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) AS total_spent FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

+-------------+-------------+
| customer_id | total_spent |
+-------------+-------------+
| A           |          76 |
| B           |          74 |
| C           |          36 |
+-------------+-------------+

-- How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS visited_times FROM sales
GROUP BY customer_id;


+-------------+---------------+
| customer_id | visited_times |
+-------------+---------------+
| A           |             4 |
| B           |             6 |
| C           |             2 |
+-------------+---------------+


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

+-------------+--------------+
| customer_id | product_name |
+-------------+--------------+
| A           | sushi        |
| A           | curry        |
| B           | curry        |
| C           | ramen        |
| C           | ramen        |
+-------------+--------------+

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(product_name) AS no_of_times_purchased FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY no_of_times_purchased DESC
LIMIT 1;

+--------------+-----------------------+
| product_name | no_of_times_purchased |
+--------------+-----------------------+
| ramen        |                     8 |
+--------------+-----------------------+


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

+-------------+--------------+---------------------+
| customer_id | product_name | no_of_times_ordered |
+-------------+--------------+---------------------+
| A           | ramen        |                   3 |
| B           | curry        |                   2 |
| B           | sushi        |                   2 |
| B           | ramen        |                   2 |
| C           | ramen        |                   3 |
+-------------+--------------+---------------------+

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

+-------------+------------+--------------+
| customer_id | order_date | product_name |
+-------------+------------+--------------+
| A           | 2021-01-07 | curry        |
| B           | 2021-01-11 | sushi        |
+-------------+------------+--------------+


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

+-------------+------------+--------------+
| customer_id | order_date | product_name |
+-------------+------------+--------------+
| A           | 2021-01-01 | sushi        |
| A           | 2021-01-01 | curry        |
| B           | 2021-01-04 | sushi        |
+-------------+------------+--------------+


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

+-------------+-------------+--------------+
| customer_id | total_items | amount_spent |
+-------------+-------------+--------------+
| A           |           2 |           25 |
| B           |           3 |           40 |
+-------------+-------------+--------------+


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

 SELECT customer_id,
 SUM(CASE WHEN product_name = 'sushi' THEN price*10*2 ELSE price*10 END) AS points FROM menu 
 JOIN sales
 ON menu.product_id = sales.product_id
 GROUP BY customer_id;
 
 +-------------+--------+
| customer_id | points |
+-------------+--------+
| A           |    860 |
| B           |    940 |
| C           |    360 |
+-------------+--------+


 -- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT sales.customer_id, 
SUM(CASE WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY) THEN price*20 
	 WHEN product_name = 'sushi' THEN price*20 ELSE price *10 END) AS points
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
JOIN members
ON sales.customer_id = members.customer_id
WHERE MONTH(order_date) = 1
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

+-------------+--------+
| customer_id | points |
+-------------+--------+
| A           |   1370 |
| B           |    820 |
+-------------+--------+


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


+-------------+------------+--------------+-------+--------+
| customer_id | order_date | product_name | price | member |
+-------------+------------+--------------+-------+--------+
| A           | 2021-01-01 | sushi        |    10 | N      |
| A           | 2021-01-01 | curry        |    15 | N      |
| A           | 2021-01-07 | curry        |    15 | Y      |
| A           | 2021-01-10 | ramen        |    12 | Y      |
| A           | 2021-01-11 | ramen        |    12 | Y      |
| A           | 2021-01-11 | ramen        |    12 | Y      |
| B           | 2021-01-01 | curry        |    15 | N      |
| B           | 2021-01-02 | curry        |    15 | N      |
| B           | 2021-01-04 | sushi        |    10 | N      |
| B           | 2021-01-11 | sushi        |    10 | Y      |
| B           | 2021-01-16 | ramen        |    12 | Y      |
| B           | 2021-02-01 | ramen        |    12 | Y      |
| C           | 2021-01-01 | ramen        |    12 | N      |
| C           | 2021-01-01 | ramen        |    12 | N      |
| C           | 2021-01-07 | ramen        |    12 | N      |
+-------------+------------+--------------+-------+--------+


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

+-------------+------------+--------------+-------+--------+---------+
| customer_id | order_date | product_name | price | member | ranking |
+-------------+------------+--------------+-------+--------+---------+
| A           | 2021-01-01 | sushi        |    10 | N      |    NULL |
| A           | 2021-01-01 | curry        |    15 | N      |    NULL |
| A           | 2021-01-07 | curry        |    15 | Y      |       1 |
| A           | 2021-01-10 | ramen        |    12 | Y      |       2 |
| A           | 2021-01-11 | ramen        |    12 | Y      |       3 |
| A           | 2021-01-11 | ramen        |    12 | Y      |       3 |
| B           | 2021-01-01 | curry        |    15 | N      |    NULL |
| B           | 2021-01-02 | curry        |    15 | N      |    NULL |
| B           | 2021-01-04 | sushi        |    10 | N      |    NULL |
| B           | 2021-01-11 | sushi        |    10 | Y      |       1 |
| B           | 2021-01-16 | ramen        |    12 | Y      |       2 |
| B           | 2021-02-01 | ramen        |    12 | Y      |       3 |
| C           | 2021-01-01 | ramen        |    12 | N      |    NULL |
| C           | 2021-01-01 | ramen        |    12 | N      |    NULL |
| C           | 2021-01-07 | ramen        |    12 | N      |    NULL |
+-------------+------------+--------------+-------+--------+---------+
