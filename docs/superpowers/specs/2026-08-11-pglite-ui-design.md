# PGlite Zero-Install UI — Future Consideration

Date: 2026-08-11

Status: **not scheduled** — written for future reference only, alongside
[2026-08-11-practice-ui-design.md](2026-08-11-practice-ui-design.md) (the Next.js + Docker UI
that's actually being built). This doc exists so the option doesn't have to be re-derived from
scratch if "juniors need zero-install onboarding" ever becomes a real requirement.

## Driver

The Next.js UI still requires Docker + Postgres locally. If the actual goal becomes **zero
install** — a junior opens a URL (or a static folder) and is practicing within seconds, no
Docker, no `docker compose up`, works offline after first load — that requires the database
itself to run in the browser. [PGlite](https://pglite.dev) (Postgres compiled to WASM, real
Postgres semantics rather than a SQLite/DuckDB reimplementation) is the only option that
preserves the repo's existing decision to target real Postgres dialect for interview fidelity.

## Why this is a separate project, not a mode of `ui/`

Once the database runs client-side, the entire reason `ui/` is a server app disappears: there's
no `pg.Pool`, no `/api/run` Route Handler, no `postgres` container to depend on, no reason to
carry a server-capable framework at all. Bolting "also run PGlite" onto the Docker-based Next.js
app as a toggle would mean shipping and maintaining two execution paths (network round-trip vs.
in-browser `db.query()`) behind one UI for no real benefit — the two apps' *reason to exist* is
different (convenience for a team already running Docker, vs. zero-install portability). A
lighter, independently-deployable static app is the right shape if this is ever built: simpler
to reason about, and it can be hosted anywhere static files work (GitHub Pages, a CDN, or just
`npx serve` locally) with no backend at all.

## Proposed structure (if built)

New sibling directory in this repo — not a separate repo — so `notes/` and `exercises/` stay the
single source of truth for both UIs instead of drifting across two places:

```
Interview-SQL/
├── ui/            # existing: Next.js + Docker + real Postgres
├── ui-static/      # new: Vite + React + PGlite, fully static
├── notes/          # unchanged, read by both
├── exercises/       # unchanged, read by both
├── database/        # unchanged; 01_schema.sql/02_seed.sql reused verbatim (see Risks)
```

**Stack: Vite + React**, not Next.js — with no server, Next's Route Handlers and SSR buy nothing;
a plain SPA with a client-side router (topic/exercise as URL params) is the smaller, more
honest fit. Content (`notes/*.md`, `exercises/**/*.sql`) is copied into the app at build time
(a small pre-build script, or a Vite plugin reading `../notes` and `../exercises`) so the final
output is pure static files with no runtime filesystem dependency.

## How PGlite fits in

- Package: `@electric-sql/pglite`, instantiated in a Web Worker (`pglite/worker`) so query
  execution never blocks the UI thread — same UX reason the Docker version runs queries
  server-side instead of synchronously.
- **Persistence**: PGlite backs onto IndexedDB (`idb://practice`), so `01_schema.sql` and
  `02_seed.sql` only need to run once per browser — on first load, detect an empty/missing
  database and run both files verbatim through `db.exec()`; subsequent visits reopen the
  persisted database instantly. This is the actual "zero install, fast after first load" story.
- **Reset**: replaces `scripts/reset.sql` + `docker compose exec`. A "Reset practice data" button
  wipes the IndexedDB-backed store and reruns `01_schema.sql`/`02_seed.sql`, mirroring the
  existing reset workflow's semantics without needing a running container to exec into.
- **Query execution**: the query editor calls `db.query(sql)` directly against the in-browser
  instance — no `/api/run` endpoint, no network hop. Results/errors surface exactly the same way
  (Postgres's own row/column shape and error messages), so the learner-facing behavior matches
  the Docker UI even though the execution path is entirely different.

## Risks / what would need validating first

This is the one part of the idea that's genuinely unverified and should be spiked before
committing to the approach, not assumed:

- **`01_schema.sql` and `02_seed.sql` need to actually run clean under PGlite.** PGlite is real
  Postgres, not a reimplementation, so this is likely fine — but the seed script's use of
  `random()`, `generate_series`, and the LATERAL-hoisting workaround noted in `handoff.md` should
  be run against PGlite once, end to end, before treating this design as validated. Any
  extension/catalog-function gap would surface here first.
- **First-load cost**: PGlite's WASM bundle plus running the full seed script in-browser has a
  real (if one-time, cacheable) latency cost that the Docker path doesn't — worth measuring
  before promising "seconds to start practicing."
- **Content duplication risk**: build-time copying of `notes/`/`exercises/` into `ui-static/`
  must not fork into a second copy that drifts from the originals — the copy step should run on
  every build, never be hand-edited.

## Out of scope (same as the Docker UI's design)

Grading/diffing against solution output, persisting a learner's in-progress query, and any
change to the shape of `notes/`/`exercises/`/`database/` content remain out of scope here too —
this doc only changes *where the database runs*, not what the practice experience does.
