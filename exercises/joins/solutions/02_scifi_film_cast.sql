-- Chain of inner joins from film through film_category/category (to filter
-- by genre) and film_actor/actor (to reach the cast).
SELECT f.title, a.first_name || ' ' || a.last_name AS actor_name
FROM sakila.film f
JOIN sakila.film_category fc ON fc.film_id = f.film_id
JOIN sakila.category c ON c.category_id = fc.category_id
JOIN sakila.film_actor fa ON fa.film_id = f.film_id
JOIN sakila.actor a ON a.actor_id = fa.actor_id
WHERE c.name = 'Sci-Fi'
ORDER BY f.title, actor_name;
