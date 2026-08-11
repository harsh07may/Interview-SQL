WITH order_totals AS (
    SELECT o.order_id, o.customer_id, o.order_date,
           SUM(oi.quantity * oi.unit_price) AS order_total
    FROM ecommerce.orders o
    JOIN ecommerce.order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
)
SELECT customer_id, order_id, order_date, order_total,
       SUM(order_total) OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS running_total
FROM order_totals
ORDER BY customer_id, order_date, order_id;
