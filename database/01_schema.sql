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
