# SQL Practice UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Next.js web app (`ui/`) that lets a learner browse the existing `notes/` and `exercises/` content, write and run SQL against the live `postgres` service, and reveal the matching solution — all in one screen, added as a new `docker-compose.yml` service alongside `postgres`.

**Architecture:** Next.js App Router (v16) with a `src/` directory, one process serving both the React frontend and a handful of Route Handlers under `src/app/api/**`. Two small server-only library modules do all the real work: `src/lib/content.ts` reads `notes/`/`exercises/` off disk, `src/lib/db.ts` runs SQL against Postgres via a pooled `pg` client. Everything else (pages, Route Handlers, client components) is a thin wrapper around those two modules, styled with Tailwind utility classes. `notes/` and `exercises/` are never modified — the app only reads them (bind-mounted read-only in Docker).

**Tech Stack:** Next.js ^16.2.9 (App Router, `src/` directory), React ^19, TypeScript, Tailwind CSS v4 (the `create-next-app` default — `@tailwindcss/postcss` plugin, no `tailwind.config.js` needed), Biome for linting/formatting (in place of ESLint), `pg` for Postgres access, `react-markdown` for note rendering, `@uiw/react-codemirror` + `@codemirror/lang-sql` for the query editor. No test framework — this repo has none (see `docs/superpowers/specs/2026-08-11-practice-ui-design.md`, "Testing"), so every task is verified with `npm run dev` + `curl`/browser checks instead of an automated suite.

## Global Constraints

- Next.js App Router, minimum v16.2.9 — dynamic route `params` are async (`Promise<{...}>`), must be `await`ed (confirmed against the v16.2.9 docs).
- All app source lives under `ui/src/` (`src/app`, `src/lib`, `src/components`) — the `@/*` import alias resolves to `./src/*`. Config files (`next.config.js`, `postcss.config.mjs`, `tsconfig.json`, `biome.json`, `next-env.d.ts`) stay at `ui/` root, per Next.js convention.
- Styling is Tailwind utility classes in JSX, not hand-rolled CSS files. `globals.css` only ever contains the Tailwind import plus a couple of base `body` styles — no per-task CSS-file edits.
- Linting is Biome (`npm run lint` → `biome check .`), not ESLint. No ESLint config or dependency is added.
- `notes/` and `exercises/` content and shape are never changed by this work — the app only reads them.
- Query execution (`/api/run`) is **unrestricted** — no read-only enforcement, matches today's direct `psql` access level. Do not add query validation/sanitization beyond passing the raw SQL to Postgres.
- The SQL editor is a scratch pad: cleared on every page load/navigation, never written back to any `.sql` file.
- The "Show solution" panel only fetches solution content when explicitly opened — never bundled into the initial exercise page load.
- `docker compose up -d` (optionally `--build` the first time) must remain the one command that starts the whole stack, per the existing README quickstart.
- No automated test suite. Every task's verification step is a real `npm run dev` + `curl`/browser check against real files/a real Postgres instance — not a mock.

---

### Task 1: Scaffold the Next.js app skeleton

**Files:**
- Create: `ui/package.json`
- Create: `ui/tsconfig.json`
- Create: `ui/next.config.js`
- Create: `ui/next-env.d.ts`
- Create: `ui/postcss.config.mjs`
- Create: `ui/biome.json`
- Create: `ui/src/app/layout.tsx`
- Create: `ui/src/app/page.tsx`
- Create: `ui/src/app/globals.css`
- Create: `ui/public/.gitkeep`
- Modify: `.gitignore` (repo root)

**Interfaces:**
- Produces: a working `npm run dev` in `ui/` serving a placeholder page at `/`, with Tailwind and Biome wired up. Later tasks overwrite `ui/src/app/page.tsx` (Task 6) and extend `ui/src/app/layout.tsx` (Task 5).

- [ ] **Step 1: Create `ui/package.json`**

```json
{
  "name": "sql-practice-ui",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "biome check ."
  },
  "dependencies": {
    "next": "^16.2.9",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "pg": "^8.13.0",
    "react-markdown": "^9.0.1",
    "@uiw/react-codemirror": "^4.23.0",
    "@codemirror/lang-sql": "^6.7.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@types/pg": "^8.11.0"
  }
}
```

Tailwind and Biome are deliberately left out of this hand-written JSON — Step 11 installs both at whatever their current latest version is, rather than this plan guessing (and possibly getting wrong) a specific version number for fast-moving tooling.

- [ ] **Step 2: Create `ui/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 3: Create `ui/next.config.js`**

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
};

module.exports = nextConfig;
```

`output: 'standalone'` is what Task 10's Dockerfile needs — it produces a minimal `.next/standalone` folder built for self-hosting in a container, per the Next.js docs.

- [ ] **Step 4: Create `ui/next-env.d.ts`**

```ts
/// <reference types="next" />
/// <reference types="next/image-types/global" />
```

- [ ] **Step 5: Create `ui/postcss.config.mjs`**

```js
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
```

This is the entire Tailwind v4 build config — v4 auto-detects source files, so no `tailwind.config.js`/`content` array is needed.

