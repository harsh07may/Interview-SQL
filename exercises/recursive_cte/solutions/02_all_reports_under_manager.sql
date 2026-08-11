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
