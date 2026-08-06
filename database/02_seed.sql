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

INSERT INTO ecommerce.products (product_name, category_id, unit_price)
SELECT
    (ARRAY['Wireless','Portable','Smart','Classic','Premium','Compact','Deluxe','Eco','Pro','Ultra'])[floor(random()*10)+1]
    || ' ' ||
    (ARRAY['Headphones','Blender','Backpack','Lamp','Notebook','Watch','Speaker','Sneakers','Mug','Keyboard'])[floor(random()*10)+1],
    (SELECT category_id FROM ecommerce.categories ORDER BY random() LIMIT 1),
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

INSERT INTO ecommerce.orders (customer_id, order_date, status)
SELECT
    (SELECT customer_id FROM ecommerce.customers ORDER BY random() LIMIT 1),
    (DATE '2022-01-01' + (random() * 365 * 2)::int),
    (ARRAY['completed','completed','completed','shipped','cancelled'])[floor(random()*5)+1]
FROM generate_series(1, 200);

-- 1-4 line items per order, random product each.
INSERT INTO ecommerce.order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, (1 + floor(random() * 4))::int, p.unit_price
FROM ecommerce.orders o
CROSS JOIN LATERAL (
    SELECT product_id, unit_price
    FROM ecommerce.products
    ORDER BY random()
    LIMIT (1 + floor(random() * 4))::int
) p;
