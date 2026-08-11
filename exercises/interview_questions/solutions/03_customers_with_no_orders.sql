-- Anti-join: LEFT JOIN to orders, then keep only rows where no matching
-- order exists (the join produced NULLs on the orders side).
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name
FROM ecommerce.customers c
LEFT JOIN ecommerce.orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY customer_name;
