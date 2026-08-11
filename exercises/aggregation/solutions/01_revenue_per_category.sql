-- Join order_items up to products and categories, then SUM(quantity * unit_price)
-- per category to get total revenue. Excludes cancelled orders, which never
-- generated real revenue even though their line items are still in the data.
SELECT cat.category_name, SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM ecommerce.order_items oi
JOIN ecommerce.orders o ON o.order_id = oi.order_id
JOIN ecommerce.products p ON p.product_id = oi.product_id
JOIN ecommerce.categories cat ON cat.category_id = p.category_id
WHERE o.status <> 'cancelled'
GROUP BY cat.category_name
ORDER BY total_revenue DESC;
