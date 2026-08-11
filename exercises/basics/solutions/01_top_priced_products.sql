-- Sort descending by price and cap the result with LIMIT.
SELECT product_name, unit_price
FROM ecommerce.products
ORDER BY unit_price DESC
LIMIT 5;
