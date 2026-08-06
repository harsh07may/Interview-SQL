# SQL Practice Repo — Design

Date: 2026-08-06

## Purpose

This repository is an educational, self-hosted SQL practice environment. A learner spins up a
local PostgreSQL instance via Docker, then works through topic-organized exercises against
trimmed, realistic sample datasets, with conceptual notes and hidden answer keys to check work
against.

## Decision: engine

Despite the repo name ("Interview-SQL" under a "TSQL" folder) and a leftover SQL-Server/SSDT
`.gitignore`, the repo targets **PostgreSQL only**. `docker-compose.yml` already runs
`postgres:17`; the SSDT-specific `.gitignore` entries are stale and will be removed.

## Directory structure

```
Interview-SQL/
├── README.md
├── docker-compose.yml
├── database/
│   ├── 01_schema.sql      # creates 3 schemas: employees, ecommerce, sakila + their tables
│   └── 02_seed.sql        # seeds all three schemas, trimmed to ~a few hundred rows each
├── scripts/
│   └── reset.sql          # DROP SCHEMA ... CASCADE + re-run schema/seed; run manually, never on container init
├── exercises/
│   ├── basics/
│   │   └── solutions/
│   ├── joins/
│   │   └── solutions/
│   ├── aggregation/
│   │   └── solutions/
│   ├── window_functions/
│   │   └── solutions/
│   ├── cte/
│   │   └── solutions/
│   ├── recursive_cte/
│   │   └── solutions/
│   ├── subqueries/
│   │   └── solutions/
│   └── interview_questions/
│       └── solutions/
└── notes/
    ├── basics.md
    ├── joins.md
    ├── aggregation.md
    ├── window_functions.md
    ├── cte.md
    ├── recursive_cte.md
    ├── subqueries.md
    └── indexes.md
```

Removed from the original placeholder tree (in `README.md`):
- `datasets/` — folded into `database/`; seed data lives in `02_seed.sql`, not separate raw files.
- `solutions/{leetcode,hackerrank,stratascratch}/` — folded into `exercises/interview_questions/`,
  to avoid a parallel top-level hierarchy and avoid reproducing copyrighted platform problem text.
  Problems there are original, inspired by common patterns seen on those platforms.

## Docker init-order fix

**Bug found in current state:** `docker-compose.yml` mounts the entire `database/` directory into
`/docker-entrypoint-initdb.d`. Postgres executes files there in alphabetical order. With the old
flat `schema.sql` / `seed.sql` / `reset.sql` naming, `reset.sql` would sort and execute *before*
`schema.sql`, and would also run automatically on every fresh container init even though it's
meant to be an explicit, manual "wipe and reseed" operation.

**Fix:**
- Only `database/01_schema.sql` and `database/02_seed.sql` remain mounted into
  `docker-entrypoint-initdb.d` (numeric prefixes guarantee order).
- `reset.sql` moves to `scripts/reset.sql`, outside the mounted directory, run manually via
  `psql -h localhost -U postgres -d practice -f scripts/reset.sql`.

## Datasets

Three PostgreSQL schemas (namespaces) inside the `practice` database, to avoid table-name
collisions (e.g. `customers` exists in both `ecommerce` and conceptually in `sakila`) and to model
real multi-schema databases:

1. **`employees`** — trimmed port of the classic employees sample DB.
   Tables: `employees`, `departments`, `dept_emp`, `dept_manager`, `salaries`, `titles`.
   ~200 employees, with realistic department assignment, manager hierarchy, and multi-row salary
   history per employee (to support salary-growth window-function exercises).

2. **`ecommerce`** — Northwind-style sample.
   Tables: `customers`, `categories`, `products`, `orders`, `order_items`.
   ~50 customers, ~40 products across several categories, ~200 orders with multiple line items
   each, enough repeat customers to make aggregation/window exercises meaningful (running totals,
   rank-per-customer spend, etc).

3. **`sakila`** — trimmed port of the real Sakila DVD-rental DB.
   Tables: `actor`, `film`, `film_actor`, `category`, `film_category`, `customer`, `rental`,
   `payment`.
   ~200 films and ~200 rentals — enough to support classic Sakila-style interview questions (top
   rented films, customer spend, actor-film joins) without the full-size dataset.

Each dataset is a clearly commented, self-contained block within `01_schema.sql` /
`02_seed.sql`, so a learner can read straight through one dataset at a time.

## Exercises

~2-3 exercises per topic folder (~20 total), easy → hard within each folder. Dataset choice per
exercise is picked for variety and to fit the concept naturally.

Format: each exercise file (`exercises/<topic>/NN_description.sql`) contains a problem-statement
comment header (which dataset/tables to use, expected output shape) followed by blank space for
the learner to write their query. The matching answer key lives at
`exercises/<topic>/solutions/NN_description.sql` — the model solution query plus a short comment
explaining the approach.

Planned coverage:

| Topic | Focus | Example |
|---|---|---|
| basics | SELECT/WHERE/ORDER BY/LIMIT | filter/sort ecommerce products; basic employee lookups |
| joins | INNER/LEFT/self-join | employees self-join for "who manages whom"; sakila film/actor/category multi-join |
| aggregation | GROUP BY/HAVING | ecommerce revenue per category; avg salary per department |
| window_functions | RANK/ROW_NUMBER/running totals | top rented films per category; employee salary growth over time |
| cte | staging/readability | multi-step ecommerce order analysis |
| recursive_cte | hierarchy traversal | employees management chain via `dept_manager`/reporting structure |
| subqueries | correlated/scalar | customers who spent above their category's average |
| interview_questions | classic reframed patterns | "Nth highest salary" (employees); "second-highest rental month" (sakila); "customers with no orders" (ecommerce) |

## Notes

One concise conceptual primer per exercise topic (`notes/<topic>.md`), read before attempting
that topic's exercises: what the concept is, when to reach for it, common gotchas/interview traps,
and a syntax cheatsheet. Plus a bonus `notes/indexes.md` — a DBA-angled note (not tied to an
exercise folder) covering how indexes affect the query patterns just practiced.

## README

Replace the current placeholder (a bare fenced-code directory tree) with real documentation:
what the repo is and who it's for, prerequisites (Docker/Docker Compose), quickstart
(`docker compose up -d`, connect on `localhost:5432`, db `practice`), how to use
exercises/solutions/notes, how to reset (`scripts/reset.sql`), and the finalized directory tree.

## Out of scope (for this pass)

- Deeper exercise counts (8-10 per topic) — explicitly deferred; current pass is a lightweight
  tour (2-3 per topic) to get full topic coverage first.
- Any non-Postgres engine support.
- CI/automated grading of exercise answers.
