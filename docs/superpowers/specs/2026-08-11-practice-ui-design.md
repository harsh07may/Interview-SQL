# SQL Practice UI — Design

Date: 2026-08-11

## Purpose

Today, practicing an exercise means manually reading a `notes/<topic>.md` file, opening an
`exercises/<topic>/NN_*.sql` file in an editor, running it via `docker compose exec ... psql`
(or a separate DB client), then opening the matching `solutions/NN_*.sql` file to check work.
This adds a local web app — `ui/` — that puts notes, the problem, a query editor, live results,
and the hidden solution in one screen, while leaving the existing file-based content
(`notes/`, `exercises/`) as the single source of truth. No grading/diffing — the learner runs
their own query, reads the results, and compares against the solution visually.

## Stack decision

**Next.js (App Router, latest stable — v16.2.9 at design time), containerized.** Added as a `ui`
service in `docker-compose.yml` alongside `postgres`, so the existing `docker compose up -d`
quickstart is unchanged — it now also starts the UI at `http://localhost:3000`. Route Handlers
under `app/api/**/route.ts` replace what would otherwise be a separate Express backend; React
Server Components render notes/exercise content server-side with no separate API round-trip for
the initial page load. Rejected a plain Express + vanilla-JS build (more hand-wiring for
markdown rendering and the editor, no benefit given Node/a build step is acceptable here) and a
Vite/React SPA (Next's file-based routing and Route Handlers already cover everything an SPA +
separate API server would need — a separate API project is unjustified for ~5 endpoints).

Per Next.js 16 conventions, dynamic route params are async (`{ params }: { params:
Promise<{ topic: string }> }`), and the Docker image uses `output: 'standalone'` in
`next.config.js` (self-hosting in a container is exactly what standalone mode is for) with a
multi-stage Dockerfile that runs `node server.js`.

## No reorganization of existing content

`notes/` and `exercises/` stay exactly where they are, in their current format. The UI reads them
directly (bind-mounted into the `ui` container read-only, the same pattern `database/` already
uses for Postgres's init directory) rather than requiring content to move into `ui/` or change
shape. This keeps the file-based workflow in the README valid as a fallback, and means editing a
note or exercise file is immediately reflected in the UI with no rebuild.

## Directory structure (additions only)

```
Interview-SQL/
├── ui/
│   ├── Dockerfile
│   ├── next.config.js          # output: 'standalone'
│   ├── package.json
│   └── app/
│       ├── layout.tsx          # sidebar: topics -> exercises, from /api/topics
│       ├── page.tsx            # landing: pick a topic
│       ├── [topic]/
│       │   └── [exercise]/
│       │       └── page.tsx    # note + problem + query editor + results + solution toggle
│       └── api/
│           ├── topics/route.ts
│           ├── topics/[topic]/route.ts
│           ├── exercises/[topic]/[exercise]/route.ts
│           ├── exercises/[topic]/[exercise]/solution/route.ts
│           └── run/route.ts
```

## Data flow

- **Content reads** (`/api/topics`, `/api/topics/:topic`, `/api/exercises/:topic/:exercise`,
  `.../solution`): filesystem reads under a mounted content root (`CONTENT_ROOT` env var,
  defaulting to `/app/content` in the container, pointing at bind-mounted `notes/` and
  `exercises/`). Topic list and exercise list are derived from directory listings — no manual
  index to keep in sync as exercises are added.
- **Solution content** is only fetched when the learner opens the "Show solution" toggle (lazy
  `fetch` from the client component), not bundled into the initial exercise payload — preserves
  today's "hidden answer key" behavior.
- **Query execution** (`POST /api/run`, body `{ sql: string }`): a module-level `pg.Pool`
  connects to the `postgres` service over the Docker network using `DATABASE_URL` (same
  `postgres`/`postgres`/`practice` credentials `docker-compose.yml` already defines). Returns
  `{ columns, rows }` on success or `{ error: string }` (the raw Postgres error message) on
  failure — rendered as-is in the results pane, no error parsing/rewriting needed. No query
  restriction: this matches the trust level of today's direct `psql` access, and `scripts/reset.sql`
  remains the recovery path if a query damages shared data.

## Frontend behavior

- Sidebar lists all 8 topics (from `notes/`/`exercises/` directory names); expanding a topic
  lists its exercises. Selecting one navigates to `/[topic]/[exercise]`, so links are
  shareable/refreshable.
- Main pane, top to bottom: rendered note markdown (`react-markdown`) for that topic, the
  exercise's problem header/body, a SQL editor (`@uiw/react-codemirror`), a Run button, and a
  results table (or the error message) below it.
- The editor is a scratch pad: empty on every page load/navigation, nothing written back to the
  `.sql` files. This matches the exercise files' existing role as read-only problem statements —
  a learner's in-progress query isn't persisted by the tool itself (they can still copy it into
  their own fork/commit if they want to keep it, same as today).
- "Show solution" is collapsed by default per exercise; opening it fetches and renders the
  solution query, left open until the learner navigates away.

## Docker Compose changes

```yaml
services:
  postgres:
    # unchanged

  ui:
    build: ./ui
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      DATABASE_URL: postgres://postgres:postgres@postgres:5432/practice
      CONTENT_ROOT: /app/content
    volumes:
      - ./notes:/app/content/notes:ro
      - ./exercises:/app/content/exercises:ro
    depends_on:
      - postgres
```

`docker compose up -d` builds the `ui` image on first run (Compose builds services with a
`build:` key automatically when no image exists) and starts both containers together.

## Error handling

- `/api/run` catches connection failures (Postgres not up yet, network hiccup) and returns a
  distinct message ("database not reachable — is `docker compose up -d` running?") instead of a
  raw connection-refused stack trace; all other query errors pass through Postgres's own message
  unmodified, since that message is itself part of what a learner should learn to read.
- A topic/exercise that doesn't resolve to a file (bad URL) renders Next's standard 404.

## Testing

Manual verification pass (no automated test suite — matches the rest of the repo, which has none):
run all 22 exercises through the UI against a fresh `docker compose up -d`, for each confirming
the note renders, the problem header matches the `.sql` file, a correct query returns expected
rows, an intentionally broken query surfaces a readable Postgres error, and the solution toggle
shows the right file. Also confirm direct navigation to an exercise URL
(`/aggregation/01_revenue_per_category`) works via the server-rendered path, not just
sidebar-driven client navigation.

## Out of scope

- Grading / diffing learner output against the solution's output.
- Writing learner queries back into the exercise `.sql` files or any other progress persistence.
- Restricting query execution to read-only (explicitly declined — matches today's access level).
- Any change to `notes/`, `exercises/`, `database/`, or `scripts/reset.sql` content or format.
