WITH monthly_counts AS (
    SELECT to_char(rental_date, 'YYYY-MM') AS rental_month, COUNT(*) AS rental_count
    FROM sakila.rental
    GROUP BY rental_month
)
SELECT rental_month, rental_count
FROM monthly_counts
ORDER BY rental_count DESC
OFFSET 1 LIMIT 1;