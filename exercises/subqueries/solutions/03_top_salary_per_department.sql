-- Scalar correlated subquery in the SELECT list: for each department, look
-- up the MAX current salary among its currently-assigned employees.
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
