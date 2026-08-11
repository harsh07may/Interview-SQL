-- =========================================================
-- database/02_seed.sql
--
-- Runs automatically on first container init, after 01_schema.sql.
-- Seeds all three schemas with randomly generated but realistic data
-- (a couple hundred rows per dataset's main entity table). Row counts
-- vary run to run since generation uses random() — that's expected.
-- =========================================================

-- ---------------------------------------------------------
-- employees schema seed (~200 employees)
-- ---------------------------------------------------------
INSERT INTO employees.departments (dept_no, dept_name) VALUES
('d001', 'Marketing'),
('d002', 'Finance'),
('d003', 'Human Resources'),
('d004', 'Production'),
('d005', 'Development'),
('d006', 'Quality Management'),
('d007', 'Sales'),
('d008', 'Research'),
('d009', 'Customer Support'),
('d010', 'Engineering');

INSERT INTO employees.employees (first_name, last_name, gender, birth_date, hire_date)
SELECT
    (ARRAY['James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','William','Elizabeth',
           'David','Barbara','Richard','Susan','Joseph','Jessica','Thomas','Sarah','Charles','Karen',
           'Priya','Wei','Fatima','Carlos','Yuki','Ahmed','Olga','Diego','Mei','Sven'])[floor(random()*30)+1],
    (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
           'Chen','Kim','Patel','Nguyen','Singh','Kowalski','Muller','Rossi','Andersen','Silva'])[floor(random()*20)+1],
    (ARRAY['M','F'])[floor(random()*2)+1],
    (DATE '1965-01-01' + (random() * (365 * 30))::int),
    (DATE '2005-01-01' + (random() * (365 * 19))::int)
FROM generate_series(1, 200);

-- ARRAY(...)-index a materialized department list so the random() call is a
-- plain top-level expression (re-evaluated per output row) rather than living
-- inside an uncorrelated subquery, which Postgres hoists and evaluates once
-- for the whole statement — verified against a live postgres:17 instance.
INSERT INTO employees.dept_emp (emp_no, dept_no, from_date, to_date)
SELECT e.emp_no,
       (ARRAY(SELECT dept_no FROM employees.departments))[1 + floor(random() * (SELECT count(*) FROM employees.departments))::int],
       e.hire_date,
       DATE '9999-01-01'
FROM employees.employees e;

INSERT INTO employees.dept_manager (emp_no, dept_no, from_date, to_date)
SELECT DISTINCT ON (d.dept_no) e.emp_no, d.dept_no, e.hire_date, DATE '9999-01-01'
FROM employees.departments d
JOIN employees.dept_emp de ON de.dept_no = d.dept_no
JOIN employees.employees e ON e.emp_no = de.emp_no
ORDER BY d.dept_no, random();

INSERT INTO employees.titles (emp_no, title, from_date, to_date)
SELECT emp_no,
       (ARRAY['Engineer','Senior Engineer','Staff Engineer','Manager','Senior Staff',
              'Assistant Engineer','Technique Leader'])[floor(random()*7)+1],
       hire_date,
       DATE '9999-01-01'
FROM employees.employees;

-- 1-4 salary records per employee, chained so each record's to_date is the
-- next record's from_date, and the latest record's to_date is open-ended (9999-01-01).
INSERT INTO employees.salaries (emp_no, salary, from_date, to_date)
SELECT emp_no, salary, from_date,
       COALESCE(
           LEAD(from_date) OVER (PARTITION BY emp_no ORDER BY from_date),
           DATE '9999-01-01'
       ) AS to_date
FROM (
    SELECT e.emp_no,
           (40000 + floor(random() * 60000) + (n - 1) * 3000)::int AS salary,
           (e.hire_date + ((n - 1) * INTERVAL '2 years'))::date AS from_date
    FROM employees.employees e
    -- "+ e.emp_no * 0" is a no-op arithmetically, but it makes this bound
    -- reference the outer row, forcing Postgres to re-evaluate random() per
    -- employee instead of computing one row count for the whole statement
    -- (which would otherwise give every employee the same number of salary
    -- records) — verified against a live postgres:17 instance.
    CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 4 + e.emp_no * 0)::int) AS n
) sub;

-- Org chart: every non-manager reports to their department's current manager.
UPDATE employees.employees e
SET manager_emp_no = dm.emp_no
FROM employees.dept_emp de
JOIN employees.dept_manager dm ON dm.dept_no = de.dept_no AND dm.to_date = DATE '9999-01-01'
WHERE de.emp_no = e.emp_no
  AND de.to_date = DATE '9999-01-01'
  AND e.emp_no <> dm.emp_no;

