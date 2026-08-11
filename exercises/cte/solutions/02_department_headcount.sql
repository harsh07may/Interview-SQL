-- CTE computes current headcount per department first, then the outer query
-- filters on that aggregate (equivalent to a HAVING, expressed via CTE).
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
