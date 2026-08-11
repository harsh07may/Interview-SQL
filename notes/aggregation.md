# Aggregation: GROUP BY, HAVING

## What
Collapsing many rows into summary rows with aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`)
per group, using `GROUP BY`. `HAVING` filters those grouped results.

## When
Whenever the question is a "per X" question — revenue per category, average salary per department,
rental count per film.

## Gotchas
- Every non-aggregated column in `SELECT` must appear in `GROUP BY` (Postgres enforces this strictly).
- `WHERE` filters rows before grouping; `HAVING` filters groups after aggregation — you cannot put
  an aggregate like `COUNT(*) > 5` in `WHERE`.
- `COUNT(*)` counts rows including `NULL`s; `COUNT(column)` skips `NULL`s in that column — they can
  give different answers on the same table.
- Aggregate functions ignore `NULL` values (e.g. `AVG` divides by the count of non-null rows, not
  total rows).

## Cheatsheet
```sql
SELECT group_col, AGG_FUNC(value_col) AS alias
FROM schema.table
WHERE row_filter
GROUP BY group_col
HAVING AGG_FUNC(value_col) > threshold
ORDER BY alias DESC;
```
