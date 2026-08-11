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