-- Pick one department manager to act as the CEO (reports to no one);
-- every other department manager reports to the CEO.
UPDATE employees.employees
SET manager_emp_no = (SELECT emp_no FROM employees.dept_manager ORDER BY emp_no LIMIT 1)
WHERE emp_no IN (SELECT emp_no FROM employees.dept_manager)
  AND emp_no <> (SELECT emp_no FROM employees.dept_manager ORDER BY emp_no LIMIT 1);

-- ---------------------------------------------------------
-- ecommerce schema seed (~200 orders)
-- ---------------------------------------------------------
INSERT INTO ecommerce.categories (category_name) VALUES
('Electronics'), ('Books'), ('Home & Kitchen'), ('Sports & Outdoors'),
('Toys & Games'), ('Clothing'), ('Beauty'), ('Grocery');

-- category_id uses ARRAY(...)-index rather than "(SELECT ... ORDER BY random()
-- LIMIT 1)": that scalar-subquery form is an uncorrelated subquery Postgres
-- hoists and evaluates ONCE for the whole statement, giving every product the
-- SAME category — verified against a live postgres:17 instance. Indexing into
-- a materialized array keeps random() as a plain top-level expression, which
-- re-evaluates correctly per output row.
INSERT INTO ecommerce.products (product_name, category_id, unit_price)
SELECT
    (ARRAY['Wireless','Portable','Smart','Classic','Premium','Compact','Deluxe','Eco','Pro','Ultra'])[floor(random()*10)+1]
    || ' ' ||
    (ARRAY['Headphones','Blender','Backpack','Lamp','Notebook','Watch','Speaker','Sneakers','Mug','Keyboard'])[floor(random()*10)+1],
    (ARRAY(SELECT category_id FROM ecommerce.categories))[1 + floor(random() * (SELECT count(*) FROM ecommerce.categories))::int],
    round((5 + random() * 195)::numeric, 2)
FROM generate_series(1, 40);

INSERT INTO ecommerce.customers (first_name, last_name, email, signup_date)
SELECT fn, ln,
       lower(fn || '.' || ln || n || '@example.com'),
       (DATE '2019-01-01' + (random() * 365 * 5)::int)
FROM (
    SELECT
        (ARRAY['Alex','Jordan','Sam','Taylor','Morgan','Casey','Riley','Jamie','Drew','Cameron',
               'Priya','Wei','Fatima','Carlos','Yuki','Ahmed','Olga','Diego','Mei','Sven',
               'Emma','Liam','Noah','Ava','Sophia','Mason','Isabella','Ethan','Mia','Lucas'])[floor(random()*30)+1] AS fn,
        (ARRAY['Reed','Brooks','Hayes','Cole','Bishop','Fox','Grant','Wells','Pierce','Sharp',
               'Chen','Kim','Patel','Nguyen','Singh','Kowalski','Muller','Rossi','Andersen','Silva'])[floor(random()*20)+1] AS ln,
        n
    FROM generate_series(1, 50) AS n
) sub;

-- customer_id: same ARRAY(...)-index technique as products.category_id above.
INSERT INTO ecommerce.orders (customer_id, order_date, status)
SELECT
    (ARRAY(SELECT customer_id FROM ecommerce.customers))[1 + floor(random() * (SELECT count(*) FROM ecommerce.customers))::int],
    (DATE '2022-01-01' + (random() * 365 * 2)::int),
    (ARRAY['completed','completed','completed','shipped','cancelled'])[floor(random()*5)+1]
FROM generate_series(1, 200);

-- 1-4 line items per order, random product each. "+ o.order_id * 0" is a
-- no-op arithmetically, but it makes the ORDER BY reference the outer row,
-- forcing Postgres to treat this LATERAL subquery (including its LIMIT) as
-- correlated and re-evaluate it per order. Without it, the subquery has no
-- reference to `o` at all, so Postgres evaluates it once for the whole
-- statement and every order gets an identical, fixed set of line items —
-- verified against a live postgres:17 instance.
INSERT INTO ecommerce.order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, (1 + floor(random() * 4))::int, p.unit_price
FROM ecommerce.orders o
CROSS JOIN LATERAL (
    SELECT product_id, unit_price
    FROM ecommerce.products
    ORDER BY random() + o.order_id * 0
    LIMIT (1 + floor(random() * 4))::int
) p;

-- ---------------------------------------------------------
-- sakila schema seed (~200 films, ~200 rentals)
-- ---------------------------------------------------------
INSERT INTO sakila.actor (first_name, last_name)
SELECT
    (ARRAY['Penelope','Nick','Ed','Jennifer','Johnny','Bette','Grace','Matthew','Joe','Christian',
           'Zero','Karl','Uma','Vivien','Cuba','Fred','Helen','Dan','Boris','Jon',
           'Jeff','Jayne','Rip','Julianne','Milla','Angela','Chris','Sandra','Mary','Wesley'])[floor(random()*30)+1],
    (ARRAY['Guiness','Wahlberg','Chase','Davis','Lollobrigida','Nicholson','Mostel','Johansson','Swank','Gable',
           'Cage','Berry','Depp','Torn','Akroyd','Costner','Voight','Harris','Willis','Kilmer'])[floor(random()*20)+1]
