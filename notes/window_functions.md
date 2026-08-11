# Window Functions

## What
Like aggregation, but *without* collapsing rows — each row keeps its identity while also seeing a
calculation "over a window" of related rows (`OVER (PARTITION BY ... ORDER BY ...)`). Common ones:
`ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`/`LEAD()`, and running `SUM()`/`AVG() OVER (...)`.

## When
"Top N per group" (top rented film per category), "compare this row to the previous row" (salary
change over time), or running totals — all classic interview staples that plain `GROUP BY` can't do
in one pass because you'd lose the row-level detail.

## Gotchas
- `RANK()` leaves gaps after ties (1, 1, 3); `DENSE_RANK()` doesn't (1, 1, 2); `ROW_NUMBER()` never
  ties (always 1, 2, 3, arbitrarily breaking ties by the given order).
- Window functions run *after* `WHERE`/`GROUP BY` but *before* `ORDER BY`/`LIMIT` in logical query
  order — you can't filter on a window function's result in the same `SELECT`'s `WHERE`; wrap it in
  a CTE or subquery and filter in the outer query instead.
- Forgetting `PARTITION BY` computes the window over the *entire* result set, not per group — a
  common bug when you meant "rank within each department" but got "rank across everyone."
- `LAG`/`LEAD` need an explicit `ORDER BY` inside `OVER (...)` to mean "previous/next" in a
  meaningful order (usually by date).

## Cheatsheet
```sql
SELECT col,
       ROW_NUMBER() OVER (PARTITION BY group_col ORDER BY sort_col DESC) AS rn,
       SUM(value_col) OVER (PARTITION BY group_col ORDER BY sort_col) AS running_total,
       LAG(value_col) OVER (PARTITION BY group_col ORDER BY sort_col) AS prev_value
FROM schema.table;
```
