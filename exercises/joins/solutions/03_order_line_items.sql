SELECT o.order_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       o.order_date,
       p.product_name,
       oi.quantity
FROM ecommerce.orders o
JOIN ecommerce.customers c ON c.customer_id = o.customer_id
JOIN ecommerce.order_items oi ON oi.order_id = o.order_id
JOIN ecommerce.products p ON p.product_id = oi.product_id
ORDER BY o.order_id, p.product_name;
