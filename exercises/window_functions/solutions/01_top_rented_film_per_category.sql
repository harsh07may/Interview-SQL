-- Window function ranks films by rental count within each category, then the
-- outer query keeps only rank 1. Group by f.film_id (not just f.title) since
-- film titles aren't unique in this seed data; break ROW_NUMBER ties by
-- film_id so the result is deterministic.
WITH rental_counts AS (
    SELECT c.category_id, c.name AS category_name, f.film_id, f.title,
           COUNT(*) AS rental_count,
           ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY COUNT(*) DESC, f.film_id) AS rn
    FROM sakila.rental r
    JOIN sakila.film f ON f.film_id = r.film_id
    JOIN sakila.film_category fc ON fc.film_id = f.film_id
    JOIN sakila.category c ON c.category_id = fc.category_id
    GROUP BY c.category_id, c.name, f.film_id, f.title
)
SELECT category_name, title, rental_count
FROM rental_counts
WHERE rn = 1
ORDER BY category_name;
