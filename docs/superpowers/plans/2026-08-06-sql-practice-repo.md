# SQL Practice Repo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the placeholder `Interview-SQL` repo into a working, self-hosted PostgreSQL practice
environment: three trimmed realistic sample datasets, topic-organized exercises with hidden answer
keys, conceptual notes per topic, a safe manual reset script, and real README documentation.

**Architecture:** A single `postgres:17` container (already defined in `docker-compose.yml`) is
seeded on first boot by two numbered SQL files (`database/01_schema.sql`, `database/02_seed.sql`)
mounted into `/docker-entrypoint-initdb.d`. Each of the three datasets lives in its own Postgres
schema (`employees`, `ecommerce`, `sakila`) to avoid table-name collisions. `scripts/reset.sql`
lives outside the auto-init directory and is only ever run manually. Exercises are plain `.sql`
files with a problem comment header; answer keys live in a parallel `solutions/` subfolder per
topic.

**Tech Stack:** PostgreSQL 17, Docker Compose. No application code — this repo is pure SQL +
Markdown content.

There is no unit-test framework here. "Testing" a task means: bring the container up from a clean
volume, run the relevant SQL against it via `docker compose exec -T postgres psql -U postgres -d
practice`, and confirm the expected schema/row counts/query results.

## Global Constraints

- Engine: **PostgreSQL only** (`postgres:17` per `docker-compose.yml`). No SQL Server / T-SQL syntax.
- Database name: `practice`. User/password: `postgres`/`postgres`. Port: `5432`.
- Three schemas, one per dataset: `employees`, `ecommerce`, `sakila`. No cross-schema table name
  collisions.
- Only `database/01_schema.sql` and `database/02_seed.sql` are mounted into
  `/docker-entrypoint-initdb.d` (via the existing `./database:/docker-entrypoint-initdb.d` volume
  in `docker-compose.yml` — do not change that mount). `scripts/reset.sql` must never run
  automatically on container init.
- Seed data: roughly a couple hundred rows for each dataset's main entity table (employees,
  orders, films/rentals) — generated via `generate_series`/`random()`, not hand-enumerated. Exact
  counts vary run to run; that's expected.
- Exercises: 2-3 per topic folder, easy → hard. Each exercise file is the problem only; the
  matching model solution lives in that topic's `solutions/` subfolder under the same filename.
- No copyrighted LeetCode/HackerRank/StrataScratch problem text — `interview_questions/` problems
  are original, inspired by common patterns, using this repo's own datasets.
- Every verification command in this plan assumes the working directory is the repo root
  (`d:\Interview Prep\TSQL\Interview-SQL`) and that `docker compose up -d` has been run.

---

### Task 1: Repo scaffolding & Docker init-order fix

**Files:**
- Delete: `database/schema.sql`, `database/seed.sql`, `database/reset.sql`
- Create: `database/01_schema.sql` (header comment only, for now)
- Create: `database/02_seed.sql` (header comment only, for now)
- Create: `exercises/basics/solutions/`, `exercises/joins/solutions/`,
  `exercises/aggregation/solutions/`, `exercises/window_functions/solutions/`,
  `exercises/cte/solutions/`, `exercises/recursive_cte/solutions/`,
  `exercises/subqueries/solutions/`, `exercises/interview_questions/solutions/` (empty dirs,
  populated in later tasks — add a `.gitkeep` if needed so git tracks them before content exists)
- Create: `notes/` (empty dir, populated in Task 6)
- Modify: `.gitignore`
- Verify: `docker-compose.yml` needs no changes (its `./database:/docker-entrypoint-initdb.d`
  mount already only covers the `database/` dir, which after this task contains just the two
  numbered files)

**Interfaces:**
- Produces: the on-disk layout every later task writes into. `database/01_schema.sql` and
  `database/02_seed.sql` are the two files later tasks append dataset sections to, in that fixed
  order (schema task always before its matching seed task).

- [ ] **Step 1: Remove the old placeholder database files**

```bash
git rm database/schema.sql database/seed.sql database/reset.sql
```

- [ ] **Step 2: Create the new numbered init files with header comments**

`database/01_schema.sql`:
```sql
-- =========================================================
-- database/01_schema.sql
--
-- Runs automatically on first container init (mounted into
-- /docker-entrypoint-initdb.d by docker-compose.yml). Creates three
-- independent schemas, each a trimmed, realistic sample dataset:
--   employees  — HR sample (departments, employees, org chart, salaries)
--   ecommerce  — storefront sample (customers, products, orders)
--   sakila     — DVD-rental sample (actors, films, rentals, payments)
-- =========================================================
```

`database/02_seed.sql`:
```sql
-- =========================================================
-- database/02_seed.sql
--
-- Runs automatically on first container init, after 01_schema.sql.
-- Seeds all three schemas with randomly generated but realistic data
-- (a couple hundred rows per dataset's main entity table). Row counts
-- vary run to run since generation uses random() — that's expected.
-- =========================================================
```

- [ ] **Step 3: Create the exercises/notes directory skeleton**

```bash
mkdir -p exercises/basics/solutions exercises/joins/solutions \
         exercises/aggregation/solutions exercises/window_functions/solutions \
         exercises/cte/solutions exercises/recursive_cte/solutions \
         exercises/subqueries/solutions exercises/interview_questions/solutions \
         notes scripts
```

- [ ] **Step 4: Replace the stale SSDT `.gitignore` with one appropriate for this repo**

`.gitignore`:
```
# Environment / secrets
.env

# OS
.DS_Store
Thumbs.db

# Editor
.vs/
.vscode/

# Logs
*.log
```

- [ ] **Step 5: Verify the container still starts cleanly with the (now near-empty) init files**

```bash
docker compose down -v
docker compose up -d
docker compose exec -T postgres pg_isready -U postgres
```

Expected: `pg_isready` reports `accepting connections`. No errors in `docker compose logs postgres`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Scaffold repo layout and fix docker-entrypoint-initdb.d ordering"
```

---

### Task 2: Employees dataset (schema + seed)

**Files:**
- Modify: `database/01_schema.sql` (append employees section)
- Modify: `database/02_seed.sql` (append employees section)

**Interfaces:**
- Consumes: nothing from prior tasks beyond the file skeletons from Task 1.
- Produces: schema `employees` with tables `departments(dept_no, dept_name)`,
  `employees(emp_no, first_name, last_name, gender, birth_date, hire_date, manager_emp_no)`,
  `dept_emp(emp_no, dept_no, from_date, to_date)`,
  `dept_manager(emp_no, dept_no, from_date, to_date)`,
  `titles(emp_no, title, from_date, to_date)`,
  `salaries(emp_no, salary, from_date, to_date)`.
  `employees.manager_emp_no` is a nullable self-FK to `employees.emp_no` — exactly one row (the
  "CEO") has `manager_emp_no IS NULL`; department managers report to the CEO; everyone else
  reports to their department's manager. This column is what later exercises (self-join,
  recursive CTE) rely on.

- [ ] **Step 1: Append the employees schema to `database/01_schema.sql`**

```sql

-- ---------------------------------------------------------
-- employees schema — trimmed port of the classic "employees" sample DB
-- ---------------------------------------------------------
CREATE SCHEMA employees;

CREATE TABLE employees.departments (
    dept_no   CHAR(4) PRIMARY KEY,
    dept_name TEXT NOT NULL UNIQUE
);

CREATE TABLE employees.employees (
    emp_no         SERIAL PRIMARY KEY,
    first_name     TEXT NOT NULL,
    last_name      TEXT NOT NULL,
    gender         CHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
    birth_date     DATE NOT NULL,
    hire_date      DATE NOT NULL,
    manager_emp_no INT REFERENCES employees.employees (emp_no)
);
CREATE INDEX idx_employees_manager_emp_no ON employees.employees (manager_emp_no);