- [ ] **Step 6: Create `ui/biome.json`**

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "ignoreUnknown": false
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space"
  },
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double"
    }
  }
}
```

- [ ] **Step 7: Create `ui/public/.gitkeep`**

Empty file — keeps the `public/` directory present in git (the Dockerfile in Task 10 copies it) even though nothing lives there yet.

```
```

- [ ] **Step 8: Create `ui/src/app/globals.css`**

```css
@import "tailwindcss";

body {
  @apply bg-neutral-950 text-neutral-100;
}
```

This is the only CSS file in the app — every other task styles its JSX with Tailwind utility classes directly, so no task after this one edits this file.

- [ ] **Step 9: Create `ui/src/app/layout.tsx`**

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SQL Practice",
  description: "Self-hosted SQL practice environment",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

- [ ] **Step 10: Create `ui/src/app/page.tsx` (placeholder, replaced in Task 6)**

```tsx
export default function HomePage() {
  return <div>SQL Practice UI</div>;
}
```

- [ ] **Step 11: Update root `.gitignore`**

Read the current `.gitignore` first, then add these lines (it currently only has `.env`, OS files, editor files, and `*.log` — none of which cover a Node subproject):

```
# Node (ui/)
node_modules/
.next/
.env*.local
```

- [ ] **Step 12: Install dependencies (base deps, then Tailwind + Biome at latest)**

```bash
cd ui
npm install
npm install --save-dev tailwindcss @tailwindcss/postcss @biomejs/biome
```

The second command adds Tailwind and Biome at whatever their current latest versions are and records the resolved versions in `package.json`/`package-lock.json`.

- [ ] **Step 13: Verify the dev server and lint**

```bash
npm run dev
```

In a second terminal:

```bash
curl -s http://localhost:3000 | grep "SQL Practice UI"
```

Expected: the placeholder text is found in the response, and the page background renders dark (Tailwind's `bg-neutral-950` applied via `globals.css`) if viewed in a browser at `http://localhost:3000`. Stop the dev server (Ctrl+C).

```bash
npm run lint
```

Expected: `biome check .` runs and passes (or reports only the expected style of the files just written — fix anything it flags before moving on).

- [ ] **Step 14: Commit**

```bash
git add ui/package.json ui/package-lock.json ui/tsconfig.json ui/next.config.js ui/next-env.d.ts ui/postcss.config.mjs ui/biome.json ui/src/app/layout.tsx ui/src/app/page.tsx ui/src/app/globals.css ui/public/.gitkeep .gitignore
git commit -m "Scaffold ui/ as a Next.js app with Tailwind v4 and Biome"
```

---

### Task 2: Content library and topic API routes

**Files:**
- Create: `ui/src/lib/content.ts`
- Create: `ui/src/app/api/topics/route.ts`
- Create: `ui/src/app/api/topics/[topic]/route.ts`

**Interfaces:**
- Consumes: nothing from prior tasks.
- Produces (used by later tasks): from `ui/src/lib/content.ts` —
  - `export interface ExerciseSummary { slug: string; number: string; title: string }`
  - `export interface Topic { slug: string; title: string; exercises: ExerciseSummary[] }`
  - `export async function listTopics(): Promise<Topic[]>`
  - `export async function getTopic(topicSlug: string): Promise<Topic>`
  - `export async function getTopicNote(topicSlug: string): Promise<string | null>`
  - `export async function getExercise(topicSlug: string, exerciseSlug: string): Promise<string>` (throws `ENOENT`-coded error if missing)
  - `export async function getSolution(topicSlug: string, exerciseSlug: string): Promise<string>` (throws `ENOENT`-coded error if missing)

**Content-shape note:** the repo's `notes/` and `exercises/` directories are *not* a clean 1:1 match — `exercises/interview_questions/` has no `notes/interview_questions.md`, and `notes/indexes.md` has no matching `exercises/indexes/`. This module treats `exercises/` as the source of truth for the topic list (that's what a learner actually practices), and `getTopicNote` returns `null` when a topic has no note file rather than throwing — the exercise page (Task 7) renders nothing in the note slot when that happens. `indexes.md` is intentionally never surfaced as a topic — it stays as plain repo content, unchanged.

- [ ] **Step 1: Write `ui/src/lib/content.ts`**

