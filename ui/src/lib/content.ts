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
