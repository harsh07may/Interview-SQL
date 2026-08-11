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
