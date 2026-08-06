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
