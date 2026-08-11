-- Boolean columns can be filtered directly; no need for `= TRUE` vs `IS TRUE` here.
SELECT customer_id, first_name, last_name
FROM sakila.customer
WHERE active = TRUE
ORDER BY last_name, first_name;
