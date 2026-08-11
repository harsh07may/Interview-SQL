SELECT emp_no, first_name, last_name, hire_date
FROM employees.employees
WHERE hire_date >= DATE '2015-01-01'
ORDER BY hire_date ASC;
