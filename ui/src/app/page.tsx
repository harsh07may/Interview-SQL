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