```ts
import { readFile, readdir } from "fs/promises";
import path from "path";

const CONTENT_ROOT = process.env.CONTENT_ROOT ?? path.resolve(process.cwd(), "..");
const NOTES_DIR = path.join(CONTENT_ROOT, "notes");
const EXERCISES_DIR = path.join(CONTENT_ROOT, "exercises");

const TOPIC_TITLES: Record<string, string> = {
  basics: "Basics",
  joins: "Joins",
  aggregation: "Aggregation",
  window_functions: "Window Functions",
  cte: "CTEs",
  recursive_cte: "Recursive CTEs",
  subqueries: "Subqueries",
  interview_questions: "Interview Questions",
};

function humanizeTopic(slug: string): string {
  return TOPIC_TITLES[slug] ?? slug;
}

export interface ExerciseSummary {
  slug: string;
  number: string;
  title: string;
}

export interface Topic {
  slug: string;
  title: string;
  exercises: ExerciseSummary[];
}

export async function listTopics(): Promise<Topic[]> {
  const entries = await readdir(EXERCISES_DIR, { withFileTypes: true });
  const topicSlugs = entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
  return Promise.all(topicSlugs.map((slug) => getTopic(slug)));
}

export async function getTopic(topicSlug: string): Promise<Topic> {
  const dir = path.join(EXERCISES_DIR, topicSlug);
  const entries = await readdir(dir, { withFileTypes: true });
  const exercises: ExerciseSummary[] = entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".sql"))
    .map((entry) => entry.name.replace(/\.sql$/, ""))
    .sort()
    .map((slug) => {
      const [number, ...rest] = slug.split("_");
      return { slug, number, title: rest.join(" ") };
    });

  return { slug: topicSlug, title: humanizeTopic(topicSlug), exercises };
}

export async function getTopicNote(topicSlug: string): Promise<string | null> {
  const notePath = path.join(NOTES_DIR, `${topicSlug}.md`);
  try {
    return await readFile(notePath, "utf-8");
  } catch (err: any) {
    if (err.code === "ENOENT") return null;
    throw err;
  }
}

export async function getExercise(topicSlug: string, exerciseSlug: string): Promise<string> {
  const filePath = path.join(EXERCISES_DIR, topicSlug, `${exerciseSlug}.sql`);
  return readFile(filePath, "utf-8");
}

export async function getSolution(topicSlug: string, exerciseSlug: string): Promise<string> {
  const filePath = path.join(EXERCISES_DIR, topicSlug, "solutions", `${exerciseSlug}.sql`);
  return readFile(filePath, "utf-8");
}
```

`CONTENT_ROOT` defaults to `path.resolve(process.cwd(), "..")` — when `npm run dev` runs from inside `ui/`, that resolves to the repo root, so `notes/` and `exercises/` are found with zero configuration for local development (the `src/` directory has no effect on this — `process.cwd()` is still `ui/`, not `ui/src/`). Task 10 overrides `CONTENT_ROOT` via a Docker env var so the same code works unchanged in the container.

- [ ] **Step 2: Write `ui/src/app/api/topics/route.ts`**

```ts
import { NextResponse } from "next/server";
import { listTopics } from "@/lib/content";

export async function GET() {
  const topics = await listTopics();
  return NextResponse.json(topics);
}
```

- [ ] **Step 3: Write `ui/src/app/api/topics/[topic]/route.ts`**

```ts
import { NextResponse } from "next/server";
import { getTopic, getTopicNote } from "@/lib/content";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ topic: string }> }
) {
  const { topic } = await params;
  const [topicData, note] = await Promise.all([getTopic(topic), getTopicNote(topic)]);
  return NextResponse.json({ ...topicData, note });
}
```

- [ ] **Step 4: Verify against the real repo content**

```bash
cd ui
npm run dev
```

In a second terminal:

```bash
curl -s http://localhost:3000/api/topics | python3 -m json.tool
```

Expected: a JSON array of exactly 8 topics, alphabetically sorted by slug: `aggregation`, `basics`, `cte`, `interview_questions`, `joins`, `recursive_cte`, `subqueries`, `window_functions`. `aggregation.exercises` has 3 entries (`01_revenue_per_category`, `02_avg_salary_per_department`, `03_top_spending_sakila_customers`).

```bash
curl -s http://localhost:3000/api/topics/aggregation | python3 -m json.tool
```

Expected: `note` starts with `"# Aggregation: GROUP BY, HAVING"`.

```bash
curl -s http://localhost:3000/api/topics/interview_questions | python3 -m json.tool
```

Expected: `note` is `null` (no `notes/interview_questions.md` exists), `exercises` has 3 entries. Stop the dev server when confirmed.

- [ ] **Step 5: Commit**

```bash
git add ui/src/lib/content.ts ui/src/app/api/topics
git commit -m "Add content library and topics API routes"
```

---

### Task 3: Exercise and solution API routes

**Files:**
- Create: `ui/src/app/api/exercises/[topic]/[exercise]/route.ts`
- Create: `ui/src/app/api/exercises/[topic]/[exercise]/solution/route.ts`

**Interfaces:**
- Consumes: `getExercise`, `getSolution` from `ui/src/lib/content.ts` (Task 2).
- Produces: `GET /api/exercises/:topic/:exercise` → `{ problem: string }` or 404 `{ error: string }`; `GET /api/exercises/:topic/:exercise/solution` → `{ solution: string }` or 404 `{ error: string }`. Task 9's `SolutionPanel` component consumes the `solution` field by this exact name.

**Note on the first route:** it's never actually called by the frontend — Task 7's exercise page fetches the problem text directly via `getExercise()` (a server component, no HTTP round trip needed for its own render), matching the design spec's explicit reasoning ("server components render notes/exercise content server-side with no separate API round-trip for the initial page load"). It's still implemented here because the approved design spec lists it as part of the API surface. Don't "fix" this by rewiring the page to fetch over HTTP — that would add latency for no benefit.

- [ ] **Step 1: Write `ui/src/app/api/exercises/[topic]/[exercise]/route.ts`**

