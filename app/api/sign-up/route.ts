import { NextRequest, NextResponse } from "next/server";

export const POST = async (req: NextRequest) => {
  const formData = await req.formData();

  const name = formData.get("firstName");

  if (name === "FAIL") {
    return NextResponse.error();
  }

  return NextResponse.redirect("http://localhost:3000/thank-you");
};
