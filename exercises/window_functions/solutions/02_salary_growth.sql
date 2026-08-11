SELECT emp_no, from_date, salary,
       LAG(salary) OVER (PARTITION BY emp_no ORDER BY from_date) AS prev_salary,
       salary - LAG(salary) OVER (PARTITION BY emp_no ORDER BY from_date) AS salary_change
FROM employees.salaries
ORDER BY emp_no, from_date;
