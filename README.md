# SQL Practice — Interview-SQL

A self-hosted PostgreSQL practice environment for learning SQL and prepping for interviews.
Spin up a local database seeded with three trimmed, realistic sample datasets, then work through
topic-organized exercises with hidden answer keys and short conceptual notes.

## Prerequisites

- Docker and Docker Compose

## Quickstart

```bash
docker compose up -d
```

This starts a PostgreSQL 17 container named `sql-practice-db`, exposed on `localhost:5432`,
with database `practice` (user `postgres`, password `postgres`). On first boot it automatically
runs `database/01_schema.sql` and `database/02_seed.sql`, creating and seeding three schemas:

- `employees` — HR sample: departments, employees, org chart, salary history
- `ecommerce` — storefront sample: customers, products, orders, order items
- `sakila` — trimmed DVD-rental sample: actors, films, customers, rentals, payments

Connect with any Postgres client, e.g.:

```bash
psql -h localhost -U postgres -d practice
```

## Practice UI

`docker compose up -d` also starts a web UI at <http://localhost:3000> — browse topics and
exercises, read the notes, write and run SQL against the live database, and reveal the
matching solution, all in one screen. It's a convenience layer on top of the same
`notes/`/`exercises/` files described below; the manual `psql`/client workflow still works
exactly as documented if you prefer it.

## Resetting the database

Seed data is randomly generated on each fresh container init, so row counts and specific values
will differ between resets — that's expected. To wipe and reseed without tearing down the
container:

```bash
docker compose exec -T postgres psql -U postgres -d practice < scripts/reset.sql
```

On Windows PowerShell, `<` redirection isn't supported — use this instead:

```powershell
Get-Content scripts/reset.sql | docker compose exec -T postgres psql -U postgres -d practice
```

`scripts/reset.sql` is never run automatically — only `database/01_schema.sql` and
`database/02_seed.sql` are mounted into Postgres's auto-init directory
(`/docker-entrypoint-initdb.d`).

## How to practice

1. Read the relevant `notes/<topic>.md` for a quick primer on the concept.
2. Open `exercises/<topic>/NN_description.sql` and write your query in the space provided.
3. Run it against the live database and check your results:

   ```bash
   docker compose exec -T postgres psql -U postgres -d practice < exercises/<topic>/NN_description.sql
   ```

   On Windows PowerShell:

   ```powershell
   Get-Content exercises/<topic>/NN_description.sql | docker compose exec -T postgres psql -U postgres -d practice
   ```

   Or connect with any Postgres client (see above) and run the query interactively.
4. Compare against `exercises/<topic>/solutions/NN_description.sql` once you're done (or stuck).

## Directory structure

```
Interview-SQL/
├── README.md
├── docker-compose.yml
├── database/
│   ├── 01_schema.sql
│   └── 02_seed.sql
├── docs/
│   └── superpowers/
│       ├── specs/
│       └── plans/
├── scripts/
│   └── reset.sql
├── exercises/
│   ├── basics/
│   ├── joins/
│   ├── aggregation/
│   ├── window_functions/
│   ├── cte/
│   ├── recursive_cte/
│   ├── subqueries/
│   └── interview_questions/
│       (each has a solutions/ subfolder with matching answer keys)
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
