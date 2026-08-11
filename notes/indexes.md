# Indexes (DBA bonus note)

## What
A separate on-disk structure (by default a B-tree in Postgres) that lets the database find rows
matching a condition without scanning the whole table — the same idea as an index at the back of a
book.

## When
Add an index on columns you frequently filter (`WHERE`), join on (`ON`), or sort by (`ORDER BY`) on
a table large enough that a full scan is expensive. Every table in this repo's `database/01_schema.sql`
already has indexes on its foreign-key join columns (e.g. `idx_salaries_emp_no`,
`idx_rental_customer_id`) — that's not automatic in Postgres, unlike the primary key itself.

## Gotchas
- A `PRIMARY KEY` automatically gets a unique index; a `FOREIGN KEY` does **not** — you must create
  one yourself if you'll query/join on it often (which is why this repo's schema adds them explicitly).
- An index speeds up reads but slows down writes (`INSERT`/`UPDATE`/`DELETE` must also update the
  index) and takes disk space — don't index every column "just in case."
- An index on `(a, b)` helps queries filtering on `a` alone or `a AND b`, but generally **not** a
  query filtering on `b` alone — column order in a composite index matters.
- Wrapping an indexed column in a function (`WHERE LOWER(email) = ...`) prevents Postgres from using
  a plain index on `email` — you'd need a matching expression index (`CREATE INDEX ... ON t (LOWER(email))`).
- Use `EXPLAIN ANALYZE` before assuming an index will help — the planner may still choose a full
  table scan on a small table like the ones in this repo, because it's genuinely faster than the
  overhead of an index lookup.

## Cheatsheet
```sql
CREATE INDEX idx_table_column ON schema.table (column);
CREATE INDEX idx_table_multi ON schema.table (col_a, col_b);   -- order matters
EXPLAIN ANALYZE SELECT ...;                                     -- check if an index is actually used
```