FROM generate_series(1, 50);

INSERT INTO sakila.category (name) VALUES
('Action'), ('Comedy'), ('Drama'), ('Documentary'), ('Horror'),
('Sci-Fi'), ('Family'), ('Animation'), ('Thriller'), ('Romance');

INSERT INTO sakila.film (title, release_year, rental_rate, rating, length)
SELECT
    (ARRAY['Academy','Ace','Adaptation','Affair','Africa','Agent','Alabama','Alamo','Alaska','Alien'])[floor(random()*10)+1]
    || ' ' ||
    (ARRAY['Dinosaur','Ghost','Rider','Story','Legend','Frontier','Chronicles','Voyage','Secret','Empire'])[floor(random()*10)+1],
    2000 + floor(random() * 24)::int,
    (ARRAY[0.99, 1.99, 2.99, 3.99, 4.99])[floor(random()*5)+1],
    (ARRAY['G','PG','PG-13','R','NC-17'])[floor(random()*5)+1],
    60 + floor(random() * 120)::int
FROM generate_series(1, 200);

-- 3 actors per film.
-- The "+ f.film_id * 0" is a no-op arithmetically, but it makes this ORDER BY
-- reference the outer row, which forces Postgres to treat the LATERAL subquery
-- as correlated. Without it, Postgres evaluates the subquery once for the
-- whole statement (since nothing in it otherwise depends on f) and every film
-- gets the SAME 3 actors — verified against a live postgres:17 instance.
INSERT INTO sakila.film_actor (film_id, actor_id)
SELECT f.film_id, a.actor_id
FROM sakila.film f
CROSS JOIN LATERAL (
    SELECT actor_id FROM sakila.actor ORDER BY random() + f.film_id * 0 LIMIT 3
) a;

-- 1 category per film. ARRAY(...)-index a materialized category list so the
-- random() call is a plain top-level expression (re-evaluated per output row)
-- rather than living inside an uncorrelated subquery (which Postgres would
-- otherwise hoist and evaluate once for the whole statement).
INSERT INTO sakila.film_category (film_id, category_id)
SELECT film_id,
       (ARRAY(SELECT category_id FROM sakila.category))[1 + floor(random() * (SELECT count(*) FROM sakila.category))::int]
FROM sakila.film;

INSERT INTO sakila.customer (first_name, last_name, email, active)
SELECT fn, ln, lower(fn || '.' || ln || n || '@sakilamail.com'), (random() > 0.1)
FROM (
    SELECT
        (ARRAY['Mary','Patricia','Linda','Barbara','Elizabeth','Jennifer','Maria','Susan','Margaret','Dorothy',
               'James','John','Robert','Michael','William','David','Richard','Joseph','Thomas','Charles',
               'Sofia','Noor','Aisha','Kenji','Hiro','Ines','Pablo','Anna','Ivan','Lars'])[floor(random()*30)+1] AS fn,
        (ARRAY['Hunter','Palmer','Reeves','Blake','Ford','Owens','Powell','Price','Bryant','Russell',
               'Chen','Kim','Patel','Nguyen','Singh','Kowalski','Muller','Rossi','Andersen','Silva'])[floor(random()*20)+1] AS ln,
        n
    FROM generate_series(1, 50) AS n
) sub;

-- Same ARRAY(...)-index technique as film_category above, for the same reason:
-- a plain "(SELECT ... ORDER BY random() LIMIT 1)" scalar subquery here would
-- be hoisted and evaluated once, giving every rental the same film and customer.
INSERT INTO sakila.rental (rental_date, film_id, customer_id, return_date)
SELECT
    ts,
    (ARRAY(SELECT film_id FROM sakila.film))[1 + floor(random() * (SELECT count(*) FROM sakila.film))::int],
    (ARRAY(SELECT customer_id FROM sakila.customer))[1 + floor(random() * (SELECT count(*) FROM sakila.customer))::int],
    ts + (1 + floor(random() * 10)) * INTERVAL '1 day'
FROM (
    SELECT (TIMESTAMP '2023-01-01' + (random() * 365 * 2) * INTERVAL '1 day') AS ts
    FROM generate_series(1, 200)
) sub;

-- One payment per rental, roughly the film's rental rate plus a small variance.
INSERT INTO sakila.payment (customer_id, rental_id, amount, payment_date)
SELECT r.customer_id, r.rental_id,
       f.rental_rate + round((random() * 2)::numeric, 2),
       r.rental_date + INTERVAL '1 hour'
FROM sakila.rental r
JOIN sakila.film f ON f.film_id = r.film_id;
