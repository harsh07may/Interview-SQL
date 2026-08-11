-- Filter both salaries and dept_emp to their currently-open rows
-- (to_date = '9999-01-01'), join, then AVG(salary) per department.
SELECT d.dept_name, ROUND(AVG(s.salary)) AS avg_salary
FROM employees.salaries s
JOIN employees.dept_emp de ON de.emp_no = s.emp_no AND de.to_date = DATE '9999-01-01'
JOIN employees.departments d ON d.dept_no = de.dept_no
WHERE s.to_date = DATE '9999-01-01'
GROUP BY d.dept_name
ORDER BY avg_salary DESC;
