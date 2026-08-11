SELECT cat.category_name, SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM ecommerce.order_items oi
JOIN ecommerce.products p ON p.product_id = oi.product_id
JOIN ecommerce.categories cat ON cat.category_id = p.category_id
GROUP BY cat.category_name
ORDER BY total_revenue DESC;
