SELECT p.product_name, p.category_id, p.unit_price
FROM ecommerce.products p
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM ecommerce.products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY p.category_id, p.unit_price DESC;
