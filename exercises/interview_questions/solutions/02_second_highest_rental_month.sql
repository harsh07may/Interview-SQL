-- Aggregate rentals per calendar month, then OFFSET past the top row to reach
-- 2nd place. Order by rental_month as a tiebreaker so a count tie resolves
-- deterministically.
WITH monthly_counts AS (
    SELECT to_char(rental_date, 'YYYY-MM') AS rental_month, COUNT(*) AS rental_count
    FROM sakila.rental
    GROUP BY rental_month
)
SELECT rental_month, rental_count
FROM monthly_counts
ORDER BY rental_count DESC, rental_month
OFFSET 1 LIMIT 1;
