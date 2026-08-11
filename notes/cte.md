# CTEs (Common Table Expressions)

## What
A `WITH name AS (...)` block that names a subquery so the main query can reference it like a table.
Purely a readability/organization tool — Postgres does not guarantee a CTE materializes separately
from the main query (it may inline it during planning).

## When
When a query needs a multi-step calculation — e.g. "first compute each order's total, then filter
to orders above $150" — a CTE lets you write and read that as two clear steps instead of nesting
subqueries.

## Gotchas
- A CTE is scoped to the single statement it's attached to — you can't reference it from a later,
  separate query.
- You can chain multiple CTEs (`WITH a AS (...), b AS (...)`), and later CTEs can reference earlier
  ones in the same `WITH` block.
- A CTE is not automatically faster than an equivalent subquery — treat it as a naming/readability
  choice, not a performance one, unless you specifically need `RECURSIVE` (see `recursive_cte`).

## Cheatsheet
```sql
WITH step_one AS (
    SELECT ... FROM schema.table GROUP BY ...
)
SELECT *
FROM step_one
WHERE some_condition;
```
