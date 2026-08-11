# Recursive CTEs

## What
A `WITH RECURSIVE name AS (base_case UNION ALL recursive_case)` construct for traversing
hierarchical or graph-shaped data — org charts, category trees, bill-of-materials — where the
depth isn't known in advance.

## When
Any "chain of relationships" question: "everyone who reports to X, directly or transitively",
"the full org chart with each person's depth", or general parent/child tree traversal.

## Gotchas
- The base case (before `UNION ALL`) defines the starting row(s) — get this wrong and the whole
  traversal starts from the wrong place (or nowhere).
- The recursive case must `JOIN` the CTE's own name to itself to walk one more level — the
  recursion stops naturally once a level produces zero new rows.
- Always use `UNION ALL`, not `UNION`, unless you specifically need deduplication — `UNION` forces
  a distinct check on every recursive step, which is both slower and can silently drop legitimate
  duplicate rows (e.g. two employees with the same manager and title).
- Without a natural termination point (e.g. a cyclical `manager_emp_no` reference), a recursive CTE
  can loop forever — real hierarchies should always have a root row where the parent column is `NULL`.

## Cheatsheet
```sql
WITH RECURSIVE chain AS (
    SELECT id, parent_id, 0 AS depth
    FROM schema.table
    WHERE parent_id IS NULL              -- base case: the root

    UNION ALL

    SELECT t.id, t.parent_id, c.depth + 1
    FROM schema.table t
    JOIN chain c ON t.parent_id = c.id   -- recursive case: one level down
)
SELECT * FROM chain ORDER BY depth;
```
