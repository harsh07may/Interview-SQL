import { NextResponse } from "next/server";
import { getExercise } from "@/lib/content";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ topic: string; exercise: string }> }
) {
  const { topic, exercise } = await params;
  try {
    const problem = await getExercise(topic, exercise);
    return NextResponse.json({ problem });
  } catch (err: any) {
    if (err.code === "ENOENT") {
      return NextResponse.json({ error: "Exercise not found." }, { status: 404 });
    }
    throw err;
  }
}
