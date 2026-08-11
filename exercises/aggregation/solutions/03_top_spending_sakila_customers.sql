-- Group by the customer's actual primary key, not the derived full-name
-- label — two different customers can share a full name in this seed data.
SELECT c.first_name || ' ' || c.last_name AS customer_name, SUM(p.amount) AS total_spent
FROM sakila.payment p
JOIN sakila.customer c ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 5;