CREATE TABLE employees.dept_emp (
    emp_no    INT NOT NULL REFERENCES employees.employees (emp_no),
    dept_no   CHAR(4) NOT NULL REFERENCES employees.departments (dept_no),
    from_date DATE NOT NULL,
    to_date   DATE NOT NULL,
    PRIMARY KEY (emp_no, dept_no)
);
CREATE INDEX idx_dept_emp_dept_no ON employees.dept_emp (dept_no);

CREATE TABLE employees.dept_manager (
    emp_no    INT NOT NULL REFERENCES employees.employees (emp_no),
    dept_no   CHAR(4) NOT NULL REFERENCES employees.departments (dept_no),
    from_date DATE NOT NULL,
    to_date   DATE NOT NULL,
    PRIMARY KEY (emp_no, dept_no)
);

CREATE TABLE employees.titles (
    emp_no    INT NOT NULL REFERENCES employees.employees (emp_no),
    title     TEXT NOT NULL,
    from_date DATE NOT NULL,
    to_date   DATE NOT NULL,
    PRIMARY KEY (emp_no, title, from_date)
);
CREATE INDEX idx_titles_emp_no ON employees.titles (emp_no);

CREATE TABLE employees.salaries (
    emp_no    INT NOT NULL REFERENCES employees.employees (emp_no),
    salary    INT NOT NULL,
    from_date DATE NOT NULL,
    to_date   DATE NOT NULL,
    PRIMARY KEY (emp_no, from_date)
);
CREATE INDEX idx_salaries_emp_no ON employees.salaries (emp_no);
```

- [ ] **Step 2: Append the employees seed to `database/02_seed.sql`**

```sql

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

INSERT INTO employees.dept_emp (emp_no, dept_no, from_date, to_date)
SELECT e.emp_no,
       (SELECT dept_no FROM employees.departments ORDER BY random() LIMIT 1),
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
    CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 4)::int) AS n
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
```

- [ ] **Step 3: Rebuild the container from a clean volume and verify**

```bash
docker compose down -v
docker compose up -d
docker compose exec -T postgres pg_isready -U postgres
docker compose exec -T postgres psql -U postgres -d practice -c "\dt employees.*"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM employees.employees;"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM employees.employees WHERE manager_emp_no IS NULL;"
```

Expected: `\dt employees.*` lists all 6 tables. Employee count is 200. Exactly one row has
`manager_emp_no IS NULL` (the CEO).

- [ ] **Step 4: Commit**

```bash
git add database/01_schema.sql database/02_seed.sql
git commit -m "Add employees dataset schema and seed"
```

---

### Task 3: Ecommerce dataset (schema + seed)

**Files:**
- Modify: `database/01_schema.sql` (append ecommerce section)
- Modify: `database/02_seed.sql` (append ecommerce section)

**Interfaces:**
- Consumes: nothing from Task 2 (independent schema).
- Produces: schema `ecommerce` with tables `categories(category_id, category_name)`,
  `products(product_id, product_name, category_id, unit_price)`,
  `customers(customer_id, first_name, last_name, email, signup_date)`,
  `orders(order_id, customer_id, order_date, status)`,
  `order_items(order_item_id, order_id, product_id, quantity, unit_price)`.

- [ ] **Step 1: Append the ecommerce schema to `database/01_schema.sql`**

```sql

-- ---------------------------------------------------------
-- ecommerce schema — Northwind-style storefront sample
-- ---------------------------------------------------------
CREATE SCHEMA ecommerce;

CREATE TABLE ecommerce.categories (
    category_id   SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE ecommerce.products (
    product_id   SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INT NOT NULL REFERENCES ecommerce.categories (category_id),
    unit_price   NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0)
);
CREATE INDEX idx_products_category_id ON ecommerce.products (category_id);

CREATE TABLE ecommerce.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    signup_date DATE NOT NULL
);

CREATE TABLE ecommerce.orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES ecommerce.customers (customer_id),
    order_date  DATE NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('completed', 'shipped', 'cancelled'))
);
CREATE INDEX idx_orders_customer_id ON ecommerce.orders (customer_id);

CREATE TABLE ecommerce.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES ecommerce.orders (order_id),
    product_id    INT NOT NULL REFERENCES ecommerce.products (product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0)
);
CREATE INDEX idx_order_items_order_id ON ecommerce.order_items (order_id);
CREATE INDEX idx_order_items_product_id ON ecommerce.order_items (product_id);
```

- [ ] **Step 2: Append the ecommerce seed to `database/02_seed.sql`**

```sql

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
```

- [ ] **Step 3: Rebuild the container from a clean volume and verify**

```bash
docker compose down -v
docker compose up -d
docker compose exec -T postgres pg_isready -U postgres
docker compose exec -T postgres psql -U postgres -d practice -c "\dt ecommerce.*"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM ecommerce.orders;"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM ecommerce.order_items;"
```

Expected: `\dt ecommerce.*` lists all 5 tables. `orders` count is 200. `order_items` count is
greater than 200 (1-4 items per order).

- [ ] **Step 4: Commit**

```bash
git add database/01_schema.sql database/02_seed.sql
git commit -m "Add ecommerce dataset schema and seed"
```

---

### Task 4: Sakila dataset (schema + seed)

**Files:**
- Modify: `database/01_schema.sql` (append sakila section)
- Modify: `database/02_seed.sql` (append sakila section)

**Interfaces:**
- Consumes: nothing from Tasks 2-3 (independent schema).
- Produces: schema `sakila` with tables `actor(actor_id, first_name, last_name)`,
  `category(category_id, name)`,
  `film(film_id, title, release_year, rental_rate, rating, length)`,
  `film_actor(film_id, actor_id)`, `film_category(film_id, category_id)`,
  `customer(customer_id, first_name, last_name, email, active)`,
  `rental(rental_id, rental_date, film_id, customer_id, return_date)`,
  `payment(payment_id, customer_id, rental_id, amount, payment_date)`.

- [ ] **Step 1: Append the sakila schema to `database/01_schema.sql`**

```sql

-- ---------------------------------------------------------
-- sakila schema — trimmed port of the DVD-rental sample DB
-- ---------------------------------------------------------
CREATE SCHEMA sakila;

CREATE TABLE sakila.actor (
    actor_id   SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name  TEXT NOT NULL
);

CREATE TABLE sakila.category (
    category_id SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE
);

