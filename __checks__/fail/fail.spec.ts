import { test, expect } from "@playwright/test";

const inputFields = ["First Name", "Last Name", "Email"];

test.setTimeout(10);
/**
 * Same as the last test in `browser.spec.ts` but fails on purpose.
 *
 * When 'fail@gmail.com' is sent with the form data the api responds back with
 * a newtwork error instead of redirecting to the 'thank-you' page.
 *
 * This is used for demonstrative purposes to show what happens when a
 * test fails on Checkly, specifically to get an alert.
 * */
test("fails every time", async ({ page }) => {
  await page.goto("/");

  const fieldsWithInputs = inputFields.map((f, i: number) =>
    i === 2 ? [f, "fail@gmail.com"] : [f, f],
  );

  for (const [field, text] of fieldsWithInputs) {
    const input = page.getByLabel(field);
    await input.fill(text);
  }

  await page.getByRole("button", { name: "Submit" }).click();
  // Won't actually redirect
  await expect(page).toHaveURL("/thank-you");
});
