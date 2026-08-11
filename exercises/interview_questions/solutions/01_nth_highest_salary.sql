-- DISTINCT collapses duplicate salary values before ranking, so "3rd highest"
-- means the 3rd highest distinct value, not the 3rd row.
SELECT DISTINCT salary
FROM employees.salaries
WHERE to_date = DATE '9999-01-01'
ORDER BY salary DESC
OFFSET 2 LIMIT 1;