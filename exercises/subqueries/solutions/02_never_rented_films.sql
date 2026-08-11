SELECT f.film_id, f.title
FROM sakila.film f
WHERE NOT EXISTS (
    SELECT 1 FROM sakila.rental r WHERE r.film_id = f.film_id
)
ORDER BY f.title;
