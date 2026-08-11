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