CREATE TABLE sakila.film (
    film_id      SERIAL PRIMARY KEY,
    title        TEXT NOT NULL,
    release_year INT NOT NULL,
    rental_rate  NUMERIC(4, 2) NOT NULL,
    rating       TEXT NOT NULL CHECK (rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17')),
    length       INT NOT NULL
);

CREATE TABLE sakila.film_actor (
    film_id  INT NOT NULL REFERENCES sakila.film (film_id),
    actor_id INT NOT NULL REFERENCES sakila.actor (actor_id),
    PRIMARY KEY (film_id, actor_id)
);
CREATE INDEX idx_film_actor_actor_id ON sakila.film_actor (actor_id);

CREATE TABLE sakila.film_category (
    film_id     INT NOT NULL REFERENCES sakila.film (film_id),
    category_id INT NOT NULL REFERENCES sakila.category (category_id),
    PRIMARY KEY (film_id, category_id)
);

CREATE TABLE sakila.customer (
    customer_id SERIAL PRIMARY KEY,
    first_name  TEXT NOT NULL,
    last_name   TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    active      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE sakila.rental (
    rental_id   SERIAL PRIMARY KEY,
    rental_date TIMESTAMP NOT NULL,
    film_id     INT NOT NULL REFERENCES sakila.film (film_id),
    customer_id INT NOT NULL REFERENCES sakila.customer (customer_id),
    return_date TIMESTAMP
);
CREATE INDEX idx_rental_film_id ON sakila.rental (film_id);
CREATE INDEX idx_rental_customer_id ON sakila.rental (customer_id);

CREATE TABLE sakila.payment (
    payment_id   SERIAL PRIMARY KEY,
    customer_id  INT NOT NULL REFERENCES sakila.customer (customer_id),
    rental_id    INT NOT NULL REFERENCES sakila.rental (rental_id),
    amount       NUMERIC(5, 2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP NOT NULL
);
CREATE INDEX idx_payment_customer_id ON sakila.payment (customer_id);
```

- [ ] **Step 2: Append the sakila seed to `database/02_seed.sql`**

```sql

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
INSERT INTO sakila.film_actor (film_id, actor_id)
SELECT f.film_id, a.actor_id
FROM sakila.film f
CROSS JOIN LATERAL (
    SELECT actor_id FROM sakila.actor ORDER BY random() LIMIT 3
) a;

-- 1 category per film.
INSERT INTO sakila.film_category (film_id, category_id)
SELECT film_id, (SELECT category_id FROM sakila.category ORDER BY random() LIMIT 1)
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

INSERT INTO sakila.rental (rental_date, film_id, customer_id, return_date)
SELECT
    ts,
    (SELECT film_id FROM sakila.film ORDER BY random() LIMIT 1),
    (SELECT customer_id FROM sakila.customer ORDER BY random() LIMIT 1),
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
```

- [ ] **Step 3: Rebuild the container from a clean volume and verify**

```bash
docker compose down -v
docker compose up -d
docker compose exec -T postgres pg_isready -U postgres
docker compose exec -T postgres psql -U postgres -d practice -c "\dt sakila.*"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM sakila.film;"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM sakila.rental;"
```

Expected: `\dt sakila.*` lists all 8 tables. `film` count is 200. `rental` count is 200.

- [ ] **Step 4: Commit**

```bash
git add database/01_schema.sql database/02_seed.sql
git commit -m "Add sakila dataset schema and seed"
```

---

### Task 5: Manual reset script + full-cycle verification

**Files:**
- Create: `scripts/reset.sql`

**Interfaces:**
- Consumes: all three schemas from Tasks 2-4 (must exist to meaningfully test a reset).
- Produces: a manual, idempotent reset command documented for use in Task 15's README.

- [ ] **Step 1: Write `scripts/reset.sql`**

```sql
-- scripts/reset.sql
--
-- Wipes and reseeds all three practice schemas. Run manually — this file is
-- NEVER executed automatically on container init (only database/01_schema.sql
-- and database/02_seed.sql are mounted into /docker-entrypoint-initdb.d).
--
-- Usage (from repo root, container already running via `docker compose up -d`):
--   docker compose exec -T postgres psql -U postgres -d practice < scripts/reset.sql
--
-- The \i paths below are container paths: docker-compose.yml bind-mounts
-- ./database into /docker-entrypoint-initdb.d for the life of the container,
-- so these files stay readable there even outside of first-boot init.

DROP SCHEMA IF EXISTS employees CASCADE;
DROP SCHEMA IF EXISTS ecommerce CASCADE;
DROP SCHEMA IF EXISTS sakila CASCADE;

\i /docker-entrypoint-initdb.d/01_schema.sql
\i /docker-entrypoint-initdb.d/02_seed.sql
```

- [ ] **Step 2: Verify the reset script works end-to-end against the already-running, already-seeded container**

```bash
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM employees.employees;"
docker compose exec -T postgres psql -U postgres -d practice < scripts/reset.sql
docker compose exec -T postgres psql -U postgres -d practice -c "\dt employees.*"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM employees.employees;"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM ecommerce.orders;"
docker compose exec -T postgres psql -U postgres -d practice -c "SELECT COUNT(*) FROM sakila.film;"
```

Expected: no errors from the reset script. All three schemas' tables exist and are repopulated
(counts around 200 again, though exact values will differ from the pre-reset run since generation
is random).

- [ ] **Step 3: Commit**

```bash
git add scripts/reset.sql
git commit -m "Add manual database reset script"
```

---

### Task 6: Notes (one primer per exercise topic, plus indexes)

**Files:**
- Create: `notes/basics.md`, `notes/joins.md`, `notes/aggregation.md`,
  `notes/window_functions.md`, `notes/cte.md`, `notes/recursive_cte.md`,
  `notes/subqueries.md`, `notes/indexes.md`

**Interfaces:**
- Consumes: table/column names from Tasks 2-4 (referenced in examples).
- Produces: nothing later tasks depend on programmatically — these are read by the learner before
  attempting the matching `exercises/<topic>/`.

- [ ] **Step 1: Write `notes/basics.md`**

```markdown
# Basics: SELECT, WHERE, ORDER BY, LIMIT

## What
The foundation of every query: choosing columns (`SELECT`), filtering rows (`WHERE`), ordering
results (`ORDER BY`), and capping how many rows come back (`LIMIT`/`OFFSET`).

## When
Every query starts here. Get comfortable filtering and sorting before moving on to joins or
aggregation — most interview questions build directly on these fundamentals.

## Gotchas
- `WHERE` filters rows *before* grouping; it cannot reference aggregate results (use `HAVING` for that).
- String comparisons are case-sensitive by default in Postgres (`'Alice' <> 'alice'`). Use `ILIKE`
  or `LOWER()` for case-insensitive matching.
- `NULL` never equals anything, including another `NULL` — use `IS NULL` / `IS NOT NULL`, not `= NULL`.
- `LIMIT` without `ORDER BY` returns an arbitrary subset — always pair them if you care which rows you get.
- `OFFSET n LIMIT 1` is a common trick for "the Nth row" once sorted — see the `interview_questions` topic.

## Cheatsheet
```sql
SELECT col1, col2
FROM schema.table
WHERE condition
ORDER BY col1 [ASC|DESC]
LIMIT n [OFFSET m];
```
```

- [ ] **Step 2: Write `notes/joins.md`**

```markdown
# Joins

## What
Combining rows from two or more tables based on a related column. The core join types:
`INNER JOIN` (only matching rows), `LEFT JOIN` (all left rows, matched or not), and self-joins
(a table joined to itself, e.g. an employee to their own manager).

## When
Any time the data you need is split across tables — which is almost always in a normalized
schema like `employees` or `ecommerce`.

## Gotchas
- `INNER JOIN` silently drops rows with no match on either side — use `LEFT JOIN` when you need
  to keep unmatched rows (e.g. "customers with no orders", see `interview_questions`).
- After a `LEFT JOIN`, columns from the right-hand table are `NULL` for unmatched rows — filter on
  `right_table.some_column IS NULL` to find "no match" rows (an anti-join).
- A self-join needs two aliases for the same table (e.g. `employees.employees e JOIN employees.employees m`)
  — `employees.manager_emp_no` pointing back to `employees.emp_no` is the classic case.
- Joining without a condition (or with the wrong column) produces a cartesian product — always
  double check your `ON` clause.

## Cheatsheet
```sql
SELECT ...
FROM schema.a
JOIN schema.b ON b.a_id = a.id            -- inner join
LEFT JOIN schema.c ON c.a_id = a.id;       -- keeps unmatched a rows, c.* is NULL

-- self-join
SELECT e.first_name, m.first_name AS manager
FROM employees.employees e
LEFT JOIN employees.employees m ON m.emp_no = e.manager_emp_no;
```
```

- [ ] **Step 3: Write `notes/aggregation.md`**

```markdown
# Aggregation: GROUP BY, HAVING

## What
Collapsing many rows into summary rows with aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`)
per group, using `GROUP BY`. `HAVING` filters those grouped results.

## When
Whenever the question is a "per X" question — revenue per category, average salary per department,
rental count per film.

## Gotchas
- Every non-aggregated column in `SELECT` must appear in `GROUP BY` (Postgres enforces this strictly).
- `WHERE` filters rows before grouping; `HAVING` filters groups after aggregation — you cannot put
  an aggregate like `COUNT(*) > 5` in `WHERE`.
- `COUNT(*)` counts rows including `NULL`s; `COUNT(column)` skips `NULL`s in that column — they can
  give different answers on the same table.
- Aggregate functions ignore `NULL` values (e.g. `AVG` divides by the count of non-null rows, not
  total rows).

## Cheatsheet
```sql
SELECT group_col, AGG_FUNC(value_col) AS alias
FROM schema.table
WHERE row_filter
GROUP BY group_col
HAVING AGG_FUNC(value_col) > threshold
ORDER BY alias DESC;
```
```

- [ ] **Step 4: Write `notes/window_functions.md`**

```markdown
# Window Functions

## What
Like aggregation, but *without* collapsing rows — each row keeps its identity while also seeing a
calculation "over a window" of related rows (`OVER (PARTITION BY ... ORDER BY ...)`). Common ones:
`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`/`LEAD()`, and running `SUM()`/`AVG() OVER (...)`.

## When
"Top N per group" (top rented film per category), "compare this row to the previous row" (salary
change over time), or running totals — all classic interview staples that plain `GROUP BY` can't do
in one pass because you'd lose the row-level detail.

## Gotchas
- `RANK()` leaves gaps after ties (1, 1, 3); `DENSE_RANK()` doesn't (1, 1, 2); `ROW_NUMBER()` never
  ties (always 1, 2, 3, arbitrarily breaking ties by the given order).
- Window functions run *after* `WHERE`/`GROUP BY` but *before* `ORDER BY`/`LIMIT` in logical query
  order — you can't filter on a window function's result in the same `SELECT`'s `WHERE`; wrap it in
  a CTE or subquery and filter in the outer query instead.
- Forgetting `PARTITION BY` computes the window over the *entire* result set, not per group — a
  common bug when you meant "rank within each department" but got "rank across everyone."
- `LAG`/`LEAD` need an explicit `ORDER BY` inside `OVER (...)` to mean "previous/next" in a
  meaningful order (usually by date).

## Cheatsheet
```sql
SELECT col,
       ROW_NUMBER() OVER (PARTITION BY group_col ORDER BY sort_col DESC) AS rn,
       SUM(value_col) OVER (PARTITION BY group_col ORDER BY sort_col) AS running_total,
       LAG(value_col) OVER (PARTITION BY group_col ORDER BY sort_col) AS prev_value
FROM schema.table;
```
```

- [ ] **Step 5: Write `notes/cte.md`**

```markdown
# CTEs (Common Table Expressions)

## What
A `WITH name AS (...)` block that names a subquery so the main query can reference it like a table.
Purely a readability/organization tool — Postgres does not guarantee a CTE materializes separately
from the main query (it may inline it during planning).

## When
When a query needs a multi-step calculation — e.g. "first compute each order's total, then filter
to orders above $150" — a CTE lets you write and read that as two clear steps instead of nesting
subqueries.

## Gotchas
- A CTE is scoped to the single statement it's attached to — you can't reference it from a later,
  separate query.
- You can chain multiple CTEs (`WITH a AS (...), b AS (...)`), and later CTEs can reference earlier
  ones in the same `WITH` block.
- A CTE is not automatically faster than an equivalent subquery — treat it as a naming/readability
  choice, not a performance one, unless you specifically need `RECURSIVE` (see `recursive_cte`).

## Cheatsheet
```sql
WITH step_one AS (
    SELECT ... FROM schema.table GROUP BY ...
)
SELECT *
FROM step_one
WHERE some_condition;
```
```

- [ ] **Step 6: Write `notes/recursive_cte.md`**

```markdown
# Recursive CTEs

## What
A `WITH RECURSIVE name AS (base_case UNION ALL recursive_case)` construct for traversing
hierarchical or graph-shaped data — org charts, category trees, bill-of-materials — where the
depth isn't known in advance.

## When
Any "chain of relationships" question: "everyone who reports to X, directly or transitively",
"the full org chart with each person's depth", or general parent/child tree traversal.

## Gotchas
- The base case (before `UNION ALL`) defines the starting row(s) — get this wrong and the whole
  traversal starts from the wrong place (or nowhere).
- The recursive case must `JOIN` the CTE's own name to itself to walk one more level — the
  recursion stops naturally once a level produces zero new rows.
- Always use `UNION ALL`, not `UNION`, unless you specifically need deduplication — `UNION` forces
  a distinct check on every recursive step, which is both slower and can silently drop legitimate
  duplicate rows (e.g. two employees with the same manager and title).
- Without a natural termination point (e.g. a cyclical `manager_emp_no` reference), a recursive CTE
  can loop forever — real hierarchies should always have a root row where the parent column is `NULL`.

## Cheatsheet
```sql
WITH RECURSIVE chain AS (
    SELECT id, parent_id, 0 AS depth
    FROM schema.table
    WHERE parent_id IS NULL              -- base case: the root

    UNION ALL

    SELECT t.id, t.parent_id, c.depth + 1
    FROM schema.table t
    JOIN chain c ON t.parent_id = c.id   -- recursive case: one level down
)
SELECT * FROM chain ORDER BY depth;
```
```

- [ ] **Step 7: Write `notes/subqueries.md`**

```markdown
# Subqueries

## What
A query nested inside another query. Three flavors matter most: **scalar** (returns one value, used
like a single expression), **row/IN-list** (returns a set of values), and **correlated** (references
a column from the outer query, so it re-runs conceptually once per outer row).

## When
Scalar subqueries for "compare this row to some single computed value" (e.g. the max salary in this
row's department). Correlated `EXISTS`/`NOT EXISTS` for "does a related row exist" questions —
usually the cleanest way to express "has never..." or "has at least one...".

## Gotchas
- A scalar subquery must return exactly one row/column, or the query errors at runtime — guard with
  aggregates (`MAX`, `AVG`) or a tight `WHERE` on the inner query.
- `NOT IN` with a subquery that can return `NULL` silently returns *zero rows* for the whole outer
  query (NULL poisons the comparison) — prefer `NOT EXISTS` for "doesn't exist" checks, it doesn't
  have this trap.
- A correlated subquery re-evaluates conceptually per outer row, which can be slow on large tables —
  the query planner often rewrites it into a join internally, but it's worth knowing the naive cost.
- `EXISTS` only cares whether the subquery returns *any* row — never `SELECT *` inside it out of
  habit; `SELECT 1` communicates the intent (existence only, not the data).

## Cheatsheet
```sql
-- scalar subquery
SELECT col, (SELECT MAX(x) FROM schema.other WHERE other.id = t.id) AS max_x
FROM schema.table t;

-- correlated EXISTS
SELECT * FROM schema.a
WHERE EXISTS (SELECT 1 FROM schema.b WHERE b.a_id = a.id);

-- correlated NOT EXISTS (safe "doesn't exist" check)
SELECT * FROM schema.a
WHERE NOT EXISTS (SELECT 1 FROM schema.b WHERE b.a_id = a.id);
```
```

- [ ] **Step 8: Write `notes/indexes.md`**

```markdown
# Indexes (DBA bonus note)

## What
A separate on-disk structure (by default a B-tree in Postgres) that lets the database find rows
matching a condition without scanning the whole table — the same idea as an index at the back of a
book.

## When
Add an index on columns you frequently filter (`WHERE`), join on (`ON`), or sort by (`ORDER BY`) on
a table large enough that a full scan is expensive. Every table in this repo's `database/01_schema.sql`
already has indexes on its foreign-key join columns (e.g. `idx_salaries_emp_no`,
`idx_rental_customer_id`) — that's not automatic in Postgres, unlike the primary key itself.

## Gotchas
- A `PRIMARY KEY` automatically gets a unique index; a `FOREIGN KEY` does **not** — you must create
  one yourself if you'll query/join on it often (which is why this repo's schema adds them explicitly).
- An index speeds up reads but slows down writes (`INSERT`/`UPDATE`/`DELETE` must also update the
  index) and takes disk space — don't index every column "just in case."
- An index on `(a, b)` helps queries filtering on `a` alone or `a AND b`, but generally **not** a
  query filtering on `b` alone — column order in a composite index matters.
- Wrapping an indexed column in a function (`WHERE LOWER(email) = ...`) prevents Postgres from using
  a plain index on `email` — you'd need a matching expression index (`CREATE INDEX ... ON t (LOWER(email))`).
- Use `EXPLAIN ANALYZE` before assuming an index will help — the planner may still choose a full
  table scan on a small table like the ones in this repo, because it's genuinely faster than the
  overhead of an index lookup.

## Cheatsheet
```sql
CREATE INDEX idx_table_column ON schema.table (column);
CREATE INDEX idx_table_multi ON schema.table (col_a, col_b);   -- order matters
EXPLAIN ANALYZE SELECT ...;                                     -- check if an index is actually used
```
```

- [ ] **Step 9: Commit**

```bash
git add notes/
git commit -m "Add conceptual primer notes for each exercise topic"
```

---

### Task 7: Exercises — basics

**Files:**
- Create: `exercises/basics/01_top_priced_products.sql`,
  `exercises/basics/solutions/01_top_priced_products.sql`
- Create: `exercises/basics/02_active_sakila_customers.sql`,
  `exercises/basics/solutions/02_active_sakila_customers.sql`
- Create: `exercises/basics/03_employees_hired_after.sql`,
  `exercises/basics/solutions/03_employees_hired_after.sql`

**Interfaces:**
- Consumes: `ecommerce.products(product_name, unit_price)`, `sakila.customer(customer_id,
  first_name, last_name, active)`, `employees.employees(emp_no, first_name, last_name, hire_date)`
  from Tasks 2-4.

- [ ] **Step 1: `exercises/basics/01_top_priced_products.sql`**

```sql
-- Basics 01: List the 5 most expensive products in ecommerce.products,
-- showing product_name and unit_price, most expensive first.

```

- [ ] **Step 2: `exercises/basics/solutions/01_top_priced_products.sql`**

```sql
-- Sort descending by price and cap the result with LIMIT.
SELECT product_name, unit_price
FROM ecommerce.products
ORDER BY unit_price DESC
LIMIT 5;
```

- [ ] **Step 3: `exercises/basics/02_active_sakila_customers.sql`**

```sql
-- Basics 02: List all sakila.customer rows where active = true,
-- showing customer_id, first_name, last_name, ordered by last_name then first_name.

```

- [ ] **Step 4: `exercises/basics/solutions/02_active_sakila_customers.sql`**

```sql
-- Boolean columns can be filtered directly; no need for `= TRUE` vs `IS TRUE` here.
SELECT customer_id, first_name, last_name
FROM sakila.customer
WHERE active = TRUE
ORDER BY last_name, first_name;
```

- [ ] **Step 5: `exercises/basics/03_employees_hired_after.sql`**

```sql
-- Basics 03: Find all employees.employees hired on or after 2015-01-01,
-- showing emp_no, first_name, last_name, hire_date, ordered by hire_date ascending.

```

- [ ] **Step 6: `exercises/basics/solutions/03_employees_hired_after.sql`**

```sql
SELECT emp_no, first_name, last_name, hire_date
FROM employees.employees
WHERE hire_date >= DATE '2015-01-01'
ORDER BY hire_date ASC;
```

- [ ] **Step 7: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/basics/solutions/01_top_priced_products.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/basics/solutions/02_active_sakila_customers.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/basics/solutions/03_employees_hired_after.sql
```

Expected: each command prints a result table with no SQL errors. Query 1 returns 5 rows. Query 3
returns 0 or more rows sorted ascending by `hire_date` (row count depends on the random seed data).

- [ ] **Step 8: Commit**

```bash
git add exercises/basics/
git commit -m "Add basics exercises with solutions"
```

---

### Task 8: Exercises — joins

**Files:**
- Create: `exercises/joins/01_self_join_management_chain.sql`,
  `exercises/joins/solutions/01_self_join_management_chain.sql`
- Create: `exercises/joins/02_scifi_film_cast.sql`,
  `exercises/joins/solutions/02_scifi_film_cast.sql`
- Create: `exercises/joins/03_order_line_items.sql`,
  `exercises/joins/solutions/03_order_line_items.sql`

**Interfaces:**
- Consumes: `employees.employees(emp_no, first_name, last_name, manager_emp_no)`,
  `sakila.film/film_category/category/film_actor/actor`, `ecommerce.orders/customers/order_items/products`
  from Tasks 2-4.

- [ ] **Step 1: `exercises/joins/01_self_join_management_chain.sql`**

```sql
-- Joins 01: For every employee, show their own full name and their direct
-- manager's full name (NULL manager_name for the one employee with no manager
-- — the CEO). Order by employee_name.

```

- [ ] **Step 2: `exercises/joins/solutions/01_self_join_management_chain.sql`**

```sql
-- Classic self-join: alias employees.employees twice, once as "the employee"
-- and once as "their manager", joined via manager_emp_no -> emp_no.
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       m.first_name || ' ' || m.last_name AS manager_name
FROM employees.employees e
LEFT JOIN employees.employees m ON m.emp_no = e.manager_emp_no
ORDER BY employee_name;
```

- [ ] **Step 3: `exercises/joins/02_scifi_film_cast.sql`**

```sql
-- Joins 02: For every film in the 'Sci-Fi' category, list the film title and
-- the full name of each of its actors (one row per actor). Order by title
-- then actor_name.

```

- [ ] **Step 4: `exercises/joins/solutions/02_scifi_film_cast.sql`**

```sql
SELECT f.title, a.first_name || ' ' || a.last_name AS actor_name
FROM sakila.film f
JOIN sakila.film_category fc ON fc.film_id = f.film_id
JOIN sakila.category c ON c.category_id = fc.category_id
JOIN sakila.film_actor fa ON fa.film_id = f.film_id
JOIN sakila.actor a ON a.actor_id = fa.actor_id
WHERE c.name = 'Sci-Fi'
ORDER BY f.title, actor_name;
```

- [ ] **Step 5: `exercises/joins/03_order_line_items.sql`**

```sql
-- Joins 03: For every order, show order_id, the customer's full name,
-- order_date, and for each line item the product_name and quantity
-- (one row per order item). Order by order_id then product_name.

```

- [ ] **Step 6: `exercises/joins/solutions/03_order_line_items.sql`**

```sql
SELECT o.order_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       o.order_date,
       p.product_name,
       oi.quantity
FROM ecommerce.orders o
JOIN ecommerce.customers c ON c.customer_id = o.customer_id
JOIN ecommerce.order_items oi ON oi.order_id = o.order_id
JOIN ecommerce.products p ON p.product_id = oi.product_id
ORDER BY o.order_id, p.product_name;
```

- [ ] **Step 7: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/joins/solutions/01_self_join_management_chain.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/joins/solutions/02_scifi_film_cast.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/joins/solutions/03_order_line_items.sql
```

Expected: query 1 returns 200 rows, all `manager_name` non-null except exactly one row (the CEO).
Queries 2 and 3 return without error (row counts vary with the random seed).

- [ ] **Step 8: Commit**

```bash
git add exercises/joins/
git commit -m "Add joins exercises with solutions"
```

---

### Task 9: Exercises — aggregation

**Files:**
- Create: `exercises/aggregation/01_revenue_per_category.sql`,
  `exercises/aggregation/solutions/01_revenue_per_category.sql`
- Create: `exercises/aggregation/02_avg_salary_per_department.sql`,
  `exercises/aggregation/solutions/02_avg_salary_per_department.sql`
- Create: `exercises/aggregation/03_top_spending_sakila_customers.sql`,
  `exercises/aggregation/solutions/03_top_spending_sakila_customers.sql`

**Interfaces:**
- Consumes: `ecommerce.order_items/products/categories`, `employees.salaries/dept_emp/departments`,
  `sakila.payment/customer` from Tasks 2-4.

- [ ] **Step 1: `exercises/aggregation/01_revenue_per_category.sql`**

```sql
-- Aggregation 01: Total revenue (quantity * unit_price) per product category,
-- highest revenue first.

```

- [ ] **Step 2: `exercises/aggregation/solutions/01_revenue_per_category.sql`**

```sql
SELECT cat.category_name, SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM ecommerce.order_items oi
JOIN ecommerce.products p ON p.product_id = oi.product_id
JOIN ecommerce.categories cat ON cat.category_id = p.category_id
GROUP BY cat.category_name
ORDER BY total_revenue DESC;
```

- [ ] **Step 3: `exercises/aggregation/02_avg_salary_per_department.sql`**

```sql
-- Aggregation 02: Average *current* salary per department (only rows where
-- both the dept_emp assignment and the salary record are still open, i.e.
-- to_date = '9999-01-01'), rounded to the nearest integer, highest first.

```

- [ ] **Step 4: `exercises/aggregation/solutions/02_avg_salary_per_department.sql`**

```sql
SELECT d.dept_name, ROUND(AVG(s.salary)) AS avg_salary
FROM employees.salaries s
JOIN employees.dept_emp de ON de.emp_no = s.emp_no AND de.to_date = DATE '9999-01-01'
JOIN employees.departments d ON d.dept_no = de.dept_no
WHERE s.to_date = DATE '9999-01-01'
GROUP BY d.dept_name
ORDER BY avg_salary DESC;
```

- [ ] **Step 5: `exercises/aggregation/03_top_spending_sakila_customers.sql`**

```sql
-- Aggregation 03: Top 5 sakila customers by total amount paid (sakila.payment),
-- showing the customer's full name and total_spent, highest first.

```

- [ ] **Step 6: `exercises/aggregation/solutions/03_top_spending_sakila_customers.sql`**

```sql
SELECT c.first_name || ' ' || c.last_name AS customer_name, SUM(p.amount) AS total_spent
FROM sakila.payment p
JOIN sakila.customer c ON c.customer_id = p.customer_id
GROUP BY customer_name
ORDER BY total_spent DESC
LIMIT 5;
```

- [ ] **Step 7: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/aggregation/solutions/01_revenue_per_category.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/aggregation/solutions/02_avg_salary_per_department.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/aggregation/solutions/03_top_spending_sakila_customers.sql
```

Expected: query 1 returns up to 8 rows (one per category with at least one order item). Query 2
returns up to 10 rows (one per department). Query 3 returns exactly 5 rows.

- [ ] **Step 8: Commit**

```bash
git add exercises/aggregation/
git commit -m "Add aggregation exercises with solutions"
```

---

### Task 10: Exercises — window_functions

**Files:**
- Create: `exercises/window_functions/01_top_rented_film_per_category.sql`,
  `exercises/window_functions/solutions/01_top_rented_film_per_category.sql`
- Create: `exercises/window_functions/02_salary_growth.sql`,
  `exercises/window_functions/solutions/02_salary_growth.sql`
- Create: `exercises/window_functions/03_running_total_customer_spend.sql`,
  `exercises/window_functions/solutions/03_running_total_customer_spend.sql`

**Interfaces:**
- Consumes: `sakila.rental/film/film_category/category`, `employees.salaries`,
  `ecommerce.orders/order_items` from Tasks 2-4.

- [ ] **Step 1: `exercises/window_functions/01_top_rented_film_per_category.sql`**

```sql
-- Window Functions 01: For each sakila film category, find the single
-- most-rented film (by rental count), showing category_name, title,
-- rental_count. Order by category_name.

```

- [ ] **Step 2: `exercises/window_functions/solutions/01_top_rented_film_per_category.sql`**

```sql
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
```

- [ ] **Step 3: `exercises/window_functions/02_salary_growth.sql`**

```sql
-- Window Functions 02: For each employee, show every salary record
-- alongside the salary they had immediately before it, and the difference
-- between the two. Order by emp_no then from_date.

```

- [ ] **Step 4: `exercises/window_functions/solutions/02_salary_growth.sql`**

```sql
SELECT emp_no, from_date, salary,
       LAG(salary) OVER (PARTITION BY emp_no ORDER BY from_date) AS prev_salary,
       salary - LAG(salary) OVER (PARTITION BY emp_no ORDER BY from_date) AS salary_change
FROM employees.salaries
ORDER BY emp_no, from_date;
```

- [ ] **Step 5: `exercises/window_functions/03_running_total_customer_spend.sql`**

```sql
-- Window Functions 03: For each ecommerce customer, show every order with a
-- running total of that customer's order value (sum of quantity * unit_price
-- across the order's line items), ordered by order_date.

```

- [ ] **Step 6: `exercises/window_functions/solutions/03_running_total_customer_spend.sql`**

```sql
WITH order_totals AS (
    SELECT o.order_id, o.customer_id, o.order_date,
           SUM(oi.quantity * oi.unit_price) AS order_total
    FROM ecommerce.orders o
    JOIN ecommerce.order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
)
SELECT customer_id, order_id, order_date, order_total,
       SUM(order_total) OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS running_total
FROM order_totals
ORDER BY customer_id, order_date, order_id;
```

- [ ] **Step 7: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/window_functions/solutions/01_top_rented_film_per_category.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/window_functions/solutions/02_salary_growth.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/window_functions/solutions/03_running_total_customer_spend.sql
```

Expected: query 1 returns up to 10 rows (one per category that has at least one rented film).
Query 2 returns 200+ rows with `prev_salary`/`salary_change` NULL on each employee's first record.
Query 3's `running_total` is non-decreasing within each `customer_id`.

- [ ] **Step 8: Commit**

```bash
git add exercises/window_functions/
git commit -m "Add window_functions exercises with solutions"
```

---

### Task 11: Exercises — cte

**Files:**
- Create: `exercises/cte/01_high_value_orders.sql`, `exercises/cte/solutions/01_high_value_orders.sql`
- Create: `exercises/cte/02_department_headcount.sql`,
  `exercises/cte/solutions/02_department_headcount.sql`

**Interfaces:**
- Consumes: `ecommerce.orders/order_items`, `employees.dept_emp/departments` from Tasks 2-3.

- [ ] **Step 1: `exercises/cte/01_high_value_orders.sql`**

```sql
-- CTE 01: Using a CTE, first compute each order's total value
-- (quantity * unit_price summed across its line items), then select only
-- orders with a total above $150. Show order_id, customer_id, order_total,
-- highest total first.

```

- [ ] **Step 2: `exercises/cte/solutions/01_high_value_orders.sql`**

```sql
WITH order_totals AS (
    SELECT o.order_id, o.customer_id,
           SUM(oi.quantity * oi.unit_price) AS order_total
    FROM ecommerce.orders o
    JOIN ecommerce.order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id
)
SELECT order_id, customer_id, order_total
FROM order_totals
WHERE order_total > 150
ORDER BY order_total DESC;
```

- [ ] **Step 3: `exercises/cte/02_department_headcount.sql`**

```sql
-- CTE 02: Using a CTE, compute current headcount per department (dept_emp
-- rows still open, to_date = '9999-01-01'), then select only departments
-- with more than 15 current employees. Show dept_name, headcount, highest first.

```

- [ ] **Step 4: `exercises/cte/solutions/02_department_headcount.sql`**

```sql
WITH current_headcount AS (
    SELECT d.dept_name, COUNT(*) AS headcount
    FROM employees.dept_emp de
    JOIN employees.departments d ON d.dept_no = de.dept_no
    WHERE de.to_date = DATE '9999-01-01'
    GROUP BY d.dept_name
)
SELECT dept_name, headcount
FROM current_headcount
WHERE headcount > 15
ORDER BY headcount DESC;
```

- [ ] **Step 5: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/cte/solutions/01_high_value_orders.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/cte/solutions/02_department_headcount.sql
```

Expected: both run without error. Query 2 returns 0 or more rows — with 200 employees spread
across 10 departments (~20 per department on average), some departments should exceed 15, but this
depends on the random department assignment; 0 rows is a valid (if less interesting) outcome, not
a bug.

- [ ] **Step 6: Commit**

```bash
git add exercises/cte/
git commit -m "Add cte exercises with solutions"
```

---

### Task 12: Exercises — recursive_cte

**Files:**
- Create: `exercises/recursive_cte/01_org_chart.sql`,
  `exercises/recursive_cte/solutions/01_org_chart.sql`
- Create: `exercises/recursive_cte/02_all_reports_under_manager.sql`,
  `exercises/recursive_cte/solutions/02_all_reports_under_manager.sql`

**Interfaces:**
- Consumes: `employees.employees(emp_no, first_name, last_name, manager_emp_no)`,
  `employees.dept_manager`, `employees.departments` from Task 2.

- [ ] **Step 1: `exercises/recursive_cte/01_org_chart.sql`**

```sql
-- Recursive CTE 01: Write a recursive CTE that produces the full org chart
-- starting from the CEO (the one employee with manager_emp_no IS NULL).
-- Show emp_no, employee_name, depth (0 for the CEO, 1 for their direct
-- reports, etc). Order by depth then employee_name.

```

- [ ] **Step 2: `exercises/recursive_cte/solutions/01_org_chart.sql`**

```sql
WITH RECURSIVE org_chart AS (
    SELECT emp_no, first_name, last_name, manager_emp_no, 0 AS depth
    FROM employees.employees
    WHERE manager_emp_no IS NULL

    UNION ALL

    SELECT e.emp_no, e.first_name, e.last_name, e.manager_emp_no, oc.depth + 1
    FROM employees.employees e
    JOIN org_chart oc ON e.manager_emp_no = oc.emp_no
)
SELECT emp_no, first_name || ' ' || last_name AS employee_name, depth
FROM org_chart
ORDER BY depth, employee_name;
```

- [ ] **Step 3: `exercises/recursive_cte/02_all_reports_under_manager.sql`**

```sql
-- Recursive CTE 02: List every employee who reports, directly or
-- transitively, to the manager of the 'Development' department. Show
-- emp_no and employee_name, ordered by employee_name.

```

- [ ] **Step 4: `exercises/recursive_cte/solutions/02_all_reports_under_manager.sql`**

```sql
WITH RECURSIVE reports AS (
    SELECT emp_no, first_name, last_name, manager_emp_no
    FROM employees.employees
    WHERE manager_emp_no = (
        SELECT dm.emp_no
        FROM employees.dept_manager dm
        JOIN employees.departments d ON d.dept_no = dm.dept_no
        WHERE d.dept_name = 'Development' AND dm.to_date = DATE '9999-01-01'
    )

    UNION ALL

    SELECT e.emp_no, e.first_name, e.last_name, e.manager_emp_no
    FROM employees.employees e
    JOIN reports r ON e.manager_emp_no = r.emp_no
)
SELECT emp_no, first_name || ' ' || last_name AS employee_name
FROM reports
ORDER BY employee_name;
```

- [ ] **Step 5: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/recursive_cte/solutions/01_org_chart.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/recursive_cte/solutions/02_all_reports_under_manager.sql
```

Expected: query 1 returns 200 rows total (all employees), with exactly one row at `depth = 0`,
9 rows at `depth = 1` (the other department managers), and the rest at `depth = 2`. Query 2 returns
0 or more rows without error (count depends on how many employees were randomly assigned to
Development).

- [ ] **Step 6: Commit**

```bash
git add exercises/recursive_cte/
git commit -m "Add recursive_cte exercises with solutions"
```

---

### Task 13: Exercises — subqueries

**Files:**
- Create: `exercises/subqueries/01_above_average_priced_products.sql`,
  `exercises/subqueries/solutions/01_above_average_priced_products.sql`
- Create: `exercises/subqueries/02_never_rented_films.sql`,
  `exercises/subqueries/solutions/02_never_rented_films.sql`
- Create: `exercises/subqueries/03_top_salary_per_department.sql`,
  `exercises/subqueries/solutions/03_top_salary_per_department.sql`

**Interfaces:**
- Consumes: `ecommerce.products`, `sakila.film/rental`, `employees.departments/dept_emp/salaries`
  from Tasks 2-4.

- [ ] **Step 1: `exercises/subqueries/01_above_average_priced_products.sql`**

```sql
-- Subqueries 01: List products priced above the average price of their own
-- category (a correlated subquery), showing product_name, category_id,
-- unit_price. Order by category_id then unit_price descending.

```

- [ ] **Step 2: `exercises/subqueries/solutions/01_above_average_priced_products.sql`**

```sql
SELECT p.product_name, p.category_id, p.unit_price
FROM ecommerce.products p
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM ecommerce.products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY p.category_id, p.unit_price DESC;
```

- [ ] **Step 3: `exercises/subqueries/02_never_rented_films.sql`**

```sql
-- Subqueries 02: List sakila films that have never been rented, using a
-- NOT EXISTS correlated subquery. Show film_id, title, ordered by title.

```

- [ ] **Step 4: `exercises/subqueries/solutions/02_never_rented_films.sql`**

```sql
SELECT f.film_id, f.title
FROM sakila.film f
WHERE NOT EXISTS (
    SELECT 1 FROM sakila.rental r WHERE r.film_id = f.film_id
)
ORDER BY f.title;
```

- [ ] **Step 5: `exercises/subqueries/03_top_salary_per_department.sql`**

```sql
-- Subqueries 03: For each department, show the department name and the
-- salary of its highest-paid *current* employee, using a scalar subquery.
-- Order by top_salary descending.

```

- [ ] **Step 6: `exercises/subqueries/solutions/03_top_salary_per_department.sql`**

```sql
SELECT d.dept_name,
       (
           SELECT MAX(s.salary)
           FROM employees.salaries s
           JOIN employees.dept_emp de ON de.emp_no = s.emp_no
           WHERE de.dept_no = d.dept_no
             AND de.to_date = DATE '9999-01-01'
             AND s.to_date = DATE '9999-01-01'
       ) AS top_salary
FROM employees.departments d
ORDER BY top_salary DESC;
```

- [ ] **Step 7: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/subqueries/solutions/01_above_average_priced_products.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/subqueries/solutions/02_never_rented_films.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/subqueries/solutions/03_top_salary_per_department.sql
```

Expected: all three run without error. Query 3 returns exactly 10 rows (one per department), some
possibly `NULL` if a department happens to have no current employees in the random seed.

- [ ] **Step 8: Commit**

```bash
git add exercises/subqueries/
git commit -m "Add subqueries exercises with solutions"
```

---

### Task 14: Exercises — interview_questions

**Files:**
- Create: `exercises/interview_questions/01_nth_highest_salary.sql`,
  `exercises/interview_questions/solutions/01_nth_highest_salary.sql`
- Create: `exercises/interview_questions/02_second_highest_rental_month.sql`,
  `exercises/interview_questions/solutions/02_second_highest_rental_month.sql`
- Create: `exercises/interview_questions/03_customers_with_no_orders.sql`,
  `exercises/interview_questions/solutions/03_customers_with_no_orders.sql`

**Interfaces:**
- Consumes: `employees.salaries`, `sakila.rental`, `ecommerce.customers/orders` from Tasks 2-4.

- [ ] **Step 1: `exercises/interview_questions/01_nth_highest_salary.sql`**

```sql
-- Interview Questions 01 (classic "Nth highest salary" pattern):
-- Find the 3rd highest distinct *current* salary company-wide. Return just
-- that one salary value.

```

- [ ] **Step 2: `exercises/interview_questions/solutions/01_nth_highest_salary.sql`**

```sql
-- DISTINCT collapses duplicate salary values before ranking, so "3rd highest"
-- means the 3rd highest distinct value, not the 3rd row.
SELECT DISTINCT salary
FROM employees.salaries
WHERE to_date = DATE '9999-01-01'
ORDER BY salary DESC
OFFSET 2 LIMIT 1;
```

- [ ] **Step 3: `exercises/interview_questions/02_second_highest_rental_month.sql`**

```sql
-- Interview Questions 02: Find the calendar month (format 'YYYY-MM') with
-- the second-highest number of sakila rentals.

```

- [ ] **Step 4: `exercises/interview_questions/solutions/02_second_highest_rental_month.sql`**

```sql
WITH monthly_counts AS (
    SELECT to_char(rental_date, 'YYYY-MM') AS rental_month, COUNT(*) AS rental_count
    FROM sakila.rental
    GROUP BY rental_month
)
SELECT rental_month, rental_count
FROM monthly_counts
ORDER BY rental_count DESC
OFFSET 1 LIMIT 1;
```

- [ ] **Step 5: `exercises/interview_questions/03_customers_with_no_orders.sql`**

```sql
-- Interview Questions 03 (classic anti-join pattern): List ecommerce
-- customers who have never placed an order. Show customer_id and full name,
-- ordered by name.

```

- [ ] **Step 6: `exercises/interview_questions/solutions/03_customers_with_no_orders.sql`**

```sql
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name
FROM ecommerce.customers c
LEFT JOIN ecommerce.orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY customer_name;
```

- [ ] **Step 7: Verify every solution runs cleanly against the live database**

```bash
docker compose exec -T postgres psql -U postgres -d practice < exercises/interview_questions/solutions/01_nth_highest_salary.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/interview_questions/solutions/02_second_highest_rental_month.sql
docker compose exec -T postgres psql -U postgres -d practice < exercises/interview_questions/solutions/03_customers_with_no_orders.sql
```

Expected: query 1 returns exactly 1 row (or 0 if fewer than 3 distinct current salaries exist,
which is very unlikely with 200 employees). Query 2 returns exactly 1 row. Query 3 returns 0 or
more rows without error.

- [ ] **Step 8: Commit**

```bash
git add exercises/interview_questions/
git commit -m "Add interview_questions exercises with solutions"
```

---

### Task 15: README rewrite

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: the final directory structure and commands from all prior tasks (docker-compose
  quickstart, `scripts/reset.sql` usage, exercises/notes layout).

- [ ] **Step 1: Replace `README.md`'s content**

```markdown
# SQL Practice — Interview-SQL

A self-hosted PostgreSQL practice environment for learning SQL and prepping for interviews.
Spin up a local database seeded with three trimmed, realistic sample datasets, then work through
topic-organized exercises with hidden answer keys and short conceptual notes.

## Prerequisites

- Docker and Docker Compose

## Quickstart

```bash
docker compose up -d
```

This starts a PostgreSQL 17 container named `sql-practice-db`, exposed on `localhost:5432`,
with database `practice` (user `postgres`, password `postgres`). On first boot it automatically
runs `database/01_schema.sql` and `database/02_seed.sql`, creating and seeding three schemas:

- `employees` — HR sample: departments, employees, org chart, salary history
- `ecommerce` — storefront sample: customers, products, orders, order items
- `sakila` — trimmed DVD-rental sample: actors, films, customers, rentals, payments

Connect with any Postgres client, e.g.:

```bash
psql -h localhost -U postgres -d practice
```

## Resetting the database

Seed data is randomly generated on each fresh container init, so row counts and specific values
will differ between resets — that's expected. To wipe and reseed without tearing down the
container:

```bash
docker compose exec -T postgres psql -U postgres -d practice < scripts/reset.sql
```

`scripts/reset.sql` is never run automatically — only `database/01_schema.sql` and
`database/02_seed.sql` are mounted into Postgres's auto-init directory
(`/docker-entrypoint-initdb.d`).

## How to practice

1. Read the relevant `notes/<topic>.md` for a quick primer on the concept.
2. Open `exercises/<topic>/NN_description.sql` and write your query in the space provided.
3. Run it against the live database and check your results.
4. Compare against `exercises/<topic>/solutions/NN_description.sql` once you're done (or stuck).

## Directory structure

```
Interview-SQL/
├── README.md
├── docker-compose.yml
├── database/
│   ├── 01_schema.sql
│   └── 02_seed.sql
├── scripts/
│   └── reset.sql
├── exercises/
│   ├── basics/
│   ├── joins/
│   ├── aggregation/
│   ├── window_functions/
│   ├── cte/
│   ├── recursive_cte/
│   ├── subqueries/
│   └── interview_questions/
│       (each has a solutions/ subfolder with matching answer keys)
└── notes/
    ├── basics.md
    ├── joins.md
    ├── aggregation.md
    ├── window_functions.md
    ├── cte.md
    ├── recursive_cte.md
    ├── subqueries.md
    └── indexes.md
```
```

- [ ] **Step 2: Verify the README's commands actually work as documented**

```bash
docker compose down -v
docker compose up -d
docker compose exec -T postgres psql -U postgres -d practice -c "\dn"
docker compose exec -T postgres psql -U postgres -d practice < scripts/reset.sql
```

Expected: `\dn` lists schemas `employees`, `ecommerce`, `sakila` (plus Postgres defaults). The
reset command completes without error.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Rewrite README with real setup and usage documentation"
```

---

## Final full-repo verification (run after Task 15)

```bash
docker compose down -v
docker compose up -d
docker compose exec -T postgres pg_isready -U postgres
docker compose exec -T postgres psql -U postgres -d practice -c "\dn"
docker compose exec -T postgres psql -U postgres -d practice -c "\dt employees.*"
docker compose exec -T postgres psql -U postgres -d practice -c "\dt ecommerce.*"
docker compose exec -T postgres psql -U postgres -d practice -c "\dt sakila.*"
```

Expected: all three schemas and all 19 tables (6 employees + 5 ecommerce + 8 sakila) exist and are
populated, matching what each dataset task verified individually.