```ts
import { NextResponse } from "next/server";
import { getExercise } from "@/lib/content";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ topic: string; exercise: string }> }
) {
  const { topic, exercise } = await params;
  try {
    const problem = await getExercise(topic, exercise);
    return NextResponse.json({ problem });
  } catch (err: any) {
    if (err.code === "ENOENT") {
      return NextResponse.json({ error: "Exercise not found." }, { status: 404 });
    }
    throw err;
  }
}
```

- [ ] **Step 2: Write `ui/src/app/api/exercises/[topic]/[exercise]/solution/route.ts`**

```ts
import { NextResponse } from "next/server";
import { getSolution } from "@/lib/content";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ topic: string; exercise: string }> }
) {
  const { topic, exercise } = await params;
  try {
    const solution = await getSolution(topic, exercise);
    return NextResponse.json({ solution });
  } catch (err: any) {
    if (err.code === "ENOENT") {
      return NextResponse.json({ error: "Solution not found." }, { status: 404 });
    }
    throw err;
  }
}
```

- [ ] **Step 3: Verify**

```bash
cd ui
npm run dev
```

```bash
curl -s http://localhost:3000/api/exercises/aggregation/01_revenue_per_category | python3 -m json.tool
```

Expected: `problem` contains `"Aggregation 01: Total revenue"` (the exercise file's header comment).

```bash
curl -s http://localhost:3000/api/exercises/aggregation/01_revenue_per_category/solution | python3 -m json.tool
```

Expected: `solution` contains a `SELECT` statement referencing `ecommerce.order_items`.

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/exercises/aggregation/does_not_exist
```

Expected: `404`. Stop the dev server when confirmed.

- [ ] **Step 4: Commit**

```bash
git add ui/src/app/api/exercises
git commit -m "Add exercise and solution API routes"
```

---

### Task 4: Database query module and /api/run route

**Files:**
- Create: `ui/src/lib/db.ts`
- Create: `ui/src/app/api/run/route.ts`

**Interfaces:**
- Produces: from `ui/src/lib/db.ts` — `export interface RunResult { columns: string[]; rows: unknown[][] }`, `export async function runQuery(sql: string): Promise<RunResult>` (throws on any Postgres error, with `err.code === "ECONNREFUSED"` distinguishing a down database from a bad query). Task 8's `Workspace` component consumes `POST /api/run` → `RunResult` on success or `{ error: string }` on failure.

- [ ] **Step 1: Write `ui/src/lib/db.ts`**

```ts
import { Pool } from "pg";

declare global {
  var pgPool: Pool | undefined;
}

function getPool(): Pool {
  if (!global.pgPool) {
    global.pgPool = new Pool({ connectionString: process.env.DATABASE_URL });
  }
  return global.pgPool;
}

export interface RunResult {
  columns: string[];
  rows: unknown[][];
}

export async function runQuery(sql: string): Promise<RunResult> {
  const pool = getPool();
  const result = await pool.query(sql);
  const columns = result.fields.map((field) => field.name);
  const rows = result.rows.map((row) => columns.map((col) => row[col]));
  return { columns, rows };
}
```

The pool is cached on `global` so Next.js's dev-mode hot-reload doesn't open a fresh connection pool on every file save.

- [ ] **Step 2: Write `ui/src/app/api/run/route.ts`**

```ts
import { NextResponse } from "next/server";
import { runQuery } from "@/lib/db";

export async function POST(request: Request) {
  const body = await request.json();
  const sql = typeof body?.sql === "string" ? body.sql : "";

  if (!sql.trim()) {
    return NextResponse.json({ error: "Query is empty." }, { status: 400 });
  }

  try {
    const result = await runQuery(sql);
    return NextResponse.json(result);
  } catch (err: any) {
    if (err.code === "ECONNREFUSED") {
      return NextResponse.json(
        { error: "Database not reachable — is `docker compose up -d` running?" },
        { status: 503 }
      );
    }
    return NextResponse.json({ error: err.message ?? String(err) }, { status: 400 });
  }
}
```

- [ ] **Step 3: Verify against the real Postgres service**

Make sure `postgres` is up (the existing service, independent of `ui`):

```bash
cd "d:\Interview Prep\TSQL\Interview-SQL"
docker compose up -d postgres
```

Run the dev server with `DATABASE_URL` pointed at the published port:

```bash
cd ui
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/practice npm run dev
```

(PowerShell: `$env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/practice"; npm run dev`)

In a second terminal:

```bash
curl -s -X POST http://localhost:3000/api/run \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT category_id, name FROM ecommerce.categories ORDER BY category_id LIMIT 3;"}' \
  | python3 -m json.tool
```

Expected: `{ "columns": ["category_id", "name"], "rows": [[...], [...], [...]] }` with real data.

```bash
curl -s -X POST http://localhost:3000/api/run \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT * FROM does_not_exist;"}' \
  | python3 -m json.tool
```

Expected: `{ "error": "relation \"does_not_exist\" does not exist" }` (Postgres's own message, passed through unmodified).

```bash
curl -s -X POST http://localhost:3000/api/run -H "Content-Type: application/json" -d '{"sql": ""}'
```

Expected: `{"error":"Query is empty."}`. Stop the dev server when confirmed.

- [ ] **Step 4: Commit**

```bash
git add ui/src/lib/db.ts ui/src/app/api/run
git commit -m "Add DB query module and /api/run route"
```

---

### Task 5: Root layout and Sidebar navigation

**Files:**
- Create: `ui/src/components/Sidebar.tsx`
- Modify: `ui/src/app/layout.tsx`

**Interfaces:**
- Consumes: `GET /api/topics` (Task 2), `Topic`/`ExerciseSummary` types from `ui/src/lib/content.ts` (type-only import — `Sidebar` is a client component, `lib/content.ts` has server-only `fs` code).
- Produces: `Sidebar` renders inside `RootLayout`; every subsequent page (Tasks 6-9) appears in the layout's content slot beside it.

- [ ] **Step 1: Write `ui/src/components/Sidebar.tsx`**

```tsx
"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { Topic } from "@/lib/content";

export default function Sidebar() {
  const [topics, setTopics] = useState<Topic[]>([]);
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const pathname = usePathname();

  useEffect(() => {
    fetch("/api/topics")
      .then((res) => res.json())
      .then((data: Topic[]) => {
        setTopics(data);
        const currentTopic = pathname.split("/")[1];
        if (currentTopic) {
          setExpanded(new Set([currentTopic]));
        }
      });
    // Only fetch once on mount; expanding/collapsing afterward is manual.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function toggleTopic(slug: string) {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(slug)) {
        next.delete(slug);
      } else {
        next.add(slug);
      }
      return next;
    });
  }

  return (
    <nav className="w-64 shrink-0 border-r border-neutral-800 bg-neutral-900 p-4">
      <h1 className="mb-4 text-sm font-semibold">SQL Practice</h1>
      <ul>
        {topics.map((topic) => (
          <li key={topic.slug}>
            <button
              className="w-full py-1.5 text-left text-sm"
              onClick={() => toggleTopic(topic.slug)}
            >
              {expanded.has(topic.slug) ? "▾" : "▸"} {topic.title}
            </button>
            {expanded.has(topic.slug) && (
              <ul className="pl-5">
                {topic.exercises.map((exercise) => {
                  const href = `/${topic.slug}/${exercise.slug}`;
                  const isActive = pathname === href;
                  return (
                    <li key={exercise.slug}>
                      <Link
                        href={href}
                        className={`block py-1 text-sm ${
                          isActive ? "font-semibold text-sky-400" : "text-neutral-400"
                        }`}
                      >
                        {exercise.number} · {exercise.title}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            )}
          </li>
        ))}
      </ul>
    </nav>
  );
}
```

- [ ] **Step 2: Wire `Sidebar` into `ui/src/app/layout.tsx`**

```tsx
import type { Metadata } from "next";
import Sidebar from "@/components/Sidebar";
import "./globals.css";

export const metadata: Metadata = {
  title: "SQL Practice",
  description: "Self-hosted SQL practice environment",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <div className="flex min-h-screen">
          <Sidebar />
          <main className="max-w-4xl flex-1 p-8">{children}</main>
        </div>
      </body>
    </html>
  );
}
```

- [ ] **Step 3: Verify in a browser**

```bash
cd ui
npm run dev
```

Open `http://localhost:3000` in a browser. Expected: a left sidebar listing all 8 topics; clicking one expands/collapses its exercise list; the exercise list items are links (they 404 until Task 7 exists — that's expected at this point). Stop the dev server when confirmed.

- [ ] **Step 4: Commit**

```bash
git add ui/src/components/Sidebar.tsx ui/src/app/layout.tsx
git commit -m "Add Sidebar navigation to the root layout"
```

---

### Task 6: Landing page

**Files:**
- Modify: `ui/src/app/page.tsx`

**Interfaces:**
- Consumes: `listTopics` from `ui/src/lib/content.ts` (server component — direct import, no HTTP round trip).

- [ ] **Step 1: Replace `ui/src/app/page.tsx`**

```tsx
import Link from "next/link";
import { listTopics } from "@/lib/content";

export default async function HomePage() {
  const topics = await listTopics();

  return (
    <div>
      <h2 className="mb-4 text-lg font-semibold">Pick a topic to start practicing</h2>
      <div className="grid grid-cols-[repeat(auto-fill,minmax(180px,1fr))] gap-4">
        {topics.map((topic) => {
          const first = topic.exercises[0];
          if (!first) {
            return (
              <div key={topic.slug} className="rounded-md border border-neutral-800 p-4 opacity-60">
                <h3 className="font-medium">{topic.title}</h3>
                <p className="text-sm text-neutral-400">No exercises yet</p>
              </div>
            );
          }
          return (
            <Link
              key={topic.slug}
              href={`/${topic.slug}/${first.slug}`}
              className="block rounded-md border border-neutral-800 p-4 hover:border-neutral-600"
            >
              <h3 className="font-medium">{topic.title}</h3>
              <p className="text-sm text-neutral-400">{topic.exercises.length} exercises</p>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify in a browser**

```bash
cd ui
npm run dev
```

Open `http://localhost:3000`. Expected: 8 topic cards, each showing its exercise count; clicking one navigates to `/<topic>/<first-exercise-slug>` (404 until Task 7 — expected). Stop the dev server when confirmed.

- [ ] **Step 3: Commit**

```bash
git add ui/src/app/page.tsx
git commit -m "Add landing page with topic cards"
```

---

### Task 7: Exercise page (note + problem statement)

**Files:**
- Create: `ui/src/app/[topic]/[exercise]/page.tsx`

**Interfaces:**
- Consumes: `getExercise`, `getTopicNote`, `getTopic` from `ui/src/lib/content.ts` (Task 2), `notFound` from `next/navigation`, `react-markdown`.
- Produces: the page shell that Task 8 (`Workspace`) plugs into at the bottom.

- [ ] **Step 1: Write `ui/src/app/[topic]/[exercise]/page.tsx`**

```tsx
import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import { getExercise, getTopicNote, getTopic } from "@/lib/content";

export default async function ExercisePage({
  params,
}: {
  params: Promise<{ topic: string; exercise: string }>;
}) {
  const { topic, exercise } = await params;

  let problem: string;
  try {
    problem = await getExercise(topic, exercise);
  } catch (err: any) {
    if (err.code === "ENOENT") notFound();
    throw err;
  }

  const [note, topicData] = await Promise.all([getTopicNote(topic), getTopic(topic)]);

  return (
    <div>
      {note && (
        <section
          className="mb-6 border-b border-neutral-800 pb-4
            [&_h1]:mb-2 [&_h1]:text-xl [&_h1]:font-bold
            [&_h2]:mb-2 [&_h2]:mt-4 [&_h2]:text-lg [&_h2]:font-semibold
            [&_ul]:list-disc [&_ul]:pl-5
            [&_code]:rounded [&_code]:bg-neutral-900 [&_code]:px-1 [&_code]:font-mono
            [&_pre]:overflow-x-auto [&_pre]:rounded [&_pre]:bg-neutral-900 [&_pre]:p-3"
        >
          <ReactMarkdown>{note}</ReactMarkdown>
        </section>
      )}
      <section className="mb-4">
        <h2 className="mb-2 text-lg font-semibold">{topicData.title}</h2>
        <pre className="whitespace-pre-wrap rounded bg-neutral-900 p-3 font-mono text-sm">
          {problem}
        </pre>
      </section>
    </div>
  );
}
```

(`Workspace` is added at the bottom of this JSX in Task 8 — kept out of this task so the page renders and is verifiable on its own first.)

- [ ] **Step 2: Verify in a browser**

```bash
cd ui
npm run dev
```

Open `http://localhost:3000/aggregation/01_revenue_per_category`. Expected: the "Aggregation: GROUP BY, HAVING" note renders as formatted markdown (headings and the cheatsheet code block visibly styled) above the problem statement, which shows the exercise file's header comment verbatim in a monospace block.

Open `http://localhost:3000/interview_questions/01_nth_highest_salary`. Expected: no note section is rendered (no crash, no empty box) since `notes/interview_questions.md` doesn't exist — only the problem statement shows.

Open `http://localhost:3000/aggregation/does_not_exist`. Expected: Next's standard 404 page. Stop the dev server when confirmed.

- [ ] **Step 3: Commit**

```bash
git add "ui/src/app/[topic]/[exercise]/page.tsx"
git commit -m "Add exercise page with note and problem statement"
```

---

### Task 8: Query workspace (SQL editor, Run, results)

**Files:**
- Create: `ui/src/components/Workspace.tsx`
- Modify: `ui/src/app/[topic]/[exercise]/page.tsx`

**Interfaces:**
- Consumes: `POST /api/run` (Task 4), `RunResult` type from `ui/src/lib/db.ts` (type-only import).
- Produces: `<Workspace topic={string} exercise={string} />`, rendered by the exercise page. Task 9's `SolutionPanel` is rendered inside `Workspace`.

- [ ] **Step 1: Write `ui/src/components/Workspace.tsx`**

```tsx
"use client";

import { useState } from "react";
import CodeMirror from "@uiw/react-codemirror";
import { sql } from "@codemirror/lang-sql";
import type { RunResult } from "@/lib/db";
import SolutionPanel from "@/components/SolutionPanel";

export default function Workspace({
  topic,
  exercise,
}: {
  topic: string;
  exercise: string;
}) {
  const [query, setQuery] = useState("");
  const [result, setResult] = useState<RunResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [running, setRunning] = useState(false);

  async function runQuery() {
    setRunning(true);
    setError(null);
    setResult(null);
    try {
      const res = await fetch("/api/run", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sql: query }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? "Unknown error");
      } else {
        setResult(data);
      }
    } catch {
      setError("Request failed — is the UI server running?");
    } finally {
      setRunning(false);
    }
  }

  return (
    <section>
      <CodeMirror
        value={query}
        height="220px"
        theme="dark"
        extensions={[sql()]}
        onChange={(value) => setQuery(value)}
        placeholder="-- write your query here"
      />
      <button
        onClick={runQuery}
        disabled={running || !query.trim()}
        className="mt-3 rounded bg-sky-600 px-3 py-1.5 text-sm font-medium disabled:opacity-50"
      >
        {running ? "Running…" : "Run"}
      </button>

      {error && (
        <pre className="mt-3 whitespace-pre-wrap rounded border border-red-800 bg-neutral-900 p-3 font-mono text-sm text-red-400">
          {error}
        </pre>
      )}

      {result && (
        <div className="mt-3 overflow-x-auto">
          <p className="mb-1 text-sm text-neutral-400">{result.rows.length} row(s)</p>
          <table className="border-collapse font-mono text-sm">
            <thead>
              <tr>
                {result.columns.map((col) => (
                  <th key={col} className="border border-neutral-800 px-2 py-1 text-left">
                    {col}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {result.rows.map((row, i) => (
                <tr key={i}>
                  {row.map((cell, j) => (
                    <td key={j} className="border border-neutral-800 px-2 py-1">
                      {cell === null ? "NULL" : String(cell)}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <SolutionPanel topic={topic} exercise={exercise} />
    </section>
  );
}
```

This imports `SolutionPanel` from Task 9 — write Task 9's file first if executing out of order, or stub it temporarily as `export default function SolutionPanel() { return null; }` and replace in Task 9.

- [ ] **Step 2: Render `Workspace` from the exercise page**

In `ui/src/app/[topic]/[exercise]/page.tsx`, add the import and render it after the `problem` section:

```tsx
import Workspace from "@/components/Workspace";
```

```tsx
      <section className="mb-4">
        <h2 className="mb-2 text-lg font-semibold">{topicData.title}</h2>
        <pre className="whitespace-pre-wrap rounded bg-neutral-900 p-3 font-mono text-sm">
          {problem}
        </pre>
      </section>
      <Workspace topic={topic} exercise={exercise} />
    </div>
```

- [ ] **Step 3: Verify end-to-end against live Postgres**

```bash
cd "d:\Interview Prep\TSQL\Interview-SQL"
docker compose up -d postgres
cd ui
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/practice npm run dev
```

Open `http://localhost:3000/aggregation/01_revenue_per_category`. Type `SELECT 1;` into the editor, click Run. Expected: a results table with one column and one row showing `1`.

Type `SELECT * FROM does_not_exist;`, click Run. Expected: the red error panel shows Postgres's `relation "does_not_exist" does not exist` message.

Reload the page. Expected: the editor is empty again (scratch pad, not persisted). Stop the dev server when confirmed.

- [ ] **Step 4: Commit**

```bash
git add ui/src/components/Workspace.tsx "ui/src/app/[topic]/[exercise]/page.tsx"
git commit -m "Add query workspace with SQL editor and results table"
```

---

### Task 9: Solution panel

**Files:**
- Create: `ui/src/components/SolutionPanel.tsx`

**Interfaces:**
- Consumes: `GET /api/exercises/:topic/:exercise/solution` (Task 3).
- Produces: `<SolutionPanel topic={string} exercise={string} />`, already referenced by `Workspace` (Task 8).

- [ ] **Step 1: Write `ui/src/components/SolutionPanel.tsx`**

```tsx
"use client";

import { useState } from "react";

export default function SolutionPanel({
  topic,
  exercise,
}: {
  topic: string;
  exercise: string;
}) {
  const [open, setOpen] = useState(false);
  const [solution, setSolution] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function toggle() {
    const next = !open;
    setOpen(next);
    if (next && solution === null) {
      setLoading(true);
      const res = await fetch(`/api/exercises/${topic}/${exercise}/solution`);
      const data = await res.json();
      setSolution(data.solution ?? data.error ?? "Solution unavailable.");
      setLoading(false);
    }
  }

  return (
    <div className="mt-4">
      <button onClick={toggle} className="rounded border border-neutral-700 px-3 py-1.5 text-sm">
        {open ? "Hide solution" : "Show solution"}
      </button>
      {open && (
        <pre className="mt-2 whitespace-pre-wrap rounded bg-neutral-900 p-3 font-mono text-sm">
          {loading ? "Loading…" : solution}
        </pre>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Verify in a browser**

```bash
cd ui
npm run dev
```

Open `http://localhost:3000/aggregation/01_revenue_per_category`. Click "Show solution". Expected: the button label flips to "Hide solution" and the solution SQL (referencing `ecommerce.order_items`, `WHERE o.status <> 'cancelled'`) appears below it. Click "Hide solution" then "Show solution" again. Expected: no second network request/flash of "Loading…" (cached after first fetch — check the Network tab). Stop the dev server when confirmed.

- [ ] **Step 3: Commit**

```bash
git add ui/src/components/SolutionPanel.tsx
git commit -m "Add lazy-loading solution panel"
```

---

### Task 10: Docker packaging and docker-compose integration

**Files:**
- Create: `ui/Dockerfile`
- Create: `ui/.dockerignore`
- Modify: `docker-compose.yml`
- Modify: `README.md`

**Interfaces:**
- Consumes: `CONTENT_ROOT`/`DATABASE_URL` env vars (already read by `ui/src/lib/content.ts` and `ui/src/lib/db.ts` from Tasks 2 and 4 — no code changes needed here, only environment wiring).

- [ ] **Step 1: Write `ui/Dockerfile`**

```dockerfile
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

COPY --from=builder /app/public ./public
RUN mkdir .next && chown node:node .next
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static

USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

The `src/` directory and Tailwind's build step need no special handling here — `next build` compiles both into `.next/standalone`/`.next/static` the same as any other Next.js app; `output: 'standalone'` (Task 1) is what makes this copy pattern work at all.

- [ ] **Step 2: Write `ui/.dockerignore`**

```
node_modules
.next
npm-debug.log
```

- [ ] **Step 3: Add the `ui` service to `docker-compose.yml`**

Read the current file first, then add a `ui` service alongside the existing `postgres` service (don't change `postgres`):

```yaml
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

Note `DATABASE_URL` here uses the Docker network hostname `postgres`, not `localhost` — this only resolves inside the Compose network, unlike Task 4's manual local-dev testing which used `localhost:5432` (the published port).

- [ ] **Step 4: Update `README.md`**

Add a short section after "Quickstart", before "Resetting the database":

```markdown
## Practice UI

`docker compose up -d` also starts a web UI at <http://localhost:3000> — browse topics and
exercises, read the notes, write and run SQL against the live database, and reveal the
matching solution, all in one screen. It's a convenience layer on top of the same
`notes/`/`exercises/` files described below; the manual `psql`/client workflow still works
exactly as documented if you prefer it.
```

- [ ] **Step 5: Verify the full containerized stack**

```bash
cd "d:\Interview Prep\TSQL\Interview-SQL"
docker compose up -d --build
```

```bash
curl -s http://localhost:3000/api/topics | python3 -m json.tool
```

Expected: same 8-topic JSON as Task 2's local verification.

```bash
curl -s -X POST http://localhost:3000/api/run \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT 1 AS one;"}' \
  | python3 -m json.tool
```

Expected: `{ "columns": ["one"], "rows": [[1]] }` — confirms the `ui` container reaches `postgres` over the Docker network using the `postgres:5432` hostname.

Open `http://localhost:3000` in a browser and click through a couple of topics to confirm the full UI (including Tailwind-styled layout) works end-to-end in the container, not just via `npm run dev`.

```bash
docker compose ps
```

Expected: both `sql-practice-db` and the new `ui` container listed as running.

- [ ] **Step 6: Commit**

```bash
git add ui/Dockerfile ui/.dockerignore docker-compose.yml README.md
git commit -m "Package ui/ as a docker-compose service"
```

---

### Task 11: Full manual verification pass

**Files:** none (verification only, per the spec's "Testing" section — no automated suite exists in this repo).

- [ ] **Step 1: Fresh stack**

```bash
cd "d:\Interview Prep\TSQL\Interview-SQL"
docker compose down
docker compose up -d --build
```

- [ ] **Step 2: Lint check**

```bash
cd ui
npm run lint
```

Expected: `biome check .` passes with no errors across every file created in Tasks 1-9.

- [ ] **Step 3: Walk every exercise**

For each of the 22 exercises below, open `http://localhost:3000/<topic>/<exercise>` and confirm: the note renders (or is absent for `interview_questions`, which has none), the problem statement matches the `.sql` file's header comment, running `SELECT 1;` returns a one-row/one-column result, and "Show solution" reveals SQL text.

- `aggregation`: `01_revenue_per_category`, `02_avg_salary_per_department`, `03_top_spending_sakila_customers`
- `basics`: `01_top_priced_products`, `02_active_sakila_customers`, `03_employees_hired_after`
- `cte`: `01_high_value_orders`, `02_department_headcount`
- `interview_questions`: `01_nth_highest_salary`, `02_second_highest_rental_month`, `03_customers_with_no_orders`
- `joins`: `01_self_join_management_chain`, `02_scifi_film_cast`, `03_order_line_items`
- `recursive_cte`: `01_org_chart`, `02_all_reports_under_manager`
- `subqueries`: `01_above_average_priced_products`, `02_never_rented_films`, `03_top_salary_per_department`
- `window_functions`: `01_top_rented_film_per_category`, `02_salary_growth`, `03_running_total_customer_spend`

- [ ] **Step 4: Error and edge-case pass**

- On any exercise page, run a deliberately broken query (e.g. `SELECT * FROM nope;`) and confirm the red error panel shows Postgres's message.
- Run the actual solution query (copy from the solution panel) for `aggregation/01_revenue_per_category` and confirm it returns rows without error.
- Navigate directly to `http://localhost:3000/aggregation/01_revenue_per_category` (typed URL, not sidebar click) and confirm it renders via server-side fetch, not a client-side loading flash.
- Navigate to `http://localhost:3000/aggregation/nonexistent` and confirm Next's 404 page appears.
- Reload an exercise page after typing a query and confirm the editor is empty again (no persistence).

- [ ] **Step 5: Confirm no repo content was modified**

```bash
git status
```

Expected: only the files from Tasks 1-10 are new/modified — nothing under `notes/`, `exercises/`, `database/`, or `scripts/` changed.

- [ ] **Step 6: Final commit (if this pass required any fixes)**

```bash
git add -A
git commit -m "Fix issues found in full manual verification pass"
```

If no fixes were needed, skip this step — there's nothing to commit.
