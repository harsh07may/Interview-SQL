-- Recursive CTE: anchor is the CEO (manager_emp_no IS NULL, depth 0), then
-- the recursive member walks down one management level per iteration.
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
