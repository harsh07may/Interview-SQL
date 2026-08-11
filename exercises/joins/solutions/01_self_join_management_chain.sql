-- Classic self-join: alias employees.employees twice, once as "the employee"
-- and once as "their manager", joined via manager_emp_no -> emp_no.
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       m.first_name || ' ' || m.last_name AS manager_name
FROM employees.employees e
LEFT JOIN employees.employees m ON m.emp_no = e.manager_emp_no
ORDER BY employee_name;
