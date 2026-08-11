import { Pool, type QueryResult, type QueryResultRow } from "pg";

declare global {
  var pgPool: Pool | undefined;
}

function getPool(): Pool {
  if (!global.pgPool) {
    global.pgPool = new Pool({ connectionString: process.env.DATABASE_URL });
    global.pgPool.on("error", (err) => {
      console.error("pg pool error:", err);
    });
  }
  return global.pgPool;
}

export interface RunResult {
  columns: string[];
  rows: unknown[][];
}

export async function runQuery(sql: string): Promise<RunResult> {
  const pool = getPool();
  // pg's types don't model this, but for a multi-statement "simple query"
  // (e.g. "SELECT 1; SELECT 2;"), pool.query resolves with an ARRAY of
  // QueryResult objects rather than a single one. Take the last statement's
  // result, matching what most SQL clients show for a multi-statement batch.
  const raw = (await pool.query(sql)) as
    | QueryResult<QueryResultRow>
    | QueryResult<QueryResultRow>[];
  const result = Array.isArray(raw) ? raw[raw.length - 1] : raw;
  const columns = result.fields.map((field) => field.name);
  const rows = result.rows.map((row) => columns.map((col) => row[col]));
  return { columns, rows };
}
