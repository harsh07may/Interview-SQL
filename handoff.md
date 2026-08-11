# Handoff — SQL Practice Repo

Status as of merge into `main` (commit `1af2880`, pushed to `origin/main`): the
15-task implementation plan (`docs/superpowers/plans/2026-08-06-sql-practice-repo.md`)
is fully built, task-reviewed, docker-verified, and merged. This document lists
the issues that were found along the way and their current status — fixed vs.
still open — so the open ones aren't lost now that the SDD workspace
(`.superpowers/sdd/2026-08-06-sql-practice-repo/`, ledger + briefs + reports)
has been deleted per the standard end-of-plan cleanup.

Nothing below blocks using the repo as-is. These are follow-up polish, not
defects that break the container, corrupt seed data, or produce wrong
answer-key results — the issues that *did* fall into that category have
already been fixed in the merged code or in this follow-up pass (see
"Already fixed" below).

## Still open

### 1. Temporal implausibilities in generated seed data

Two independent spots where two independently-randomized dates aren't
constrained relative to each other, producing occasionally nonsensical rows:

- `database/02_seed.sql:25` (`birth_date` drawn from 1965–1995) vs. `hire_date`
  drawn independently (2005–2024) — roughly 5% of the 200 generated employees
  end up hired before turning 18, some as young as ~10.
- `database/02_seed.sql:74` — salary `from_date = hire_date + (n-1) * 2 years`
  with up to 4 records per employee can push a "current" salary record's
  `from_date` years into the future (past today), since nothing clamps it.
- (Same class, already known from an earlier task review but not fixed then):
  `ecommerce.orders.order_date` and `ecommerce.customers.signup_date` are
  generated independently with no `order_date >= signup_date` constraint —
  some orders predate the customer's signup.

None of these break any exercise's correctness (they weren't spec-mandated),
but `exercises/window_functions/02_salary_growth.sql` surfaces the
future-dated-salary oddity directly if a learner inspects raw rows.

**Fix (if pursued):** derive `hire_date` from `birth_date` with a minimum age
gate, clamp salary `from_date` generation to not exceed the current date, and
add `order_date >= signup_date` to the ecommerce order generation.

### 2. Problem headers name their dataset inconsistently

The design spec says each problem header should state "which dataset/tables
to use." Some do explicitly
(`exercises/aggregation/02_avg_salary_per_department.sql` names `dept_emp`;
`exercises/aggregation/03_top_spending_sakila_customers.sql` names
`sakila.payment`), others don't name a schema/table at all
(`exercises/aggregation/01_revenue_per_category.sql`,
`exercises/cte/01_high_value_orders.sql`,
`exercises/joins/03_order_line_items.sql`,
`exercises/recursive_cte/01_org_chart.sql`).

**Fix:** normalize all 22 problem headers to explicitly name their
schema/tables, matching the style of the ones that already do it well.

### 3. `sakila.rental.return_date` is nullable but the seed never produces NULL

`database/01_schema.sql:163` declares `return_date TIMESTAMP` (nullable) —
clearly intended as the "not yet returned" modeling hook — but
`database/02_seed.sql:227` onward always populates it. Meanwhile
`notes/basics.md` and `notes/subqueries.md` both teach NULL-handling gotchas
with no live example of a NULL anywhere in the sakila data to actually
practice against.

**Fix:** make roughly 5-10% of generated `return_date`s NULL (e.g. rentals
within the last N days of the generated date range) so the NULL-handling
lessons have real data to bite on.

### 4. Plan doc has a stale/wrong expected-result claim (doc-only, low priority)

`docs/superpowers/plans/2026-08-06-sql-practice-repo.md` (recursive_cte task,
verification step) claims `exercises/recursive_cte/01_org_chart.sql` yields
"exactly one row at depth 0, 9 rows at depth 1, and the rest at depth 2." In
practice the CEO is also one department's manager, so that department's
members land at depth 1 too — the real depth-1 count is closer to ~29, not 9.
This never caused a wrong deliverable (the actual solution file and its
20-line output were correctly hand-verified via a full 200-row count during
final verification, just not by depth bucket) — it only matters if `docs/`
ships and someone treats the plan's worked example as ground truth.

