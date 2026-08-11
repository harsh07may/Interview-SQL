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
