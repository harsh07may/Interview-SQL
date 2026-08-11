# Subqueries

## What
A query nested inside another query. Three flavors matter most: **scalar** (returns one value, used
like a single expression), **row/IN-list** (returns a set of values), and **correlated** (references
a column from the outer query, so it re-runs conceptually once per outer row).

## When
Scalar subqueries for "compare this row to some single computed value" (e.g. the max salary in this
row's department). Correlated `EXISTS`/`NOT EXISTS` for "does a related row exist" questions —
usually the cleanest way to express "has never..." or "has at least one...".

## Gotchas
- A scalar subquery must return exactly one row/column, or the query errors at runtime — guard with
  aggregates (`MAX`, `AVG`) or a tight `WHERE` on the inner query.
- `NOT IN` with a subquery that can return `NULL` silently returns *zero rows* for the whole outer
  query (NULL poisons the comparison) — prefer `NOT EXISTS` for "doesn't exist" checks, it doesn't
  have this trap.
- A correlated subquery re-evaluates conceptually per outer row, which can be slow on large tables —
  the query planner often rewrites it into a join internally, but it's worth knowing the naive cost.
- `EXISTS` only cares whether the subquery returns *any* row — never `SELECT *` inside it out of
  habit; `SELECT 1` communicates the intent (existence only, not the data).

## Cheatsheet
```sql
-- scalar subquery
SELECT col, (SELECT MAX(x) FROM schema.other WHERE other.id = t.id) AS max_x
FROM schema.table t;

-- correlated EXISTS
SELECT * FROM schema.a
WHERE EXISTS (SELECT 1 FROM schema.b WHERE b.a_id = a.id);

-- correlated NOT EXISTS (safe "doesn't exist" check)
SELECT * FROM schema.a
WHERE NOT EXISTS (SELECT 1 FROM schema.b WHERE b.a_id = a.id);
```