**Fix:** correct the plan doc's expected-result note. (`docs/` is now
confirmed to ship — it's listed in the README's directory-structure tree —
so dropping it is no longer an option; the note itself still needs fixing.)

## Already fixed (for context — don't re-do these)

Fixed in a follow-up pass on `main` (after commit `1af2880`), verified via a
live `docker compose up` / reset / query run:

- **`README.md`** reset command was `bash`-only (`<` redirection errors in
  Windows PowerShell). Added a PowerShell (`Get-Content | ...`) form
  alongside it, and the same pattern for "run it against the live database"
  in the practice-workflow section, which previously gave no command at all.
  Also added `docs/` to the directory-structure tree, since it's tracked and
  ships (`docs/superpowers/{specs,plans}/`).
- **`scripts/reset.sql`** had no `\set ON_ERROR_STOP on`, so a mid-run
  failure would leave a silently half-reset database. Added as the first
  statement; verified a full reset still runs clean.
- **`exercises/aggregation/solutions/01_revenue_per_category.sql`** summed
  `order_items` with no `orders.status` filter, counting cancelled orders'
  line items as revenue (~22% inflation, confirmed live: $117,851 vs. the
  correct $91,472 in the current seed). Joined in `orders` and added
  `WHERE o.status <> 'cancelled'`; problem header now names the trap and the
  tables to use.
- **`docker-compose.yml`** published Postgres on `0.0.0.0:5432`. Changed to
  `127.0.0.1:5432:5432`; confirmed via `docker compose ps` that the
  container now only binds the loopback interface.

Fixed in the final-review fix wave (commit `1af2880`), verified via live
`docker compose` runs both in the worktree and again after merging to `main`:

- **`exercises/window_functions/solutions/01_top_rented_film_per_category.sql`**
  grouped by `f.title`, which isn't unique (seed generates only ~100 possible
  titles across 200 films) — distinct films' rental counts were being summed
  into one row. Now groups by `f.film_id` with a deterministic tiebreak.
- **`exercises/aggregation/solutions/03_top_spending_sakila_customers.sql`**
  grouped by the derived `customer_name` label (name collisions are ~87%
  likely in the 50-row seed) instead of `c.customer_id`, silently merging
  distinct customers' spend. Now groups by `customer_id`.
- **`notes/indexes.md`** falsely claimed every table already has FK indexes,
  and cited a redundant index as its example. `database/01_schema.sql` gained
  3 missing FK indexes (`dept_manager.dept_no`, `film_category.category_id`,
  `payment.rental_id`) and dropped 2 that were redundant with existing
  composite PKs (`idx_salaries_emp_no`, `idx_titles_emp_no`); the note's claim
  and example were corrected to match.
- **18 of 22 solution files** were missing the spec-required short
  "approach" comment — backfilled across all 8 exercise topics.
- `database/02_seed.sql`'s ecommerce-section comments (explaining the
  random()-hoisting fix) were terse/misleading — rewritten to match the
  clearer wording already used in the employees/sakila sections.
- 10 problem files were missing the trailing blank line for the learner to
  write their query in — added.
- `exercises/interview_questions/solutions/02_second_highest_rental_month.sql`
  had a nondeterministic tie (`OFFSET 1 LIMIT 1` with no tiebreaker) — added
  a secondary sort key.
- The 3 `interview_questions/solutions/*.sql` files were missing a trailing
  EOF newline, unlike every other solution file — added.

Also fixed earlier, mid-plan (commits `fa3d80d`, `5dc5d93`, `dfa5d17`'s
plan-doc updates): a Postgres planner behavior where uncorrelated
`(SELECT ... ORDER BY random() LIMIT 1)` scalar subqueries and LATERAL blocks
with no outer-row reference get hoisted and evaluated once per statement
instead of once per row, causing degenerate seed data (e.g. every product in
one category). Fixed across all three dataset sections
(employees/ecommerce/sakila) in `database/02_seed.sql`.
