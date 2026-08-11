import { NextResponse } from "next/server";
import { getSolution } from "@/lib/content";
import { isErrnoException } from "@/lib/errors";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ topic: string; exercise: string }> },
) {
  const { topic, exercise } = await params;
  try {
    const solution = await getSolution(topic, exercise);
    return NextResponse.json({ solution });
  } catch (err) {
    if (isErrnoException(err) && err.code === "ENOENT") {
      return NextResponse.json(
        { error: "Solution not found." },
        { status: 404 },
      );
    }
    throw err;
  }
}
