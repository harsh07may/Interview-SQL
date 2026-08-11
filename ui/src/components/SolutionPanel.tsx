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
