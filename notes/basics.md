# Basics: SELECT, WHERE, ORDER BY, LIMIT

## What
The foundation of every query: choosing columns (`SELECT`), filtering rows (`WHERE`), ordering
results (`ORDER BY`), and capping how many rows come back (`LIMIT`/`OFFSET`).

## When
Every query starts here. Get comfortable filtering and sorting before moving on to joins or
aggregation — most interview questions build directly on these fundamentals.

## Gotchas
- `WHERE` filters rows *before* grouping; it cannot reference aggregate results (use `HAVING` for that).
- String comparisons are case-sensitive by default in Postgres (`'Alice' <> 'alice'`). Use `ILIKE`
  or `LOWER()` for case-insensitive matching.
- `NULL` never equals anything, including another `NULL` — use `IS NULL` / `IS NOT NULL`, not `= NULL`.
- `LIMIT` without `ORDER BY` returns an arbitrary subset — always pair them if you care which rows you get.
- `OFFSET n LIMIT 1` is a common trick for "the Nth row" once sorted — see the `interview_questions` topic.

## Cheatsheet
```sql
SELECT col1, col2
FROM schema.table
WHERE condition
ORDER BY col1 [ASC|DESC]
LIMIT n [OFFSET m];
```
