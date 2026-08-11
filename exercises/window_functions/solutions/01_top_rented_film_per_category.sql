WITH rental_counts AS (
    SELECT c.category_id, c.name AS category_name, f.title,
           COUNT(*) AS rental_count,
           ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY COUNT(*) DESC) AS rn
    FROM sakila.rental r
    JOIN sakila.film f ON f.film_id = r.film_id
    JOIN sakila.film_category fc ON fc.film_id = f.film_id
    JOIN sakila.category c ON c.category_id = fc.category_id
    GROUP BY c.category_id, c.name, f.title
)
SELECT category_name, title, rental_count
FROM rental_counts
WHERE rn = 1
ORDER BY category_name;
