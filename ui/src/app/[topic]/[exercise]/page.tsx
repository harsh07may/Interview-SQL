import { notFound } from "next/navigation";
import ReactMarkdown from "react-markdown";
import { getExercise, getTopicNote, getTopic } from "@/lib/content";
import Workspace from "@/components/Workspace";

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
      <Workspace topic={topic} exercise={exercise} />
    </div>
  );
}
