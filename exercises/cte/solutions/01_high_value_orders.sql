-- CTE computes each order's total first, then the outer query filters on
-- that computed total (can't filter on an alias in the same-level WHERE).
WITH order_totals AS (
    SELECT o.order_id, o.customer_id,
           SUM(oi.quantity * oi.unit_price) AS order_total
    FROM ecommerce.orders o
    JOIN ecommerce.order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id
)
SELECT order_id, customer_id, order_total
FROM order_totals
WHERE order_total > 150
ORDER BY order_total DESC;
