import { NextResponse } from "next/server";
import { getSolution } from "@/lib/content";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ topic: string; exercise: string }> }
) {
  const { topic, exercise } = await params;
  try {
    const solution = await getSolution(topic, exercise);
    return NextResponse.json({ solution });
  } catch (err: any) {
    if (err.code === "ENOENT") {
      return NextResponse.json({ error: "Solution not found." }, { status: 404 });
    }
    throw err;
  }
}
