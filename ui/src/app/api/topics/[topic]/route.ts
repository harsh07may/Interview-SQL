import { NextResponse } from "next/server";
import { getTopic, getTopicNote } from "@/lib/content";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ topic: string }> },
) {
  const { topic } = await params;
  const [topicData, note] = await Promise.all([
    getTopic(topic),
    getTopicNote(topic),
  ]);
  return NextResponse.json({ ...topicData, note });
}
