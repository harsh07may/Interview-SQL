# Joins

## What
Combining rows from two or more tables based on a related column. The core join types:
`INNER JOIN` (only matching rows), `LEFT JOIN` (all left rows, matched or not), and self-joins
(a table joined to itself, e.g. an employee to their own manager).

## When
Any time the data you need is split across tables — which is almost always in a normalized
schema like `employees` or `ecommerce`.

## Gotchas
- `INNER JOIN` silently drops rows with no match on either side — use `LEFT JOIN` when you need
  to keep unmatched rows (e.g. "customers with no orders", see `interview_questions`).
- After a `LEFT JOIN`, columns from the right-hand table are `NULL` for unmatched rows — filter on
  `right_table.some_column IS NULL` to find "no match" rows (an anti-join).
- A self-join needs two aliases for the same table (e.g. `employees.employees e JOIN employees.employees m`)
  — `employees.manager_emp_no` pointing back to `employees.emp_no` is the classic case.
- Joining without a condition (or with the wrong column) produces a cartesian product — always
  double check your `ON` clause.

## Cheatsheet
```sql
SELECT ...
FROM schema.a
JOIN schema.b ON b.a_id = a.id            -- inner join
LEFT JOIN schema.c ON c.a_id = a.id;       -- keeps unmatched a rows, c.* is NULL

-- self-join
SELECT e.first_name, m.first_name AS manager
FROM employees.employees e
LEFT JOIN employees.employees m ON m.emp_no = e.manager_emp_no;
```
